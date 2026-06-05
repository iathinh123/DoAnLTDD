import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Controllers/group_jar_controller.dart';

class GroupJarMembersScreen extends StatefulWidget {
  final String jarId;
  const GroupJarMembersScreen({
    super.key,
    required this.jarId,
  });
  @override
  State<GroupJarMembersScreen> createState() => _GroupJarMembersScreenState();
}

class _GroupJarMembersScreenState extends State<GroupJarMembersScreen> {
  final GroupJarController controller = GroupJarController();
  bool isCreator = false;

  @override
  void initState() {
    super.initState();
    checkCreator();
  }

  Future<void> checkCreator() async {
    final doc = await FirebaseFirestore.instance
        .collection("group_jars")
        .doc(widget.jarId)
        .get();
    if (!mounted) return;
    setState(() {
      isCreator = doc["createdBy"] == controller.currentUid;
    });
  }

  Future<void> showAddMemberDialog() async {
    final friends = await controller.getFriendsList();
    final memberSnapshot = await FirebaseFirestore.instance
        .collection("group_jars")
        .doc(widget.jarId)
        .collection("members")
        .get();
    final memberIds = memberSnapshot.docs.map((e) => e.id).toSet();
    final availableFriends = friends.where((friend) {
      if (memberIds.contains(friend.uid)) return false;
      if (friend.uid == controller.currentUid) return false;
      return true;
    }).toList();

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E), // Đồng bộ nền tối cho Dialog
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Thêm thành viên",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: availableFriends.isEmpty
                ? Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                "Không còn bạn bè để thêm",
                style: TextStyle(color: Colors.grey, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.builder(
              shrinkWrap: true,
              itemCount: availableFriends.length,
              itemBuilder: (context, index) {
                final friend = availableFriends[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2C2C2E),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[700],
                      backgroundImage: friend.avatarUrl.isNotEmpty ? NetworkImage(friend.avatarUrl) : null,
                      child: friend.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                    ),
                    title: Text(friend.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14.5)),
                    subtitle: Text(friend.email, style: TextStyle(color: Colors.grey[400], fontSize: 12)),
                    trailing: const Icon(Icons.add_circle, color: Colors.green, size: 22),
                    onTap: () async {
                      await controller.addMember(
                        jarId: widget.jarId,
                        friend: friend,
                      );
                      if (mounted) Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền tối sâu đồng bộ sang trọng
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          "Thành viên nhóm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
        ),
      ),

      floatingActionButton: isCreator
          ? FloatingActionButton(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc FAB hiện đại
        onPressed: showAddMemberDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      )
          : null,

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection("group_jars")
            .doc(widget.jarId)
            .collection("members")
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          final members = snapshot.data!.docs;

          if (members.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có thành viên nào",
                    style: TextStyle(color: Colors.grey, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: members.length,
            itemBuilder: (context, index) {
              final doc = members[index];
              final member = doc.data() as Map<String, dynamic>;
              final isOwner = doc.id == controller.currentUid;

              return Container(
                margin: const EdgeInsets.symmetric(vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E), // Màu card xám tối nhẹ
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  leading: CircleAvatar(
                    backgroundColor: Colors.grey[800],
                    backgroundImage: member["avatarUrl"] != null && member["avatarUrl"].toString().isNotEmpty
                        ? NetworkImage(member["avatarUrl"])
                        : null,
                    child: member["avatarUrl"] == null || member["avatarUrl"].toString().isEmpty
                        ? const Icon(Icons.person, color: Colors.white)
                        : null,
                  ),
                  title: Row(
                    children: [
                      Text(
                        member["name"] ?? "",
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      if (isOwner) ...[
                        const SizedBox(width: 8),
                        // Badge đánh dấu là "Bạn" (Chủ tài khoản đang xem)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Bạn",
                            style: TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ],
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 4.0),
                    child: Text(
                      member["email"] ?? "",
                      style: TextStyle(color: Colors.grey[500], fontSize: 13),
                    ),
                  ),
                  trailing: isCreator && !isOwner
                      ? PopupMenuButton<String>(
                    color: const Color(0xFF2C2C2E), // Đổi nền menu popup sang xám đậm thay vì trắng mặc định
                    icon: Icon(Icons.more_vert_rounded, color: Colors.grey[400]),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                        value: "remove",
                        child: Row(
                          children: [
                            Icon(Icons.person_remove_outlined, color: Colors.redAccent, size: 18),
                            SizedBox(width: 8),
                            Text(
                              "Xóa khỏi hũ",
                              style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                    ],
                    onSelected: (value) async {
                      if (value == "remove") {
                        await controller.removeMember(
                          jarId: widget.jarId,
                          memberUid: doc.id,
                        );
                      }
                    },
                  )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}