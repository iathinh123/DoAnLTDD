import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/transaction_model.dart';

class TransactionService {
  final collection = FirebaseFirestore.instance.collection('transactions');

  Future addTransaction(TransactionModel t) async {
    await collection.add(t.toMap());
  }

  Stream<List<TransactionModel>> getTransactions() {
    return collection.orderBy('date', descending: true).snapshots().map(
          (snapshot) => snapshot.docs
          .map((doc) => TransactionModel.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }
}