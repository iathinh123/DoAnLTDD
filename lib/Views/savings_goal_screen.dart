import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/savings_goal_model.dart';
import '../Services/gemini_service.dart';

class SavingsGoalScreen extends StatefulWidget {
  const SavingsGoalScreen({super.key});

  @override
  State<SavingsGoalScreen> createState() => _SavingsGoalScreenState();
}

class _SavingsGoalScreenState extends State<SavingsGoalScreen> {
  List<SavingsGoal> goals = [];
  bool isLoading = true;

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "";

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  Future<void> _loadGoals() async {
    final snapshot = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("savings_goals")
        .orderBy("deadline")
        .get();

    setState(() {
      goals = snapshot.docs
          .map((doc) => SavingsGoal.fromMap(doc.id, doc.data()))
          .toList();
      isLoading = false;
    });
  }

  Future<void> _analyzeGoal(SavingsGoal goal) async {
    // Load financial data
    final txSnap = await FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("transactions")
        .orderBy("date", descending: true)
        .limit(30)
        .get();

    double totalIncome = 0;
    double totalExpense = 0;
    for (var doc in txSnap.docs) {
      final amount = (doc.data()["amount"] as num).toDouble();
      if (amount > 0) totalIncome += amount;
      else totalExpense += amount.abs();
    }

    final now = DateTime.now();
    final daysLeft = goal.deadline.difference(now).inDays;
    final monthsLeft = (daysLeft / 30).ceil();

    final goalData = """
=== MỤC TIÊU TIẾT KIỆM ===
🎯 Mục tiêu: ${goal.title}
💰 Cần tiết kiệm: ${goal.targetAmount.toStringAsFixed(0)}đ
✅ Đã có: ${goal.currentAmount.toStringAsFixed(0)}đ
📊 Còn thiếu: ${goal.remaining.toStringAsFixed(0)}đ
📅 Deadline: ${goal.deadline.day}/${goal.deadline.month}/${goal.deadline.year}
⏰ Còn $daysLeft ngày ($monthsLeft tháng)
""";

    final financialData = """
=== TÀI CHÍNH HIỆN TẠI ===
📈 Thu nhập trung bình: ${totalIncome.toStringAsFixed(0)}đ
📉 Chi tiêu trung bình: ${totalExpense.toStringAsFixed(0)}đ
💹 Tiết kiệm được: ${(totalIncome - totalExpense).toStringAsFixed(0)}đ
""";

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const AlertDialog(
        backgroundColor: Color(0xFF1E1E1E),
        content: Row(
          children: [
            CircularProgressIndicator(color: Colors.green),
            SizedBox(width: 16),
            Text("AI đang phân tích...",
                style: TextStyle(color: Colors.white)),
          ],
        ),
      ),
    );

    final response = await GeminiService.analyzeSavingsGoal(
        goalData, financialData);

    if (mounted) Navigator.pop(context);

    if (mounted) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.smart_toy, color: Colors.green),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  goal.title,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Text(
              response,
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đóng",
                  style: TextStyle(color: Colors.green)),
            ),
          ],
        ),
      );
    }
  }

  void _showAddGoalSheet() {
    final titleController = TextEditingController();
    final targetController = TextEditingController();
    final currentController = TextEditingController();
    final noteController = TextEditingController();
    DateTime selectedDeadline = DateTime.now().add(const Duration(days: 30));

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1C1C1E),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setST) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20, right: 20, top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("🎯 Mục tiêu tiết kiệm mới",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold)),
                const SizedBox(height: 20),

                _buildTextField(titleController, "Tên mục tiêu (VD: Mua iPhone)", Icons.flag),
                const SizedBox(height: 12),
                _buildTextField(targetController, "Số tiền cần tiết kiệm", Icons.attach_money,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(currentController, "Đã tiết kiệm được (nếu có)", Icons.savings,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildTextField(noteController, "Ghi chú", Icons.note),
                const SizedBox(height: 16),

                // Chọn deadline
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: ctx,
                      initialDate: selectedDeadline,
                      firstDate: DateTime.now(),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) {
                      setST(() => selectedDeadline = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2C2C2E),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            color: Colors.green, size: 20),
                        const SizedBox(width: 12),
                        Text(
                          "Deadline: ${selectedDeadline.day}/${selectedDeadline.month}/${selectedDeadline.year}",
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final target = double.tryParse(targetController.text) ?? 0;
                      final current = double.tryParse(currentController.text) ?? 0;

                      if (title.isEmpty || target <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text("Vui lòng nhập đầy đủ thông tin")),
                        );
                        return;
                      }

                      final goal = SavingsGoal(
                        id: "",
                        title: title,
                        targetAmount: target,
                        currentAmount: current,
                        deadline: selectedDeadline,
                        note: noteController.text.trim(),
                      );

                      await FirebaseFirestore.instance
                          .collection("users")
                          .doc(userId)
                          .collection("savings_goals")
                          .add(goal.toMap());

                      if (ctx.mounted) Navigator.pop(ctx);
                      await _loadGoals();
                    },
                    child: const Text("LƯU MỤC TIÊU",
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String hint, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.green, size: 20),
        filled: true,
        fillColor: const Color(0xFF2C2C2E),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("Mục tiêu tiết kiệm",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.green),
            onPressed: _showAddGoalSheet,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator(color: Colors.green))
          : goals.isEmpty
          ? Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.savings,
                color: Colors.grey, size: 60),
            const SizedBox(height: 16),
            const Text("Chưa có mục tiêu nào",
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _showAddGoalSheet,
              icon: const Icon(Icons.add),
              label: const Text("Thêm mục tiêu"),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: goals.length,
        itemBuilder: (context, index) {
          final goal = goals[index];
          final daysLeft =
              goal.deadline.difference(DateTime.now()).inDays;

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: goal.isCompleted
                  ? Border.all(color: Colors.green, width: 1.5)
                  : daysLeft < 7
                  ? Border.all(
                  color: Colors.red.withOpacity(0.5),
                  width: 1.5)
                  : null,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        goal.isCompleted
                            ? "✅ ${goal.title}"
                            : goal.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    // Nút AI phân tích
                    GestureDetector(
                      onTap: () => _analyzeGoal(goal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: Colors.green.withOpacity(0.5)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.smart_toy,
                                color: Colors.green, size: 14),
                            SizedBox(width: 4),
                            Text("AI phân tích",
                                style: TextStyle(
                                    color: Colors.green,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Progress bar
                LinearProgressIndicator(
                  value: goal.percent > 1 ? 1 : goal.percent,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    goal.isCompleted ? Colors.green : Colors.blue,
                  ),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "${(goal.percent * 100).toInt()}%",
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${goal.currentAmount.toStringAsFixed(0)}đ / ${goal.targetAmount.toStringAsFixed(0)}đ",
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Còn thiếu: ${goal.remaining.toStringAsFixed(0)}đ",
                      style: TextStyle(
                        color: goal.isCompleted
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      daysLeft > 0
                          ? "⏰ Còn $daysLeft ngày"
                          : "⚠️ Đã quá hạn",
                      style: TextStyle(
                        color: daysLeft < 7
                            ? Colors.red
                            : Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}