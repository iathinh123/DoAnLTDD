import 'package:flutter/material.dart';
import '../../Controllers/admin_controller.dart';
import '../../models/user_model.dart';
import '../../models/transaction_model.dart';

class TabUsersManagement extends StatefulWidget {
  const TabUsersManagement({super.key});

  @override
  State<TabUsersManagement> createState() => _TabUsersManagementState();
}

class _TabUsersManagementState extends State<TabUsersManagement> {
  final AdminController _adminController = AdminController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<UserModel>>(
      stream: _adminController.streamUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFF2DB15D)));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text("Lỗi tải dữ liệu: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(
            child: Text("Không có người dùng nào.", style: TextStyle(color: Colors.grey)),
          );
        }

        final users = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            // Loại bỏ tài khoản Admin khỏi danh sách hoặc không cho phép tự chặn chính mình
            if (user.role == 'admin') return const SizedBox.shrink();

            // Kiểm tra trạng thái hoạt động linh hoạt (qua role hoặc biến isBlocked)
            bool isActive = user.role != 'blocked';

            return Card(
              color: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                onTap: () => _showTransactionsDialog(user),
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[800],
                  backgroundImage: user.avatarUrl.isNotEmpty ? NetworkImage(user.avatarUrl) : null,
                  child: user.avatarUrl.isEmpty ? const Icon(Icons.person, color: Colors.white) : null,
                ),
                title: Text(
                    user.name,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                subtitle: Text(
                    user.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 13)
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isActive ? "Hoạt Động" : "Bị Khóa",
                      style: TextStyle(
                          color: isActive ? Colors.green : Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch(
                      value: isActive,
                      thumbColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green;
                        }
                        return Colors.red;
                      }),
                      trackColor: WidgetStateProperty.resolveWith<Color?>((states) {
                        if (states.contains(WidgetState.selected)) {
                          return Colors.green.withValues(alpha: 0.3);
                        }
                        return Colors.red.withValues(alpha: 0.3);
                      }),
                      onChanged: (value) async {
                        bool shouldBlock = !value;
                        await _adminController.toggleBlockUser(user.uid, shouldBlock);

                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(shouldBlock ? "Đã khóa tài khoản ${user.name}" : "Đã mở khóa tài khoản ${user.name}"),
                              duration: const Duration(seconds: 1),
                              backgroundColor: shouldBlock ? Colors.redAccent : Colors.green,
                            ),
                          );
                        }
                      },
                    )
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // DIALOG XEM LỊCH SỬ GIAO DỊCH CỦA USER THƯỜNG
  void _showTransactionsDialog(UserModel user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E1E1E),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.75,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 40, height: 5,
                    margin: const EdgeInsets.only(bottom: 15),
                    decoration: BoxDecoration(color: Colors.grey[600], borderRadius: BorderRadius.circular(10))
                ),
              ),
              Row(
                children: [
                  CircleAvatar(backgroundColor: Colors.blue.withValues(alpha: 0.2), child: const Icon(Icons.history, color: Colors.blue)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("Lịch sử giao dịch", style: TextStyle(color: Colors.grey, fontSize: 12)),
                        Text(user.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                      ],
                    ),
                  ),
                ],
              ),
              const Padding(padding: EdgeInsets.symmetric(vertical: 10), child: Divider(color: Colors.grey, thickness: 0.5)),
              Expanded(
                child: StreamBuilder<List<TransactionModel>>(
                  stream: _adminController.streamUserTransactions(user.uid),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Colors.green));
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text("Lỗi tải dữ liệu: ${snapshot.error}", style: const TextStyle(color: Colors.redAccent)));
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("Người dùng này chưa có giao dịch nào.", style: TextStyle(color: Colors.grey)));
                    }

                    final transactions = snapshot.data!;
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, idx) {
                        final tx = transactions[idx];
                        Color amountColor = tx.type == 1 ? Colors.greenAccent : (tx.type == 0 ? Colors.redAccent : Colors.amberAccent);
                        String prefix = tx.type == 1 ? "+" : "";
                        IconData typeIcon = tx.type == 1 ? Icons.arrow_downward_rounded : (tx.type == 0 ? Icons.arrow_upward_rounded : Icons.swap_horiz_rounded);
                        String formattedDate = "${tx.date.day.toString().padLeft(2, '0')}/${tx.date.month.toString().padLeft(2, '0')}/${tx.date.year}";

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          decoration: BoxDecoration(color: const Color(0xFF252525), borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: amountColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                              child: Icon(typeIcon, color: amountColor, size: 20),
                            ),
                            title: Text(tx.category, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (tx.note.isNotEmpty) Text(tx.note, style: const TextStyle(color: Colors.grey, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                const SizedBox(height: 2),
                                Text(formattedDate, style: const TextStyle(color: Colors.white38, fontSize: 11)),
                              ],
                            ),
                            trailing: Text("$prefix${tx.amount.toStringAsFixed(0)} đ", style: TextStyle(color: amountColor, fontWeight: FontWeight.bold, fontSize: 15)),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}