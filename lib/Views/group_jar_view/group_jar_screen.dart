import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../Controllers/group_jar_controller.dart';
import 'create_group_jar_screen.dart';
import 'group_jar_detail_screen.dart';

class GroupJarScreen extends StatefulWidget {
  const GroupJarScreen({super.key});

  @override
  State<GroupJarScreen> createState() => _GroupJarScreenState();
}

class _GroupJarScreenState extends State<GroupJarScreen> {
  final GroupJarController controller = GroupJarController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(

      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          "Hũ nhóm của tôi",
          style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontWeight: FontWeight.bold, fontSize: 22),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), // Bo góc nút bấm hiện đại
        child: const Icon(Icons.add, color: Colors.white, size: 28),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateGroupJarScreen(),
            ),
          );
        },
      ),

      body: StreamBuilder<List<QueryDocumentSnapshot>>(
        stream: controller.getGroupJars(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.green),
            );
          }

          final jars = snapshot.data!;

          if (jars.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.pie_chart_outline_rounded, size: 64, color: Colors.grey[700]),
                  const SizedBox(height: 16),
                  const Text(
                    "Chưa có hũ nhóm nào",
                    style: TextStyle(color: Colors.grey, fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
            itemCount: jars.length,
            itemBuilder: (context, index) {
              final jar = jars[index];
              final data = jar.data() as Map<String, dynamic>;

              final currentAmount = (data["currentAmount"] ?? 0).toDouble();
              final target = (data["target"] ?? 1).toDouble();
              final progress = currentAmount / target;

              // Tính toán phần trăm hiển thị nhanh
              final percentText = "${(progress * 100).toStringAsFixed(0)}%";

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection("group_jars")
                    .doc(jar.id)
                    .collection("members")
                    .doc(controller.currentUid)
                    .get(),
                builder: (context, memberSnap) {
                  if (memberSnap.connectionState == ConnectionState.waiting && !memberSnap.hasData) {
                    return const SizedBox();
                  }
                  if (!memberSnap.hasData || !memberSnap.data!.exists) {
                    return const SizedBox();
                  }

                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(16),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => GroupJarDetailScreen(jarId: jar.id),
                          ),
                        );
                      },
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              data["name"] ?? "",
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                          // Badge hiển thị phần trăm tiến độ cực đẹp
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              percentText,
                              style: const TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (data["description"] != null && data["description"].toString().isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              data["description"],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: Colors.grey[500], fontSize: 13),
                            ),
                          ],
                          const SizedBox(height: 14),

                          // Thanh tiến độ đồng bộ MÀU XANH LÁ bo góc mịn
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress > 1 ? 1 : progress,
                              backgroundColor: Theme.of(context).dividerColor.withOpacity(0.3),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Hiển thị số tiền dạng có dấu chấm phân tách (Ví dụ: 50.000 đ)
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(fontSize: 13.5),
                              children: [
                                TextSpan(
                                  text: "${currentAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ",
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                                ),
                                TextSpan(
                                  text: " / ${target.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ",
                                  style: TextStyle(color: Colors.grey[500]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      trailing: PopupMenuButton<String>(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        icon: Icon(Icons.more_vert_rounded, color: Theme.of(context).textTheme.bodySmall?.color),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        itemBuilder: (context) {
                          return [
                            const PopupMenuItem(
                              value: "delete",
                              child: Row(
                                children: [
                                  Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 20),
                                  SizedBox(width: 8),
                                  Text(
                                    "Hủy hũ",
                                    style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                            ),
                          ];
                        },
                        onSelected: (value) async {
                          if (value == "delete") {
                            await controller.deleteGroupJar(jar.id);
                          }
                        },
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}