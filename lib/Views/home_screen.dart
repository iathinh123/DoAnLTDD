import 'package:doanltdd/Views/search_screen.dart';
import 'package:flutter/material.dart';
import 'transaction_screen.dart';
import 'budget_screen.dart';
import 'account_screen.dart';
import '../models/transaction_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'expense_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'all_transaction_screen.dart';
import 'AI_screen.dart';
import 'addfriend_view/addfriend_screen.dart';
import 'group_jar_view/group_jar_screen.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<TransactionModel> allTransactions = [];
  String getWeekday(int day) {
    switch (day) {
      case 1:
        return "Thứ 2";
      case 2:
        return "Thứ 3";
      case 3:
        return "Thứ 4";
      case 4:
        return "Thứ 5";
      case 5:
        return "Thứ 6";
      case 6:
        return "Thứ 7";
      case 7:
        return "CN";
      default:
        return "";
    }
  }

  String formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }
  int currentIndex = 0;
  double balance = 0;
  double totalExpense = 0;
  double totalIncome = 0;
  List<TransactionModel> transactions = [];
  bool isBalanceVisible = true;
  bool _showDetails = false;

  final amountController = TextEditingController();
  final noteController = TextEditingController();
  int selectedType = 0;
  String selectedCategory = "Chọn nhóm";
  DateTime selectedDate = DateTime.now();

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "";

  final Map<String, List<String>> defaultCategories = {
    "expense": ["Ăn uống", "Mua sắm", "Di chuyển"],
    "income": ["Lương", "Thưởng", "Thu khác"],
    "debt": ["Cho vay", "Trả nợ", "Thu nợ"],
  };

  String get typeKey {
    if (selectedType == 0) return "expense";
    if (selectedType == 1) return "income";
    return "debt";
  }

  List<Map<String, dynamic>> userDefinedCategories = [];
  @override
  void initState() {
    super.initState();
    listenToTransactions();
    loadUserCategories();
  }
  //Đếm bạn
  Stream<int> getFriendCount() {
    return FirebaseFirestore.instance
        .collection("NguoiDung")
        .doc(userId)
        .collection("friends")
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  //Đếm lời mời kết bạn
  Stream<int> getFriendRequestCount() {
    return FirebaseFirestore.instance
        .collection("NguoiDung")
        .doc(userId)
        .collection("received_requests")
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }
  // ================= LẮNG NGHE DỮ LIỆU REAL-TIME =================
  void listenToTransactions() {
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .snapshots()
        .listen((snapshot) {
      double tExpense = 0;
      double tIncome = 0;
      double calculatedBalance = 0;

      // 1. Xác định mốc thời gian bắt đầu
      DateTime now = DateTime.now();
      DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
      startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

      List<TransactionModel> tList = snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList();

      tList.sort((a, b) => b.date.compareTo(a.date));

      for (var t in tList) {
        calculatedBalance += t.amount;

        if (t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
          if (t.amount < 0) {
            tExpense += t.amount.abs();
          } else {
            tIncome += t.amount;
          }
        }
      }

      if (mounted) {
        setState(() {
          transactions = tList;
          totalExpense = tExpense;
          totalIncome = tIncome;
          balance = calculatedBalance;
        });
      }
    });
  }

  void loadUserCategories() {
    if (userId.isEmpty) return;
    FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("categories")
        .snapshots()
        .listen((snapshot) {
      if (mounted) {
        setState(() {
          userDefinedCategories = snapshot.docs.map((doc) {
            // Ép kiểu dữ liệu từ Firebase
            Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
            return {
              "name": data["name"].toString(),
              "type": data["type"].toString(),
            };
          }).toList();
        });
      }
    });
  }

  Future<void> _checkBudgetWarning(String category, double savedAmount) async {
    if (savedAmount >= 0) return;

    try {
      final now = DateTime.now();

      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("budgets")
          .where("month", isEqualTo: now.month)
          .where("year", isEqualTo: now.year)
          .get();

      if (snapshot.docs.isEmpty) return;

      final categoryNorm = _normalize(category);

      final matched = snapshot.docs.where((doc) {
        final data = doc.data();
        final budgetCat = _normalize(data["category"] ?? "");
        return budgetCat == categoryNorm;
      }).toList();

      if (matched.isEmpty) return;

      final budgetData = matched.first.data();
      double limit = (budgetData["limit"] as num).toDouble();
      double spent = (budgetData["spent"] as num).toDouble();
      spent += savedAmount.abs();
      double percent = limit > 0 ? spent / limit : 0;

      if (!mounted) return;

      if (percent >= 1.0) {
        _showBudgetAlert(
          "🚨 Vượt ngân sách!",
          "Bạn đã vượt hạn mức \"${budgetData['category']}\"\n"
              "Đã chi: ${spent.toStringAsFixed(0)}đ / ${limit.toStringAsFixed(0)}đ",
          Colors.red,
        );
      } else if (percent >= 0.8) {
        _showBudgetAlert(
          "⚠️ Sắp vượt ngân sách!",
          "Ngân sách \"${budgetData['category']}\" đã dùng ${(percent * 100).toInt()}%\n"
              "Còn lại: ${(limit - spent).toStringAsFixed(0)}đ",
          Colors.orange,
        );
      }

    } catch (e) {
      print("checkBudget ERROR: $e");
    }
  }

  String _normalize(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const latin =      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';

    String result = text.toLowerCase();
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }
    return result;
  }

  void _showBudgetAlert(String title, String message, Color color) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: color, fontSize: 18)),
        content: Text(
          message,
          style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Đã hiểu", style: TextStyle(color: Colors.green)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => currentIndex = 2);
            },
            child: const Text("Xem ngân sách",
                style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  // ================= LƯU GIAO DỊCH =================
  void _saveTransaction() async {
    try {
      double amountValue =
          double.tryParse(amountController.text.trim()) ?? 0;

      if (amountValue <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng nhập số tiền")),
        );
        return;
      }

      if (selectedCategory == "Chọn nhóm") {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Vui lòng chọn nhóm")),
        );
        return;
      }

      // Khoản chi => số âm
      if (selectedType == 0) {
        amountValue = -amountValue;
      }

      final docRef = FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .doc();

      await docRef.set({
        "type": selectedType,
        "category": selectedCategory,
        "amount": amountValue,
        "note": noteController.text.trim(),
        "date": Timestamp.fromDate(selectedDate),

      });
      await _checkBudgetWarning(selectedCategory, amountValue);
      amountController.clear();
      noteController.clear();

      setState(() {
        selectedCategory = "Chọn nhóm";
        selectedDate = DateTime.now();

        _showDetails = false;
      });

      if (mounted) Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Đã lưu giao dịch")),
      );
    } catch (e) {
      print("LỖI SAVE: $e");

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  // ================= UI HELPERS =================
  Widget _typeBtn(String t, int i, Function s) {
    return GestureDetector(
      onTap: () => s(() {
        selectedType = i;
        selectedCategory = "Chọn nhóm";
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selectedType == i ? const Color(0xFF4CAF50) : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
      ),
    );
  }

  Widget _buildCard({required String title, required String action, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color, fontSize: 16)),
              Text(action, style: const TextStyle(color: Colors.green, fontSize: 14)),
            ],
          ),
          const SizedBox(height: 15),
          child
        ],
      ),
    );
  }

  Widget _buildReportItem(String label, double amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          isBalanceVisible ? formatMoney(amount) : "****** đ",
          style: TextStyle(color: color, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    List<TransactionModel> recentList = transactions.take(3).toList();

    return _buildCard(
      title: "Giao dịch gần đây",
      action: "Xem tất cả",
      child: Column(
        children: [
          ...recentList.map((t) {
            bool isExpense = t.amount < 0;

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.receipt, color: Theme.of(context).textTheme.bodyMedium?.color),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.category,
                          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "${getWeekday(t.date.weekday)}, ${t.date.day}/${t.date.month}/${t.date.year}",
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    formatMoney(t.amount),
                    style: TextStyle(
                      color: isExpense ? Colors.red : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),

          const SizedBox(height: 10),
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllTransactionsScreen(
                    transactions: transactions,
                  ),
                ),
              );
            },
            child: const Text(
              "Xem tất cả",
              style: TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Ví dụ logic lưu nhóm mới vào Firebase
  Future<void> saveNewCategory(String name, String type) async {
    await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("categories")
        .add({
      "name": name,
      "type": type, // Phải lưu đúng "income" hoặc "expense"
      "createdAt": FieldValue.serverTimestamp(),
    });
  }
  // ================= MODAL SHEETS =================
  void _showCreateCategorySheet() {
    final nameCatController = TextEditingController();
    int catType = selectedType;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setST) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Nhóm mới", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCatController,
                  autofocus: true,
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                  decoration: const InputDecoration(
                    hintText: "Tên nhóm (ví dụ: Đi chợ, Tiền điện...)",
                    hintStyle: TextStyle(color: Colors.grey),
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text("Khoản thu"),
                      selected: catType == 1,
                      onSelected: (val) => setST(() => catType = 1),
                    ),
                    const SizedBox(width: 10),
                    ChoiceChip(
                      label: const Text("Khoản chi"),
                      selected: catType == 0,
                      onSelected: (val) => setST(() => catType = 0),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (nameCatController.text.isNotEmpty) {
                        await FirebaseFirestore.instance
                            .collection("users")
                            .doc(userId)
                            .collection("categories")
                            .add({
                          "name": nameCatController.text,
                          "type": catType == 0 ? "expense" : "income",
                        });
                        if (mounted) Navigator.pop(context);
                      }
                    },
                    child: const Text("Lưu nhóm"),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          );
        });
      },
    );
  }

  void _showCategoryPicker(Function setModalState) {
    // 1. Tạo danh sách hiển thị cuối cùng
    List<String> displayList = [];

    displayList.addAll(defaultCategories[typeKey] ?? []);

    final filteredUserCats = userDefinedCategories
        .where((cat) => cat["type"] == typeKey)
        .map((cat) => cat["name"] as String)
        .toList();

    displayList.addAll(filteredUserCats);

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (sheetContext) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text("Chọn nhóm",
                  style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Hiển thị toàn bộ danh sách đã gộp
                  ...displayList.map((categoryName) => ListTile(
                    leading: Icon(Icons.label_outline, color: Theme.of(context).textTheme.bodySmall?.color),
                    title: Text(categoryName, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
                    onTap: () {
                      setModalState(() => selectedCategory = categoryName);
                      Navigator.pop(sheetContext);
                    },
                  )),

                  ListTile(
                    leading: const Icon(Icons.add_circle_outline, color: Colors.green),
                    title: const Text("Thêm nhóm mới", style: TextStyle(color: Colors.green)),
                    onTap: () {
                      Navigator.pop(sheetContext);
                      _showCreateCategorySheet(); // Hàm mở giao diện tạo nhóm mới
                    },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showAddTaskSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                    Text("Thêm giao dịch mới", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _typeBtn("Khoản chi", 0, setModalState),
                      const SizedBox(width: 10),
                      _typeBtn("Khoản thu", 1, setModalState),
                      const SizedBox(width: 10),
                      _typeBtn("Vay/Nợ", 2, setModalState),
                    ],
                  ),
                  const SizedBox(height: 20),



// ================= AMOUNT INPUT =================

                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 24,
                    ),
                    decoration: const InputDecoration(
                      hintText: "Số tiền",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),

                  const SizedBox(height: 20),

// ================= CATEGORY =================

                  ListTile(
                    onTap: () => _showCategoryPicker(setModalState),
                    leading: Icon(Icons.category, color: Theme.of(context).textTheme.bodyMedium?.color),
                    title: Text(
                      selectedCategory,
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),

// ================= DATE =================

                  ListTile(
                    onTap: () async {

                      DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );

                      if (picked != null) {

                        setModalState(() {

                          selectedDate = picked;
                        });
                      }
                    },

                    leading: Icon(
                      Icons.calendar_today,
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                    ),

                    title: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
                    ),

                    trailing: const Icon(
                      Icons.arrow_forward_ios,
                      size: 14,
                      color: Colors.grey,
                    ),
                  ),

// ================= NOTE =================

                  TextField(
                    controller: noteController,
                    style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),

                    decoration: const InputDecoration(
                      hintText: "Ghi chú",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () {
                      setModalState(() {
                        _showDetails = !_showDetails;
                      });
                    },
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [

                          Text(
                            _showDetails
                                ? "Ẩn bớt chi tiết"
                                : "Hiện chi tiết",
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),

                          const SizedBox(width: 4),

                          Icon(
                            _showDetails
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: Colors.green,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                  // ================= KHU VỰC CHI TIẾT ĐƯỢC MỞ RỘNG (GIAO DIỆN TỐI) =================
                  if (_showDetails) ...[
                    _buildDetailRow(
                      Icons.people_outline,
                      "Lập hũ nhóm",
                      "Thêm bạn bè",
                          () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GroupJarScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  // NÚT LƯU CHÍNH
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _saveTransaction,
                      child: const Text("LƯU GIAO DỊCH", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildDetailRow(IconData icon, String title, String value, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2E) : Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: Colors.grey[400], size: 22),
        title: Text(title, style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 14)),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value, style: const TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_forward_ios, size: 12, color: Colors.grey),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                isBalanceVisible ? formatMoney(balance) : "********",
                                style: TextStyle(fontSize: 26, color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: Icon(Icons.search, color: Theme.of(context).textTheme.bodyMedium?.color),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => AdvancedSearchScreen(allTransactions: transactions),
                                  ));
                                },
                              ),
                              IconButton(
                                icon: Icon(isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Theme.of(context).textTheme.bodyMedium?.color, size: 20),
                                onPressed: () => setState(() => isBalanceVisible = !isBalanceVisible),
                              ),
                            ],
                          ),
                          const Text("Tổng số dư", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Icon(Icons.notifications_none, color: Theme.of(context).textTheme.bodyMedium?.color),
                    ],
                  ),
                  const SizedBox(height: 20),
                  // Ví của tôi
                  _buildCard(
                    title: "Ví của tôi",
                    action: "Xem tất cả",
                    child: Row(
                      children: [
                        const CircleAvatar(backgroundColor: Colors.orange, child: Icon(Icons.wallet, color: Colors.white)),
                        const SizedBox(width: 15),
                        Expanded(child: Text("Tiền mặt", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color))),
                        Text(formatMoney(balance)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddFriendScreen(),
                        ),
                      );
                    },
                    child: StreamBuilder<int>(
                      stream: getFriendRequestCount(),
                      builder: (context, requestSnapshot) {

                        final requestCount =
                            requestSnapshot.data ?? 0;

                        return Stack(
                          children: [
                            _buildCard(
                              title: "Bạn bè",
                              action: "Thêm bạn",
                              child: StreamBuilder<int>(
                                stream: getFriendCount(),
                                builder: (context, snapshot) {

                                  int count =
                                      snapshot.data ?? 0;

                                  return Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: Colors.blue,
                                        child: Icon(
                                          Icons.people,
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                        ),
                                      ),

                                      const SizedBox(width: 15),

                                      Expanded(
                                        child: Text(
                                          "Danh sách bạn bè",
                                          style: TextStyle(
                                            color: Theme.of(context).textTheme.bodyMedium?.color,
                                          ),
                                        ),
                                      ),

                                      Text(
                                        "$count",
                                        style: TextStyle(
                                          color: Theme.of(context).textTheme.bodyMedium?.color,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ),

                            if (requestCount > 0)
                              Positioned(
                                top: -5,
                                right: 1,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    requestCount > 99
                                        ? "99+"
                                        : "$requestCount",
                                    style: TextStyle(
                                      color: Theme.of(context).textTheme.bodyMedium?.color,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Báo cáo
                  _buildCard(
                    title: "Báo cáo tháng này",
                    action: "Xem báo cáo",
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildReportItem("Tổng đã chi", totalExpense, Colors.red),
                        _buildReportItem("Tổng thu", totalIncome, Colors.blue),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Chart
                  ExpenseChart(transactions: transactions),
                  const SizedBox(height: 80),

                  _buildRecentTransactions(),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
          TransactionScreen(transactions: transactions),
          BudgetScreen(),
          const AccountScreen(),
          const AIScreen(),
        ],
      ),
      floatingActionButton: currentIndex == 4
      ? null
      : FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        backgroundColor: Theme.of(context).cardColor,
        selectedItemColor: Theme.of(context).textTheme.bodyMedium?.color,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Tổng quan"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Giao dịch"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Ngân sách"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI"),
        ],
      ),
    );
  }
}