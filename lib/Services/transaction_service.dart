import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Truy cập users/{uid}/transactions
  CollectionReference _getUserTransactionsRef() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    return _firestore
        .collection('users')
        .doc(user.uid)
        .collection('transactions');
  }

  // Thêm giao dịch
  Future<void> addTransaction(TransactionModel t) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Chưa đăng nhập');

    final transactionsRef = _getUserTransactionsRef();

    final data = t.toMap();
    data['uid'] = user.uid;
    data['createdAt'] = FieldValue.serverTimestamp();

    await transactionsRef.add(data);

    print(
      '✅ Đã thêm transaction vào sub-collection: ${data['amount']} - ${data['category']}',
    );
  }

  // Cập nhật giao dịch
  Future<void> updateTransaction(TransactionModel t) async {
    final transactionsRef = _getUserTransactionsRef();

    final docSnapshot = await transactionsRef.doc(t.id).get();

    final docData = docSnapshot.data() as Map<String, dynamic>?;

    if (docSnapshot.exists &&
        docData != null &&
        docData['uid'] != FirebaseAuth.instance.currentUser?.uid) {
      throw Exception('Không có quyền sửa');
    }

    final data = t.toMap();
    data['uid'] = FirebaseAuth.instance.currentUser?.uid;

    await transactionsRef.doc(t.id).update(data);
  }

  // Xóa giao dịch
  Future<void> deleteTransaction(String id) async {
    final transactionsRef = _getUserTransactionsRef();

    final docSnapshot = await transactionsRef.doc(id).get();

    final docData = docSnapshot.data() as Map<String, dynamic>?;

    if (docSnapshot.exists &&
        docData != null &&
        docData['uid'] != FirebaseAuth.instance.currentUser?.uid) {
      throw Exception('Không có quyền xóa');
    }

    await transactionsRef.doc(id).delete();

    print('✅ Đã xóa transaction: $id');
  }

  // Lấy danh sách giao dịch
  Stream<List<TransactionModel>> getTransactions() {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      print('❌ Không có user đăng nhập');
      return Stream.value([]);
    }

    print(
      '🔍 Đang query sub-collection transactions cho uid: ${user.uid}',
    );

    return _getUserTransactionsRef()
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      print(
        '📊 Tìm thấy ${snapshot.docs.length} giao dịch trong sub-collection',
      );

      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return TransactionModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  // Lọc theo danh mục
  Stream<List<TransactionModel>> getTransactionsByCategory(
      String category,
      ) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _getUserTransactionsRef()
        .where('category', isEqualTo: category)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TransactionModel.fromMap(doc.id, data);
    }).toList());
  }

  // Lọc theo loại
  Stream<List<TransactionModel>> getTransactionsByType(int type) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Stream.value([]);
    }

    return _getUserTransactionsRef()
        .where('type', isEqualTo: type)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return TransactionModel.fromMap(doc.id, data);
    }).toList());
  }
}