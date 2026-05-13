import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Models/budget_model.dart';
import '../Models/transaction_model.dart';

class BudgetService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Budgets reference (dùng chung cấu trúc với HomeScreen)
  CollectionReference get _budgetsRef =>
      _db.collection('users').doc(_uid).collection('budgets');

  // Transactions reference (dùng chung cấu trúc với HomeScreen)
  CollectionReference get _transactionsRef =>
      _db.collection('users').doc(_uid).collection('transactions');

  // Lấy danh sách ngân sách theo tháng
  Stream<List<Budget>> getBudgets(int month, int year) {
    return _budgetsRef
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Budget.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList());
  }

  // Thêm ngân sách
  Future<void> addBudget(Budget budget) async {
    await _budgetsRef.add(budget.toMap());
  }

  // Cập nhật ngân sách
  Future<void> updateBudget(Budget budget) async {
    await _budgetsRef.doc(budget.id).update(budget.toMap());
  }

  // Xóa ngân sách
  Future<void> deleteBudget(String id) async {
    await _budgetsRef.doc(id).delete();
  }

  // Tính spent từ transactions thực tế
  Future<double> calcSpent(String category, int month, int year) async {
    if (_uid == null) return 0;

    final snap = await _transactionsRef
        .where('category', isEqualTo: category)
        .where('type', isEqualTo: 0) // 0 = chi tiêu
        .get();

    double total = 0;
    for (var doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final t = TransactionModel.fromMap(doc.id, data);
      if (t.date.month == month && t.date.year == year) {
        total += t.amount.abs();
      }
    }
    return total;
  }

  // Sync tất cả budgets
  Future<void> syncAllSpent(int month, int year) async {
    if (_uid == null) return;

    final snap = await _budgetsRef
        .where('month', isEqualTo: month)
        .where('year', isEqualTo: year)
        .get();

    for (var doc in snap.docs) {
      final budget = Budget.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      final spent = await calcSpent(budget.category, month, year);
      await _budgetsRef.doc(doc.id).update({'spent': spent});
    }
  }

  // Lắng nghe transactions và tự động sync
  void listenToTransactionsAndSync(int month, int year) {
    if (_uid == null) return;

    _transactionsRef
        .where('type', isEqualTo: 0) // Chỉ lắng nghe chi tiêu
        .snapshots()
        .listen((snapshot) {
      syncAllSpent(month, year);
    });
  }
}