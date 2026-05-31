import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Services/gemini_service.dart';

class AIScreen extends StatefulWidget {
  const AIScreen({super.key});

  @override
  State<AIScreen> createState() => _AIScreenState();
}

class _AIScreenState extends State<AIScreen> {
  final TextEditingController aiController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool isLoading = false;

  List<Map<String, String>> messages = [];
  List<Map<String, dynamic>> chatHistory = [];

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "";

  final Map<String, List<String>> defaultCategories = {
    "expense": ["Ăn uống", "Mua sắm", "Di chuyển"],
    "income": ["Lương", "Thưởng", "Thu khác"],
    "debt": ["Cho vay", "Trả nợ", "Thu nợ"],
  };

  String _normalize(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const latin =      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    String result = text.toLowerCase();
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }
    return result;
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> sendMessage() async {
    final text = aiController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      messages.add({"role": "user", "text": text});
      isLoading = true;
    });
    aiController.clear();
    _scrollToBottom();

    try {
      final userCatSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("categories")
          .get();
      final userCats = userCatSnapshot.docs
          .map((doc) => doc.data()["name"]?.toString() ?? "")
          .toList();

      // Phân tích giao dịch
      final transactionResult = await GeminiService.analyzeTransaction(
        text,
        defaultCategories["expense"] ?? [],
        defaultCategories["income"] ?? [],
        defaultCategories["debt"] ?? [],
        userCats,
      );

      if (transactionResult != null) {
        double amount = (transactionResult["amount"] as num).toDouble();
        String category = transactionResult["category"] ?? "Khác";
        String type = transactionResult["type"] ?? "expense";
        bool isNewCategory = transactionResult["isNewCategory"] ?? false;

        if (isNewCategory) {
          final existingCats = await FirebaseFirestore.instance
              .collection("users")
              .doc(userId)
              .collection("categories")
              .get();

          final allExistingNames = [
            ...defaultCategories["expense"]!,
            ...defaultCategories["income"]!,
            ...defaultCategories["debt"]!,
            ...existingCats.docs.map((doc) => doc.data()["name"]?.toString() ?? ""),
          ];

          final categoryNorm = _normalize(category);
          final alreadyExists = allExistingNames.any((name) =>
          _normalize(name) == categoryNorm);

          if (!alreadyExists) {
            await FirebaseFirestore.instance
                .collection("users")
                .doc(userId)
                .collection("categories")
                .add({
              "name": category,
              "type": type,
              "createdAt": FieldValue.serverTimestamp(),
            });
          } else {
            final matchedName = allExistingNames.firstWhere(
                  (name) => _normalize(name) == categoryNorm,
              orElse: () => category,
            );
            category = matchedName;
            isNewCategory = false;
          }
        }

        double savedAmount = type == "expense" ? -amount : amount;

        await FirebaseFirestore.instance
            .collection("users")
            .doc(userId)
            .collection("transactions")
            .add({
          "type": type == "expense" ? 0 : type == "income" ? 1 : 2,
          "category": category,
          "amount": savedAmount,
          "note": text,
          "date": Timestamp.fromDate(DateTime.now()),
          "withPerson": "",
          "location": "",
          "event": "",
          "excludeFromReport": false,
        });

        await _syncBudgetSpent(category);
        await _checkBudgetWarning(category, savedAmount);

        final reply = "✅ Đã lưu giao dịch!\n"
            "📂 Nhóm: $category ${isNewCategory ? '(nhóm mới 🆕)' : ''}\n"
            "💰 Số tiền: ${amount.toStringAsFixed(0)}đ\n"
            "📊 Loại: ${type == 'expense' ? 'Khoản chi 🔴' : type == 'income' ? 'Khoản thu 🔵' : 'Vay/Nợ'}";

        setState(() => messages.add({"role": "ai", "text": reply}));
        chatHistory.add({"role": "user", "parts": [{"text": text}]});
        chatHistory.add({"role": "model", "parts": [{"text": reply}]});

      } else {
        // Câu hỏi thường
        chatHistory.add({
          "role": "user",
          "parts": [{"text": text}]
        });
        final response = await GeminiService.askAIWithHistory(chatHistory);
        chatHistory.add({
          "role": "model",
          "parts": [{"text": response}]
        });
        setState(() => messages.add({"role": "ai", "text": response}));
      }

    } catch (e) {
      setState(() => messages.add({"role": "ai", "text": "Lỗi: $e"}));
    } finally {
      setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  Future<void> _syncBudgetSpent(String category) async {
    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 1);

      final budgetSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("budgets")
          .where("month", isEqualTo: now.month)
          .where("year", isEqualTo: now.year)
          .get();

      if (budgetSnapshot.docs.isEmpty) return;

      final categoryNorm = _normalize(category);
      final matched = budgetSnapshot.docs.where((doc) {
        final budgetCat = _normalize(doc.data()["category"] ?? "");
        return budgetCat == categoryNorm;
      }).toList();

      if (matched.isEmpty) return;

      final txSnapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where("date", isLessThan: Timestamp.fromDate(endOfMonth))
          .get();

      double totalSpent = 0;
      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        final txCat = _normalize(data["category"] ?? "");
        final amount = (data["amount"] as num).toDouble();
        if (txCat == categoryNorm && amount < 0) {
          totalSpent += amount.abs();
        }
      }

      await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("budgets")
          .doc(matched.first.id)
          .update({"spent": totalSpent});

    } catch (e) {
      print("syncBudgetSpent ERROR: $e");
    }
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
        final budgetCat = _normalize(doc.data()["category"] ?? "");
        return budgetCat == categoryNorm;
      }).toList();

      if (matched.isEmpty) return;

      final budgetData = matched.first.data();
      double limit = (budgetData["limit"] as num).toDouble();
      double spent = (budgetData["spent"] as num).toDouble();
      double percent = limit > 0 ? spent / limit : 0;

      if (!mounted) return;

      String warningMessage = "";
      if (percent >= 1.0) {
        warningMessage = "🚨 Vượt ngân sách \"${budgetData['category']}\"\n"
            "Đã chi: ${spent.toStringAsFixed(0)}đ / ${limit.toStringAsFixed(0)}đ";
      } else if (percent >= 0.8) {
        warningMessage = "⚠️ Ngân sách \"${budgetData['category']}\" đã dùng ${(percent * 100).toInt()}%\n"
            "Còn lại: ${(limit - spent).toStringAsFixed(0)}đ";
      }

      if (warningMessage.isNotEmpty) {
        setState(() => messages.add({"role": "ai", "text": warningMessage}));
        _scrollToBottom();
      }

    } catch (e) {
      print("checkBudget ERROR: $e");
    }
  }

  Future<void> analyzeThisMonth() async {
    setState(() {
      messages.add({"role": "user", "text": "📊 Phân tích chi tiêu tháng này cho tôi"});
      isLoading = true;
    });
    _scrollToBottom();

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);

      final snapshot = await FirebaseFirestore.instance
          .collection("users")
          .doc(userId)
          .collection("transactions")
          .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .orderBy("date", descending: true)
          .get();

      double totalExpense = 0;
      double totalIncome = 0;
      Map<String, double> categoryMap = {};
      List<String> transactionList = [];

      for (var doc in snapshot.docs) {
        final data = doc.data();
        double amount = (data["amount"] as num).toDouble();
        String category = data["category"] ?? "Khác";
        int type = data["type"] ?? 0;

        if (type != 2) {
          if (amount < 0) {
            totalExpense += amount.abs();
            categoryMap[category] = (categoryMap[category] ?? 0) + amount.abs();
          } else {
            totalIncome += amount;
          }
        }

        final date = (data["date"] as Timestamp).toDate();
        transactionList.add(
            "${date.day}/${date.month}: $category ${amount > 0 ? '+' : ''}${amount.toStringAsFixed(0)}đ");
      }

      final sortedCats = categoryMap.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final catDetail = sortedCats
          .map((e) => "${e.key}: ${e.value.toStringAsFixed(0)}đ")
          .join(", ");

      final context = """
=== BÁO CÁO THÁNG ${now.month}/${now.year} ===
📈 Tổng thu: ${totalIncome.toStringAsFixed(0)}đ
📉 Tổng chi: ${totalExpense.toStringAsFixed(0)}đ
💹 Tiết kiệm: ${(totalIncome - totalExpense).toStringAsFixed(0)}đ
🏆 Chi tiêu theo nhóm: $catDetail
📋 Danh sách giao dịch: ${transactionList.join(' | ')}
""";

      final response = await GeminiService.analyzeMonthlySpending(context);
      setState(() => messages.add({"role": "ai", "text": response}));
      chatHistory.add({"role": "user", "parts": [{"text": context}]});
      chatHistory.add({"role": "model", "parts": [{"text": response}]});

    } catch (e) {
      setState(() => messages.add({"role": "ai", "text": "Lỗi: $e"}));
    } finally {
      setState(() => isLoading = false);
      _scrollToBottom();
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isUser ? Colors.green : const Color(0xFF2C2C2E),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isUser ? 16 : 4),
            bottomRight: Radius.circular(isUser ? 4 : 16),
          ),
        ),
        child: Text(
          msg["text"] ?? "",
          style: const TextStyle(color: Colors.white, fontSize: 15),
        ),
      ),
    );
  }

  Widget _buildSuggestion(String text) {
    return GestureDetector(
      onTap: () {
        aiController.text = text;
        sendMessage();
      },
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 32),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.green.withOpacity(0.4)),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white70)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text("AI Assistant",
            style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart, color: Colors.green),
            tooltip: "Phân tích tháng này",
            onPressed: isLoading ? null : analyzeThisMonth,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.grey),
            onPressed: () {
              setState(() {
                messages.clear();
                chatHistory.clear();
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (messages.isEmpty)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.smart_toy, color: Colors.green, size: 60),
                    const SizedBox(height: 16),
                    const Text(
                      "Xin chào! Tôi có thể giúp gì cho bạn?",
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    const SizedBox(height: 20),
                    _buildSuggestion("🍜 ăn cơm 50k"),
                    _buildSuggestion("📊 Phân tích chi tiêu tháng này"),
                    _buildSuggestion("💡 Tôi nên cắt giảm chi tiêu ở đâu?"),
                    _buildSuggestion("🎯 Lập kế hoạch tiết kiệm cho tôi"),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.all(16),
                itemCount: messages.length + (isLoading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index == messages.length) {
                    return Align(
                      alignment: Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2C2C2E),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: Colors.green,
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text("AI đang trả lời...",
                                style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    );
                  }
                  return _buildMessage(messages[index]);
                },
              ),
            ),

          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
            color: const Color(0xFF1C1C1E),
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: aiController,
                      style: const TextStyle(color: Colors.white),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => isLoading ? null : sendMessage(),
                      decoration: InputDecoration(
                        hintText: "Nhập giao dịch hoặc câu hỏi...",
                        hintStyle: const TextStyle(color: Colors.grey),
                        filled: true,
                        fillColor: const Color(0xFF2C2C2E),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: isLoading ? null : sendMessage,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: isLoading ? Colors.grey : Colors.green,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.send,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}