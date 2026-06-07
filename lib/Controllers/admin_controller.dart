import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/transaction_model.dart';
import '../models/for_group_jar/group_jar_model.dart';

class AdminController {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  //Lấy danh sách toàn bộ User (trừ tài khoản Admin hiện tại để tránh tự chặn chính mình)
  Stream<List<UserModel>> streamUsers() {
    String currentUid = FirebaseAuth.instance.currentUser?.uid ?? "";
    return _firestore.collection('NguoiDung').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data(), doc.id))
          .where((user) => user.uid != currentUid) // Lọc bỏ chính admin hiện tại
          .toList();
    });
  }

  //Chức năng Chặn / Mở chặn User
  Future<void> toggleBlockUser(String uid, bool shouldBlock) async {
    try {
      String newRole = shouldBlock ? 'blocked' : 'user';

      await _firestore.collection('NguoiDung').doc(uid).update({
        'role': newRole,
        'isBlocked': shouldBlock,
      });
      print("✅ Đã cập nhật trạng thái chặn của $uid thành: $shouldBlock");
    } catch (e) {
      print("❌ Lỗi khi cập nhật trạng thái chặn: $e");
    }
  }

  //Tạo User mới phân quyền Role (Sử dụng Firebase Auth phụ)
  Future<String?> createAccountWithRole({
    required String email,
    required String password,
    required String name,
    required String role,
  }) async {
    try {
      // Tạo một Firebase app phụ để đăng ký mà không làm mất session Đăng nhập của Admin hiện tại
      FirebaseApp secondaryApp = await Firebase.initializeApp(
        name: 'SecondaryApp',
        options: Firebase.app().options,
      );

      UserCredential userCredential = await FirebaseAuth.instanceFor(app: secondaryApp)
          .createUserWithEmailAndPassword(email: email, password: password);

      String newUid = userCredential.user!.uid;

      // Lưu thông tin vào Firestore 'NguoiDung'
      await _firestore.collection('NguoiDung').doc(newUid).set({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'isBlocked': false,
        'avatarUrl': '',
      });

      // Xoá app phụ sau khi tạo xong để giải phóng bộ nhớ
      await secondaryApp.delete();
      return null; // Thành công không có lỗi
    } catch (e) {
      return e.toString(); // Trả về thông báo lỗi
    }
  }

  //Lấy danh sách giao dịch của một User cụ thể
  Stream<List<TransactionModel>> streamUserTransactions(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return TransactionModel.fromMap(doc.id, data);
      }).toList();
    });
  }

  //lấy toàn bộ danh sách hũ nhóm có trong hệ thống
  Stream<List<GroupJarModel>> streamAllGroupJars() {
    return _firestore
        .collection('group_jars') // Tên collection gốc nằm ngoài rìa
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return GroupJarModel.fromMap(doc.id, doc.data());
      }).toList();
    });
  }

  //lấy danh sách thành viên nằm trong sub-collection 'members' của một hũ cụ thể
  Future<List<Map<String, dynamic>>> getJarMembers(String jarId) async {
    final snapshot = await _firestore
        .collection('group_jars')
        .doc(jarId)
        .collection('members')
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  //lấy thông tin Tên chủ hũ dựa theo UID người tạo (createdBy)
  Future<String> getUserNameByUid(String uid) async {
    try {
      final doc = await _firestore.collection('NguoiDung').doc(uid).get();
      if (doc.exists) {
        return doc.data()?['name'] ?? 'Không rõ';
      }
    } catch (_) {}
    return 'Thành viên hệ thống';
  }
}