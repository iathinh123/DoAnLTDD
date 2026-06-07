import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Controllers/friend_controller.dart';

class FriendsTab extends StatelessWidget {
  final FriendController controller;

  const FriendsTab(this.controller, {super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: controller.getFriends(),
      builder: (context, snapshot) {

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final friends = snapshot.data!.docs;

        if (friends.isEmpty) {
          return Center(
            child: Text(
              "Chưa có bạn bè",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color),
            ),
          );
        }

        return ListView.builder(
          itemCount: friends.length,
          itemBuilder: (context, index) {

            final friend = friends[index].data() as Map<String, dynamic>;
            final friendUid = friends[index].id;
            return Card(
              color: Theme.of(context).cardColor,
              margin: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundImage:
                  friend["avatarUrl"] != null &&
                      friend["avatarUrl"] != "" &&
                      friend["avatarUrl"] != "URL"
                      ? NetworkImage(friend["avatarUrl"])
                      : null,
                  child: friend["avatarUrl"] == null ||
                      friend["avatarUrl"] == "" ||
                      friend["avatarUrl"] == "URL"
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(
                  friend["name"] ?? "",
                  style: const TextStyle(
                    color: Colors.white,
                  ),
                ),
                subtitle: Text(
                  friend["email"] ?? "",
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                trailing: IconButton(
                  icon: const Icon(
                    Icons.person_remove,
                    color: Colors.red,
                  ),
                  onPressed: () async {

                    final confirm =
                    await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Hủy kết bạn"),
                        content: Text(
                          "Bạn có muốn hủy kết bạn với ${friend["name"]} không?",
                        ),
                        actions: [

                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, false),
                            child: const Text("Không"),
                          ),

                          TextButton(
                            onPressed: () =>
                                Navigator.pop(context, true),
                            child: const Text("Có"),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {

                      await controller.removeFriend(
                        friendUid,
                      );

                      if (context.mounted) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Đã hủy kết bạn",
                            ),
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            );
          },
        );
      },
    );
  }
}