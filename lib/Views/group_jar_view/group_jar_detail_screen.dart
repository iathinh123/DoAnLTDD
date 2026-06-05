import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../Controllers/group_jar_controller.dart';
import 'member_screen.dart';

//ĐỊNH DẠNG GIỜ
String _formatTimestamp(dynamic createdAt) {
  if (createdAt == null) return "";
  DateTime dateTime;
  if (createdAt is Timestamp) {
    dateTime = createdAt.toDate();
  } else if (createdAt is int) {
    dateTime = DateTime.fromMillisecondsSinceEpoch(createdAt);
  } else {
    return "";
  }
  final hour = dateTime.hour.toString().padLeft(2, '0');
  final minute = dateTime.minute.toString().padLeft(2, '0');

  return "$hour:$minute";
}

class GroupJarDetailScreen extends StatefulWidget {
  final String jarId;
  const GroupJarDetailScreen({
    super.key,
    required this.jarId,
  });

  @override
  State<GroupJarDetailScreen> createState() => _GroupJarDetailScreenState();
}

class _GroupJarDetailScreenState extends State<GroupJarDetailScreen> {
  final GroupJarController controller = GroupJarController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  //TỰ ĐỘNG CUỘN KHI CÓ HOẠT ĐỘNG
  void _scrollToBottom() {
    // Đợi giao diện vẽ xong dữ liệu mới rồi mới cuộn
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
  @override
  void dispose() {
    _scrollController.dispose(); // Hủy controller để tránh rò rỉ bộ nhớ (Memory Leak)
    amountController.dispose();
    messageController.dispose();
    super.dispose();
  }
  Future<void> showContributionDialog() async {
    await showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E1E1E),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16)),
          title: const Text(
            "Nạp tiền vào hũ",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: "Nhập số tiền (VNĐ)",
              hintStyle: const TextStyle(color: Colors.grey),
              prefixIcon: const Icon(Icons.attach_money, color: Colors.green),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.grey, width: 0.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.green, width: 1.5),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text) ?? 0;
                if (amount <= 0) return;
                await controller.contribute(
                  jarId: widget.jarId,
                  amount: amount,
                );
                amountController.clear();
                if (mounted) Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text("Xác nhận"),
            ),
          ],
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền tối sâu hơn
      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        title: const Text(
          "Chi tiết hũ nhóm",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.people_alt_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupJarMembersScreen(jarId: widget.jarId),
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("group_jars")
            .doc(widget.jarId)
            .snapshots(),
        builder: (context, jarSnapshot) {
          if (!jarSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }
          final jarData = jarSnapshot.data!.data() as Map<String, dynamic>;
          final currentAmount = (jarData["currentAmount"] ?? 0).toDouble();
          final target = (jarData["target"] ?? 1).toDouble();
          final progress = currentAmount / target;
          final completed = jarData["isCompleted"] ?? false;
          final percentText = "${(progress * 100).toStringAsFixed(0)}%";
          return Column(
            children: [
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: Colors.black, blurRadius: 8, offset: const Offset(0, 4))
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children:[
                        Expanded(
                          child: Text(
                            jarData["name"] ?? "",
                            style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            percentText,
                            style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      jarData["description"] ?? "Không có mô tả",
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: progress > 1 ? 1 : progress,
                        backgroundColor: Colors.grey[800],
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.green),
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "${currentAmount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Text(
                          "Mục tiêu: ${target.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')} đ",
                          style: const TextStyle(color: Colors.grey, fontSize: 13),
                        ),
                      ],
                    ),
                    if (completed) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: const [
                          Icon(Icons.stars, color: Colors.green, size: 18),
                          SizedBox(width: 6),
                          Text(
                            "Hũ đã hoàn thành mục tiêu!",
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        onPressed: showContributionDialog,
                        icon: const Icon(Icons.add_circle_outline),
                        label: const Text("NẠP TIỀN VÀO HŨ", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green, // Đổi nút thành màu xanh lá
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Text("Lịch sử hoạt động", style: TextStyle(color: Colors.grey, fontSize: 13, fontWeight: FontWeight.bold)),
                    Spacer(),
                  ],
                ),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: controller.getActivities(widget.jarId),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox();
                    final docs = snapshot.data!.docs;
                    _scrollToBottom();
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (context, index) {
                        final data = docs[index].data() as Map<String, dynamic>;
                        final isMe = data["senderId"] == controller.currentUid;

                        if (data["type"] == "contribution") {
                          final timestamp = data["createdAt"];
                          final timeStr = _formatTimestamp(timestamp);
                          final amount = (data["amount"] ?? 0).toDouble();

                          return Center(
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                              padding: const EdgeInsets.all(12),
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: Colors.green.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Icon giao dịch thành công bọc vòng tròn
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.account_balance_wallet_rounded,
                                      color: Colors.green,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Nội dung thông báo
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          data["text"] ?? "Có thành viên vừa nạp tiền",
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                        if (timeStr.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.access_time_rounded,
                                                color: Colors.grey[500],
                                                size: 12,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                timeStr,
                                                style: TextStyle(
                                                  color: Colors.grey[500],
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  Text(
                                    "+${amount.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}đ",
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            constraints: const BoxConstraints(maxWidth: 280),
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isMe ? Colors.green : const Color(0xFF1E1E1E), // Đồng bộ màu chat của mình là xanh lá
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isMe ? 16 : 4),
                                bottomRight: Radius.circular(isMe ? 4 : 16),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMe) ...[
                                  Text(
                                    data["senderName"] ?? "Thành viên",
                                    style: const TextStyle(color: Colors.green, fontSize: 11, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  data["text"] ?? "",
                                  style: const TextStyle(color: Colors.white, fontSize: 14.5),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.only(left: 8, right: 8, top: 8, bottom: 20), // Thừa khoảng trống cho tai thỏ/đáy màn hình vuốt
                color: const Color(0xFF1E1E1E),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.add_box_rounded, color: Colors.green, size: 28),
                      onPressed: showContributionDialog,
                    ),
                    Expanded(
                      child: TextField(
                        controller: messageController,
                        style: const TextStyle(
                          color: Colors.white,
                        ),
                        decoration: InputDecoration(
                          hintText: "Nhập tin nhắn...",
                          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          filled: true,
                          fillColor: const Color(0xFF2C2C2E),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.green, size: 26),
                      onPressed: () async {
                        if (messageController.text.trim().isEmpty) return;
                        await controller.sendMessage(
                          jarId: widget.jarId,
                          message: messageController.text.trim(),
                        );
                        messageController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
