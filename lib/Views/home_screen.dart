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

  // ================= LƯU GIAO DỊCH =================
  void _saveTransaction() async {
    double amountValue = double.tryParse(amountController.text) ?? 0;
    if (amountValue <= 0 || selectedCategory == "Chọn nhóm") return;

    final docRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .doc();

    final newTransaction = TransactionModel(
      id: docRef.id,
      type: selectedType,
      category: selectedCategory,
      amount: amountValue,
      note: noteController.text,
      date: selectedDate,
    );

    await docRef.set(newTransaction.toMap());

    amountController.clear();
    noteController.clear();
    setState(() {
      selectedCategory = "Chọn nhóm";
      selectedDate = DateTime.now();
    });

    if (mounted) Navigator.pop(context);
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
          color: selectedType == i ? const Color(0xFF4CAF50) : const Color(0xFF3A3A3C),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(t, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildCard({required String title, required String action, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1A1A), borderRadius: BorderRadius.circular(16)),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: const TextStyle(color: Colors.white70, fontSize: 16)),
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
                  const CircleAvatar(
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.receipt, color: Colors.white),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.category,
                          style: const TextStyle(color: Colors.white),
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
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setST) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Nhóm mới", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),
                TextField(
                  controller: nameCatController,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white),
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

    // Chỉ lấy những nhóm có 'type' khớp với 'typeKey' hiện tại
    final filteredUserCats = userDefinedCategories
        .where((cat) => cat["type"] == typeKey)
        .map((cat) => cat["name"] as String)
        .toList();

    displayList.addAll(filteredUserCats);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))
      ),
      builder: (sheetContext) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text("Chọn nhóm",
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: ListView(
                children: [
                  // Hiển thị toàn bộ danh sách đã gộp
                  ...displayList.map((categoryName) => ListTile(
                    leading: const Icon(Icons.label_outline, color: Colors.white70),
                    title: Text(categoryName, style: const TextStyle(color: Colors.white)),
                    onTap: () {
                      setModalState(() => selectedCategory = categoryName);
                      Navigator.pop(sheetContext);
                    },
                  )),

                  // Nút thêm nhóm mới luôn ở dưới cùng
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
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 20, right: 20, top: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Thêm giao dịch mới", style: TextStyle(color: Colors.white, fontSize: 18)),
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
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  style: const TextStyle(color: Colors.white, fontSize: 24),
                  decoration: const InputDecoration(hintText: "Số tiền", hintStyle: TextStyle(color: Colors.grey)),
                ),
                ListTile(
                  onTap: () => _showCategoryPicker(setModalState),
                  leading: const Icon(Icons.category, color: Colors.white),
                  title: Text(selectedCategory, style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
                ListTile(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: selectedDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setModalState(() => selectedDate = picked);
                  },
                  leading: const Icon(Icons.calendar_today, color: Colors.white),
                  title: Text("${selectedDate.day}/${selectedDate.month}/${selectedDate.year}", style: const TextStyle(color: Colors.white)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                    onPressed: _saveTransaction,
                    child: const Text("LƯU GIAO DỊCH", style: TextStyle(fontWeight: FontWeight.bold)),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
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
                                formatMoney(balance),
                                style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(Icons.search, color: Colors.white),
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(
                                    builder: (context) => AdvancedSearchScreen(allTransactions: transactions),
                                  ));
                                },
                              ),
                              IconButton(
                                icon: Icon(isBalanceVisible ? Icons.visibility : Icons.visibility_off, color: Colors.white, size: 20),
                                onPressed: () => setState(() => isBalanceVisible = !isBalanceVisible),
                              ),
                            ],
                          ),
                          const Text("Tổng số dư", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                      const Icon(Icons.notifications_none, color: Colors.white),
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
                        const Expanded(child: Text("Tiền mặt", style: TextStyle(color: Colors.white))),
                        Text(formatMoney(balance)),
                      ],
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
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () => _showAddTaskSheet(context),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (i) => setState(() => currentIndex = i),
        backgroundColor: Colors.black,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Tổng quan"),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: "Giao dịch"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Ngân sách"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}