import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Controllers/friend_controller.dart';

class AllUsersTab extends StatelessWidget {
  final FriendController controller;

  const AllUsersTab(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("NguoiDung")
          .doc(controller.currentUid)
          .collection("received_requests")
          .snapshots(),
      builder: (context, requestSnapshot) {
        if (!requestSnapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final receivedRequests =
            requestSnapshot.data!.docs;

        final receivedIds =
        receivedRequests.map((e) => e.id).toSet();

        return StreamBuilder<QuerySnapshot>(
          stream: controller.getAllUsers(),
          builder: (context, userSnapshot) {
            if (!userSnapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(),
              );
            }

            final allUsers =
                userSnapshot.data!.docs;

            return Column(
              children: [
                if (receivedRequests.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.mail,
                          color: Colors.orange,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Lời mời kết bạn",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight:
                            FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (receivedRequests.isNotEmpty)
                  SizedBox(
                    height: receivedRequests.length * 90,
                    child: ListView.builder(
                      physics:
                      const NeverScrollableScrollPhysics(),
                      itemCount:
                      receivedRequests.length,
                      itemBuilder: (context, index) {

                        final senderUid =
                            receivedRequests[index].id;

                        final sender =
                        receivedRequests[index]
                            .data()
                        as Map<String, dynamic>;

                        return Card(
                          color:
                          Theme.of(context).cardColor,
                          margin:
                          const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundImage:
                              sender["avatarUrl"] !=
                                  null &&
                                  sender[
                                  "avatarUrl"] !=
                                      "" &&
                                  sender[
                                  "avatarUrl"] !=
                                      "URL"
                                  ? NetworkImage(
                                sender[
                                "avatarUrl"],
                              )
                                  : null,
                              child: sender[
                              "avatarUrl"] ==
                                  null ||
                                  sender[
                                  "avatarUrl"] ==
                                      "" ||
                                  sender[
                                  "avatarUrl"] ==
                                      "URL"
                                  ? const Icon(
                                  Icons.person)
                                  : null,
                            ),
                            title: Text(
                              sender["name"] ?? "",
                              style:
                              TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight:
                                FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              sender["email"] ?? "",
                              style:
                              const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize:
                              MainAxisSize.min,
                              children: [

                                IconButton(
                                  icon: const Icon(
                                    Icons
                                        .check_circle,
                                    color:
                                    Colors.green,
                                  ),
                                  onPressed:
                                      () async {

                                    final currentUser =
                                    await FirebaseFirestore
                                        .instance
                                        .collection(
                                        "NguoiDung")
                                        .doc(controller
                                        .currentUid)
                                        .get();

                                    await controller
                                        .acceptRequest(
                                      senderUid,
                                      sender,
                                      currentUser
                                          .data()!,
                                    );
                                  },
                                ),

                                IconButton(
                                  icon: const Icon(
                                    Icons.cancel,
                                    color: Colors.red,
                                  ),
                                  onPressed:
                                      () async {

                                    await controller
                                        .rejectRequest(
                                      senderUid,
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                    Divider(
                  color: Theme.of(context).dividerColor,
                  height: 1,
                ),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        Icons.people_alt,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8),
                      Text(
                        "Người dùng",
                        style: TextStyle(
                          color: Theme.of(context).textTheme.bodyMedium?.color,
                          fontSize: 18,
                          fontWeight:
                          FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot>(
                    stream: FirebaseFirestore
                        .instance
                        .collection(
                        "NguoiDung")
                        .doc(controller
                        .currentUid)
                        .collection("friends")
                        .snapshots(),
                    builder:
                        (context, friendSnapshot) {

                      if (!friendSnapshot
                          .hasData) {
                        return const Center(
                          child:
                          CircularProgressIndicator(),
                        );
                      }

                      final friendIds =
                      friendSnapshot
                          .data!.docs
                          .map(
                              (e) => e.id)
                          .toSet();

                      final users =
                      allUsers.where((doc) {

                        if (doc.id ==
                            controller
                                .currentUid) {
                          return false;
                        }
                        if (friendIds
                            .contains(
                            doc.id)) {
                          return false;
                        }

                        if (receivedIds
                            .contains(
                            doc.id)) {
                          return false;
                        }

                        return true;

                      }).toList();

                      return ListView.builder(
                        itemCount:
                        users.length,
                        itemBuilder:
                            (context,
                            index) {

                          final user =
                          users[index]
                              .data()
                          as Map<String,
                              dynamic>;

                          final targetUid =
                              users[index]
                                  .id;

                          return StreamBuilder<
                              DocumentSnapshot>(
                            stream: FirebaseFirestore
                                .instance
                                .collection(
                                "NguoiDung")
                                .doc(controller
                                .currentUid)
                                .collection(
                                "sent_requests")
                                .doc(
                                targetUid)
                                .snapshots(),
                            builder:
                                (context,
                                sentSnapshot) {

                              final bool
                              isSent =
                                  sentSnapshot
                                      .data
                                      ?.exists ??
                                      false;

                              return Card(
                                color:
                                const Color(
                                    0xFF1E1E1E),
                                margin:
                                const EdgeInsets
                                    .symmetric(
                                  horizontal:
                                  10,
                                  vertical: 4,
                                ),
                                child:
                                ListTile(
                                  leading:
                                  CircleAvatar(
                                    backgroundImage: user["avatarUrl"] != null &&
                                        user["avatarUrl"] !=
                                            "" &&
                                        user["avatarUrl"] !=
                                            "URL"
                                        ? NetworkImage(
                                        user["avatarUrl"])
                                        : null,
                                    child: user["avatarUrl"] ==
                                        null ||
                                        user["avatarUrl"] ==
                                            "" ||
                                        user["avatarUrl"] ==
                                            "URL"
                                        ? const Icon(
                                        Icons
                                            .person)
                                        : null,
                                  ),
                                  title: Text(
                                    user["name"] ??
                                        "",
                                    style:
                                    const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle:
                                  Text(
                                    user["email"] ??
                                        "",
                                    style:
                                    const TextStyle(
                                      color: Colors.grey,
                                    ),
                                  ),
                                  trailing:
                                  ElevatedButton(
                                    style:
                                    ElevatedButton.styleFrom(
                                      backgroundColor:
                                      isSent
                                          ? Colors.red
                                          : Colors.green,
                                    ),
                                    onPressed:
                                        () async {

                                      if (isSent) {

                                        await controller
                                            .cancelRequest(
                                          targetUid,
                                        );

                                      } else {

                                        await controller
                                            .sendRequest(
                                          targetUid,
                                        );
                                      }
                                    },
                                    child:
                                    Text(
                                      isSent
                                          ? "Hủy"
                                          : "Thêm",
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}