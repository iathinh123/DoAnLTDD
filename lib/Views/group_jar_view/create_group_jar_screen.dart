import 'package:flutter/material.dart';
import '../../Controllers/group_jar_controller.dart';
import '../../models/friend_model.dart';

class CreateGroupJarScreen extends StatefulWidget {
  const CreateGroupJarScreen({super.key});

  @override
  State<CreateGroupJarScreen> createState() =>
      _CreateGroupJarScreenState();
}

class _CreateGroupJarScreenState
    extends State<CreateGroupJarScreen> {

  final GroupJarController controller =
  GroupJarController();

  final TextEditingController nameController =
  TextEditingController();

  final TextEditingController descriptionController =
  TextEditingController();

  final TextEditingController targetController =
  TextEditingController();

  List<FriendModel> friends = [];

  List<FriendModel> selectedFriends = [];

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadFriends();
  }

  Future<void> loadFriends() async {

    friends =
    await controller.getFriendsList();

    setState(() {
      isLoading = false;
    });
  }

  Future<void> createJar() async {

    if (nameController.text.trim().isEmpty) {
      return;
    }

    if (targetController.text.trim().isEmpty) {
      return;
    }

    await controller.createGroupJar(
      name: nameController.text.trim(),
      description:
      descriptionController.text.trim(),
      target: double.parse(
        targetController.text.trim(),
      ),
      members: selectedFriends,
    );

    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Tạo hũ nhóm",
          style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).textTheme.bodyMedium?.color),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: Theme.of(context).textTheme.bodyMedium?.color),
      ),
      body: isLoading
          ? const Center(
        child: CircularProgressIndicator(color: Colors.green),
      )
          : GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(), // Ẩn bàn phím khi chạm ngoài
        child: Column(
          children: [
            // Phần nhập thông tin hũ (Cho vào cuộn đề phòng màn hình nhỏ)
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ô nhập Tên hũ
                    _buildTextField(
                      controller: nameController,
                      label: "Tên hũ",
                      icon: Icons.drive_file_rename_outline,
                    ),
                    const SizedBox(height: 16),

                    // Ô nhập Mô tả
                    _buildTextField(
                      controller: descriptionController,
                      label: "Mô tả",
                      icon: Icons.description_outlined,
                    ),
                    const SizedBox(height: 16),

                    // Ô nhập Mục tiêu
                    _buildTextField(
                      controller: targetController,
                      label: "Mục tiêu (VNĐ)",
                      icon: Icons.track_changes,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 24),

                    // Tiêu đề danh sách bạn bè
                    const Text(
                      "Chọn thành viên",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Danh sách bạn bè
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: friends.length,
                      itemBuilder: (context, index) {
                        final friend = friends[index];
                        final isSelected = selectedFriends.contains(friend);

                        return Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: CheckboxListTile(
                            value: isSelected,
                            activeColor: Colors.green,
                            checkColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            title: Text(
                              friend.name,
                              style: TextStyle(
                                color: Theme.of(context).textTheme.bodyMedium?.color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            subtitle: Text(
                              friend.email,
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                            onChanged: (value) {
                              setState(() {
                                if (isSelected) {
                                  selectedFriends.remove(friend);
                                } else {
                                  selectedFriends.add(friend);
                                }
                              });
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),

            // Nút TẠO HŨ cố định ở dưới cùng màn hình
            Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 24, top: 8),
              child: SizedBox(
                width: double.infinity,
                height: 52, // Tăng chiều cao nút cho dễ bấm
                child: ElevatedButton(
                  onPressed: createJar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green, // Đổi sang MÀU XANH LÁ theo yêu cầu
                    foregroundColor: Colors.white, // Màu chữ trắng
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12), // Bo góc hiện đại hơn
                    ),
                  ),
                  child: const Text(
                    "TẠO HŨ",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIcon: Icon(icon, color: Colors.green),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.grey, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.green, width: 1.5),
        ),
        filled: true,
        fillColor: Theme.of(context).cardColor,
      ),
    );
  }
}