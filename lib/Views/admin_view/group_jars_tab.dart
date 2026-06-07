import 'package:flutter/material.dart';
import '../../Controllers/admin_controller.dart';
import '../../models/for_group_jar/group_jar_model.dart';

class TabGroupJars extends StatefulWidget {
  const TabGroupJars({super.key});

  @override
  State<TabGroupJars> createState() => _TabGroupJarsState();
}

class _TabGroupJarsState extends State<TabGroupJars> {
  final AdminController _adminController = AdminController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<GroupJarModel>>(
      stream: _adminController.streamAllGroupJars(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2DB15D)));
        }
        if (snapshot.hasError) {
          return Center(child: Text("Lỗi: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text("Hệ thống chưa có hũ nhóm nào được tạo.", style: TextStyle(color: Colors.grey)));
        }

        final jars = snapshot.data!;
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: jars.length,
          itemBuilder: (context, index) {
            final jar = jars[index];
            double progress = jar.target > 0 ? (jar.currentAmount / jar.target).clamp(0.0, 1.0) : 0.0;
            int percent = (progress * 100).toInt();

            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(15),
                border: Border.all(color: jar.isCompleted ? const Color(0xFF2DB15D).withValues(alpha: 0.4) : Colors.transparent),
              ),
              child: InkWell(
                borderRadius: BorderRadius.circular(15),
                onTap: () => _showJarDetailsBottomSheet(jar),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                const Icon(Icons.savings_rounded, color: Color(0xFF2DB15D), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    jar.name,
                                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: jar.isCompleted ? Colors.green.withValues(alpha: 0.2) : Colors.amber.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              jar.isCompleted ? "Hoàn thành" : "Đang tích lũy",
                              style: TextStyle(
                                color: jar.isCompleted ? Colors.greenAccent : Colors.amberAccent,
                                fontSize: 11, fontWeight: FontWeight.bold,
                              ),
                            ),
                          )
                        ],
                      ),
                      if (jar.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(jar.description, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      const SizedBox(height: 15),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("Đã tích: ${jar.currentAmount.toStringAsFixed(0)}đ", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                          Text("Mục tiêu: ${jar.target.toStringAsFixed(0)}đ", style: const TextStyle(color: Colors.grey, fontSize: 13)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Colors.grey[800],
                          color: jar.isCompleted ? const Color(0xFF2DB15D) : Colors.blueAccent,
                          minHeight: 8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text("Tiến độ: $percent%", style: TextStyle(color: jar.isCompleted ? const Color(0xFF2DB15D) : Colors.blueAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      )
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showJarDetailsBottomSheet(GroupJarModel jar) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.65,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 45, height: 5, margin: const EdgeInsets.only(bottom: 15), decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))),
              ),
              Text(jar.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              FutureBuilder<String>(
                future: _adminController.getUserNameByUid(jar.createdBy),
                builder: (context, res) {
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(10)),
                    child: Row(
                      children: [
                        const Icon(Icons.gite_rounded, color: Colors.amber, size: 22),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("Người tạo hũ (Chủ trì)", style: TextStyle(color: Colors.white38, fontSize: 11)),
                            Text(res.data ?? "Đang tải...", style: const TextStyle(color: Colors.amberAccent, fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        )
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 15),
              const Text("Danh sách thành viên tham gia:", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Expanded(
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: _adminController.getJarMembers(jar.id),
                  builder: (context, snap) {
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF2DB15D)));
                    }
                    final members = snap.data ?? [];
                    if (members.isEmpty) {
                      return const Center(child: Text("Hũ nhóm này không có thành viên.", style: TextStyle(color: Colors.white30)));
                    }
                    return ListView.builder(
                      itemCount: members.length,
                      itemBuilder: (context, mIdx) {
                        final m = members[mIdx];
                        String name = m['name'] ?? 'Không tên';
                        String email = m['email'] ?? '';
                        String avatar = m['avatarUrl'] ?? '';

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor: Colors.grey[700],
                                backgroundImage: avatar.isNotEmpty ? NetworkImage(avatar) : null,
                                child: avatar.isEmpty ? const Icon(Icons.person, size: 16, color: Colors.white) : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                                    if (email.isNotEmpty) Text(email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                                  ],
                                ),
                              ),
                              if (m['uid'] == jar.createdBy)
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 18)
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              )
            ],
          ),
        );
      },
    );
  }
}