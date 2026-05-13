import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final CollectionReference _transactionsRef =
  FirebaseFirestore.instance.collection('transactions');

  // Thêm giao dịch
  Future<void> addTransaction(TransactionModel t) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final data = t.toMap();
    data['uid'] = user.uid;
    data['createdAt'] = FieldValue.serverTimestamp();

    await _transactionsRef.add(data);
    print('✅ Đã thêm transaction: ${data['amount']} - ${data['category']}');
  }

  // Cập nhật giao dịch
  Future<void> updateTransaction(TransactionModel t) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final docSnapshot = await _transactionsRef.doc(t.id).get();

    // SỬA LỖI: Lấy data an toàn với type casting
    final docData = docSnapshot.data() as Map<String, dynamic>?;

    if (docSnapshot.exists && docData != null && docData['uid'] != user.uid) {
      throw Exception('Không có quyền sửa');
    }

    final data = t.toMap();
    data['uid'] = user.uid;
    await _transactionsRef.doc(t.id).update(data);
  }

  // Xóa giao dịch
  Future<void> deleteTransaction(String id) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final docSnapshot = await _transactionsRef.doc(id).get();

    // SỬA LỖI: Lấy data an toàn với type casting
    final docData = docSnapshot.data() as Map<String, dynamic>?;

    if (docSnapshot.exists && docData != null && docData['uid'] != user.uid) {
      throw Exception('Không có quyền xóa');
    }

    await _transactionsRef.doc(id).delete();
    print('✅ Đã xóa transaction: $id');
  }

  // Lấy danh sách giao dịch của user hiện tại
  Stream<List<TransactionModel>> getTransactions() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print('❌ Không có user đăng nhập');
      return Stream.value([]);
    }

    print('🔍 Đang query transactions cho uid: ${user.uid}');

    return _transactionsRef
        .where('uid', isEqualTo: user.uid)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print('📊 Tìm thấy ${snapshot.docs.length} giao dịch');
      return snapshot.docs
          .map((doc) {
        // SỬA LỖI: Ép kiểu dữ liệu an toàn
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap(doc.id, data);
      })
          .toList();
    });
  }

  // Debug: Lấy tất cả giao dịch
  Future<List<TransactionModel>> getAllTransactionsDebug() async {
    final snapshot = await _transactionsRef.get();
    print('📊 Tổng số transactions trong collection: ${snapshot.docs.length}');

    final List<TransactionModel> transactions = [];

    for (var doc in snapshot.docs) {
      // SỬA LỖI: Ép kiểu dữ liệu an toàn
      final data = doc.data() as Map<String, dynamic>;
      print('- ${doc.id}: $data');
      transactions.add(TransactionModel.fromMap(doc.id, data));
    }

    return transactions;
  }

  // Lọc theo danh mục
  Stream<List<TransactionModel>> getTransactionsByCategory(String category) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _transactionsRef
        .where('uid', isEqualTo: user.uid)
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TransactionModel.fromMap(doc.id, data);
    })
        .toList());
  }

  // Lọc theo loại
  Stream<List<TransactionModel>> getTransactionsByType(int type) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return Stream.value([]);

    return _transactionsRef
        .where('uid', isEqualTo: user.uid)
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TransactionModel.fromMap(doc.id, data);
    })
        .toList());
  }
}