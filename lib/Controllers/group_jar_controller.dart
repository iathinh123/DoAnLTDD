import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/friend_model.dart';

class GroupJarController {

  final FirebaseFirestore firestore =
      FirebaseFirestore.instance;

  final String currentUid =
      FirebaseAuth.instance.currentUser!.uid;

  // FRIENDS
  Future<List<FriendModel>> getFriendsList() async {

    final snapshot = await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .collection("friends")
        .get();

    return snapshot.docs.map((doc) {

      final data = doc.data();

      return FriendModel(
        uid: doc.id,
        name: data["name"] ?? "",
        email: data["email"] ?? "",
        avatarUrl: data["avatarUrl"] ?? "",
      );

    }).toList();
  }

  // CREATE GROUP JAR
  Future<void> createGroupJar({
    required String name,
    required String description,
    required double target,
    required List<FriendModel> members,
  }) async {
    final currentUserDoc = await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .get();
    final currentUser =
    currentUserDoc.data()!;
    final jarRef = firestore
        .collection("group_jars")
        .doc();
    await jarRef.set({
      "name": name,
      "description": description,
      "target": target,
      "currentAmount": 0,
      "createdBy": currentUid,
      "isCompleted": false,
      "createdAt":
      FieldValue.serverTimestamp(),
    });
    // creator
    await jarRef
        .collection("members")
        .doc(currentUid)
        .set({
      "uid": currentUid,
      "name": currentUser["name"],
      "email": currentUser["email"],
      "avatarUrl":
      currentUser["avatarUrl"],
    });
    // friends
    for (final friend in members) {

      await jarRef
          .collection("members")
          .doc(friend.uid)
          .set({
        "uid": friend.uid,
        "name": friend.name,
        "email": friend.email,
        "avatarUrl": friend.avatarUrl,
      });
    }
  }

  // MY GROUPS
  Stream<List<QueryDocumentSnapshot>> getGroupJars() {
    return firestore
        .collection("group_jars")
        .snapshots()
        .asyncMap((snapshot) async {

      List<QueryDocumentSnapshot>
      myJars = [];

      for (final jar
      in snapshot.docs) {

        final memberDoc =
        await firestore
            .collection("group_jars")
            .doc(jar.id)
            .collection("members")
            .doc(currentUid)
            .get();

        if (memberDoc.exists) {
          myJars.add(jar);
        }
      }

      return myJars;
    });
  }

  // CONTRIBUTION
  Future<void> contribute({
    required String jarId,
    required double amount,
  }) async {

    final userDoc = await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .get();

    final userData = userDoc.data()!;

    await firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("contributions")
        .add({

      "uid": currentUid,
      "name": userData["name"],
      "amount": amount,
      "createdAt":
      FieldValue.serverTimestamp(),
    });

    final jarDoc = await firestore
        .collection("group_jars")
        .doc(jarId)
        .get();

    final currentAmount =
    (jarDoc["currentAmount"] ?? 0)
        .toDouble();

    final target =
    (jarDoc["target"] ?? 0)
        .toDouble();

    final newAmount =
        currentAmount + amount;

    await firestore
        .collection("group_jars")
        .doc(jarId)
        .update({
      "currentAmount": newAmount,
    });
    await firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("activities")
        .add({

      "type": "contribution",
      "senderId": currentUid,
      "senderName": userData["name"],
      "amount": amount,
      "text":
      "${userData["name"]} đã nạp ${amount.toInt()}đ vào hũ",
      "createdAt":
      FieldValue.serverTimestamp(),
    });
    if (newAmount >= target) {

      await firestore
          .collection("group_jars")
          .doc(jarId)
          .update({
        "isCompleted": true,
      });
    }
  }

  // CHAT
  Stream<QuerySnapshot> getMessages(
      String jarId) {

    return firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("messages")
        .orderBy(
      "createdAt",
      descending: false,
    )
        .snapshots();
  }

  Future<void> sendMessage({
    required String jarId,
    required String message,
  }) async {

    final userDoc = await firestore
        .collection("NguoiDung")
        .doc(currentUid)
        .get();

    final user =
    userDoc.data()!;

    await firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("activities")
        .add({

      "type": "message",
      "senderId": currentUid,
      "senderName": user["name"],
      "text": message,
      "createdAt":
      FieldValue.serverTimestamp(),
    });
  }
  //ACTIVITIES (CONTRIBUTION + CHAT)
  Stream<QuerySnapshot> getActivities(String jarId) {
    return firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("activities")
        .orderBy(
      "createdAt",
      descending: false,
    )
        .snapshots();
  }
  // DELETE GROUP
  Future<void> deleteGroupJar(
      String jarId) async {
    final jarRef = firestore.collection("group_jars").doc(jarId);
    final members = await jarRef.collection("members").get();
    final contributions = await jarRef.collection("contributions").get();
    final messages = await jarRef.collection("messages").get();
    final batch = firestore.batch();
    final activities = await jarRef.collection("activities").get();
    for (final doc
    in members.docs) {
      batch.delete(doc.reference);
    }
    for (final doc
    in contributions.docs) {
      batch.delete(doc.reference);
    }
    for (final doc
    in messages.docs) {
      batch.delete(doc.reference);
    }
    for (final doc
    in activities.docs) {
      batch.delete(doc.reference);
    }
    batch.delete(jarRef);
    await batch.commit();
  }
  //ADD MEMBER
  Future<void> addMember({
    required String jarId,
    required FriendModel friend,
  }) async {

    await firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("members")
        .doc(friend.uid)
        .set({
      "uid": friend.uid,
      "name": friend.name,
      "email": friend.email,
      "avatarUrl": friend.avatarUrl,
    });
  }
  //REMOVE MEMBER
  Future<void> removeMember({
    required String jarId,
    required String memberUid,
  }) async {

    final jarDoc = await firestore
        .collection("group_jars")
        .doc(jarId)
        .get();
    await firestore
        .collection("group_jars")
        .doc(jarId)
        .collection("members")
        .doc(memberUid)
        .delete();
  }
}