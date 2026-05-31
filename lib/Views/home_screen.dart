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
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_typeahead/flutter_typeahead.dart';
import '../Services/gemini_service.dart';
import 'AI_screen.dart';
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
  String _withPerson = "";
  String _location = "";
  String _event = "";
  bool _excludeFromReport = false;

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
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: TextStyle(color: color, fontSize: 18)),
        content: Text(
          message,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
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

        // chi tiết
        "withPerson": _withPerson,
        "location": _location,
        "event": _event,
        "excludeFromReport": _excludeFromReport,
      });
      await _checkBudgetWarning(selectedCategory, amountValue);
      amountController.clear();
      noteController.clear();

      setState(() {
        selectedCategory = "Chọn nhóm";
        selectedDate = DateTime.now();

        _withPerson = "";
        _location = "";
        _event = "";
        _excludeFromReport = false;
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

  Future<List<String>> _fetchPlacePredictions(String input) async {
    // Thay API_KEY của bạn được cấp từ Google Cloud Console vào đây
    const String apiKey = "YOUR_GOOGLE_MAPS_API_KEY";
    final String url = "https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$input&key=$apiKey&language=vi&components=country:vn";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final predictions = data['predictions'] as List;
        return predictions.map((p) => p['description'] as String).toList();
      }
    } catch (e) {
      print("Lỗi gọi API địa điểm: $e");
    }
    return [];
  }

  void _showLocationPicker(Function setModalState) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Địa điểm giao dịch", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: SizedBox(
          width: double.maxFinite,
          child: TypeAheadField<String>(
            // Cấu hình ô nhập liệu
            builder: (context, controller, focusNode) {
              return TextField(
                controller: controller,
                focusNode: focusNode,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: "Nhập địa điểm (Ví dụ: BigC, Highlands...)",
                  hintStyle: TextStyle(color: Colors.grey),
                ),
              );
            },
            // Hàm này sẽ tự động chạy và gọi API mỗi khi người dùng gõ chữ
            suggestionsCallback: (searchPattern) async {
              if (searchPattern.length < 3) return []; // Gõ trên 3 ký tự mới gọi API để tiết kiệm
              return await _fetchPlacePredictions(searchPattern);
            },
            // Giao diện hiển thị từng dòng gợi ý trong danh sách đổ xuống
            itemBuilder: (context, String prediction) {
              return Container(
                color: const Color(0xFF2C2C2E), // Đổi màu nền tối tại đây thay vì đặt trong ListTile
                child: ListTile(
                  leading: const Icon(Icons.location_on, color: Colors.green),
                  title: Text(
                    prediction,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              );
            },
            // Xử lý khi người dùng ấn chọn một địa điểm trong danh sách
            onSelected: (String prediction) {
              setModalState(() {
                _location = prediction; // Gán địa điểm được chọn vào biến toàn cục
              });
              Navigator.pop(context);
            },
          ),
        ),
      ),
    );
  }

  void _showEventPicker(Function setModalState) {
    // Danh sách sự kiện mẫu, bạn có thể tự định nghĩa thêm
    final List<String> events = ["Du lịch hè", "Đám cưới", "Sinh nhật", "Tết 2026"];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text("Chọn sự kiện", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          ),
          ...events.map((e) => ListTile(
            title: Text(e, style: const TextStyle(color: Colors.white)),
            onTap: () {
              setModalState(() {
                _event = e;
              });
              Navigator.pop(ctx);
            },
          )).toList(),
        ],
      ),
    );
  }

  void _showWithPersonPicker(Function setModalState) {
    final personController = TextEditingController(text: _withPerson);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1C1C1E),
        title: const Text("Đi cùng ai?", style: TextStyle(color: Colors.white, fontSize: 16)),
        content: TextField(
          controller: personController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: "Nhập tên người đi cùng...",
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Hủy")),
          TextButton(
            onPressed: () {
              setModalState(() {
                _withPerson = personController.text;
              });
              Navigator.pop(context);
            },
            child: const Text("Xác nhận", style: TextStyle(color: Colors.green)),
          ),
        ],
      ),
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Thêm giao dịch mới", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
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
                    style: const TextStyle(
                      color: Colors.white,
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
                    leading: const Icon(Icons.category, color: Colors.white),
                    title: Text(
                      selectedCategory,
                      style: const TextStyle(color: Colors.white),
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

                    leading: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                    ),

                    title: Text(
                      "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                      style: const TextStyle(color: Colors.white),
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
                    style: const TextStyle(color: Colors.white),

                    decoration: const InputDecoration(
                      hintText: "Ghi chú",
                      hintStyle: TextStyle(color: Colors.grey),
                    ),
                  ),

                  // ================= KHU VỰC CHI TIẾT ĐƯỢC MỞ RỘNG (GIAO DIỆN TỐI) =================
                  if (_showDetails) ...[
                    _buildDetailRow(
                        Icons.people_outline,
                        "Với",
                        _withPerson.isEmpty ? "Gắn thẻ ai đó" : _withPerson,
                            () => _showWithPersonPicker(setModalState) // Kết nối chức năng chọn người
                    ),
                    _buildDetailRow(
                        Icons.location_on_outlined,
                        "Đặt vị trí",
                        _location.isEmpty ? "Thêm địa điểm" : _location,
                            () => _showLocationPicker(setModalState) // Kết nối chức năng chọn vị trí
                    ),
                    _buildDetailRow(
                        Icons.card_travel_outlined,
                        "Chọn sự kiện",
                        _event.isEmpty ? "Chuyến đi, đám cưới..." : _event,
                            () => _showEventPicker(setModalState) // Kết nối chức năng chọn sự kiện
                    ),
                    _buildDetailRow(
                        Icons.access_alarm,
                        "Đặt nhắc nhở",
                        "Không",
                            () {
                          // Có thể mở rộng tích hợp thư viện Local Notifications ở đây
                        }
                    ),

                    // Ô hình ảnh hóa đơn
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: const [
                          Icon(Icons.add_photo_alternate_outlined, color: Colors.green),
                          SizedBox(width: 12),
                          Text("Thêm Hình Ảnh", style: TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),

                    // Công tắc loại trừ báo cáo
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFF2C2C2E), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Không tính vào báo cáo", style: TextStyle(color: Colors.white, fontSize: 14)),
                          Switch(
                            value: _excludeFromReport,
                            activeColor: Colors.green,
                            onChanged: (val) {
                              setModalState(() => _excludeFromReport = val);
                            },
                          ),
                        ],
                      ),
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
        color: const Color(0xFF2C2C2E), // Màu xám tối nhẹ hơn màu nền gốc một chút
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14),
        leading: Icon(icon, color: Colors.grey[400], size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14)),
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
          const AIScreen(),
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
          BottomNavigationBarItem(icon: Icon(Icons.smart_toy), label: "AI"),
        ],
      ),
    );
  }
}