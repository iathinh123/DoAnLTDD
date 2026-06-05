import 'package:flutter/material.dart';
import 'package:doanltdd/Controllers/friend_controller.dart';
import 'friend_tab.dart';
import 'all_user_tab.dart';

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FriendController controller = FriendController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  // Đừng quên giải phóng TabController để tối ưu hiệu năng và tránh rò rỉ bộ nhớ
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Nền tối sâu đồng bộ sang trọng

      appBar: AppBar(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white), // Giúp nút Back có màu trắng rõ ràng
        title: const Text(
          "Kết nối bạn bè",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),

        // Cải tiến cấu trúc thanh TabBar FinTech hiện đại hơn
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.green, // Thanh gạch chân màu xanh lá chủ đạo
          indicatorWeight: 3, // Thanh gạch chân dày dặn, sắc nét hơn
          labelColor: Colors.green, // Màu icon và chữ khi được chọn
          unselectedLabelColor: Colors.grey[500], // Màu icon và chữ khi chưa chọn
          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), // Chữ in đậm khi được chọn
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.normal, fontSize: 14),
          tabs: const [
            Tab(
              icon: Icon(Icons.person_add_alt_1_rounded), // Đổi sang icon bo tròn mịn hơn
              text: "Khám phá", // Thay chữ "Thêm bạn" thành "Khám phá" nghe tinh tế hơn
            ),
            Tab(
              icon: Icon(Icons.people_alt_rounded), // Đổi sang icon nhóm người bo tròn hiện đại
              text: "Danh sách", // Thay chữ "Bạn bè" thành "Danh sách" để ngắn gọn, cân xứng UI
            ),
          ],
        ),
      ),

      body: TabBarView(
        controller: _tabController,
        children: [
          /// TAB THÊM BẠN (Khám phá toàn bộ người dùng)
          AllUsersTab(controller),

          /// TAB BẠN BÈ (Danh sách bạn bè đã kết bạn)
          FriendsTab(controller),
        ],
      ),
    );
  }
}