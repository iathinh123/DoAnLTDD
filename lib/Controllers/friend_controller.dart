import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FriendController {
  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final String currentUid = FirebaseAuth.instance.currentUser!.uid;

  Stream<QuerySnapshot> getAllUsers() {
    return firestore
        .collection("NguoiDung")
        .snapshots();
  }

  Stream<QuerySnapshot> getFriends() {
    return firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("friends")
        .snapshots();
  }

  Stream<QuerySnapshot> getRequests() {
    return firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("received_requests")
        .snapshots();
  }

  Future<void> sendRequest(String targetUid) async {

    final currentUserDoc = await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .get();

    final currentUserData = currentUserDoc.data();

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("sent_requests")
        .doc(targetUid)
        .set({
      "createdAt": FieldValue.serverTimestamp(),
    });

    await firestore
        .collection("NguoiDung")
        .doc(targetUid)
        .collection("received_requests")
        .doc(currentUid)
        .set({
      "name": currentUserData?["name"],
      "email": currentUserData?["email"],
      "avatarUrl": currentUserData?["avatarUrl"],
    });
  }

  Future<void> acceptRequest(
      String senderUid,
      Map<String, dynamic> senderData,
      Map<String, dynamic> currentUser,
      ) async {

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("friends")
        .doc(senderUid)
        .set(senderData);

    await firestore
        .collection("NguoiDung")
        .doc(senderUid)
        .collection("friends")
        .doc(currentUid)
        .set(currentUser);

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("received_requests")
        .doc(senderUid)
        .delete();

    await firestore
        .collection("NguoiDung")
        .doc(senderUid)
        .collection("sent_requests")
        .doc(currentUid)
        .delete();
  }

  Future<void> rejectRequest(
      String senderUid,
      ) async {

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("received_requests")
        .doc(senderUid)
        .delete();

    await firestore
        .collection("NguoiDung")
        .doc(senderUid)
        .collection("sent_requests")
        .doc(currentUid)
        .delete();
  }

  Future<void> cancelRequest(String targetUid) async {

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("sent_requests")
        .doc(targetUid)
        .delete();

    await firestore
        .collection("NguoiDung")
        .doc(targetUid)
        .collection("received_requests")
        .doc(currentUid)
        .delete();
  }
  Future<void> removeFriend(String friendUid) async {

    await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("friends")
        .doc(friendUid)
        .delete();

    await firestore
        .collection("NguoiDung")
        .doc(friendUid)
        .collection("friends")
        .doc(currentUid)
        .delete();
  }
}