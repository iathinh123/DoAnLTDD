import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'currency_screen.dart';
import 'login_screen.dart';
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          // AppBar dạng hiệu ứng kéo giãn
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text("Tài khoản",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
              centerTitle: true,
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              children: [
                // --- CARD THÔNG TIN CÁ NHÂN ---
                _buildProfileCard(user),

                const SizedBox(height: 25),

                // --- NHÓM CÀI ĐẶT 1: HỆ THỐNG ---
                _buildSectionHeader("Cài đặt ứng dụng"),
                _buildSettingsGroup([
                  _buildSettingTile(
                      icon: Icons.language,
                      title: "Ngôn ngữ",
                      trailing: "Tiếng Việt",
                      color: Colors.blueAccent,
                      onTap: () {}
                  ),
                  _buildSettingTile(
                      icon: Icons.currency_exchange,
                      title: "Tiền tệ",
                      trailing: "VND",
                      color: Colors.orangeAccent,
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => CurrencyScreen()));
                      }
                  ),
                ]),

                const SizedBox(height: 20),

                // --- NHÓM CÀI ĐẶT 2: BẢO MẬT & HỖ TRỢ ---
                _buildSectionHeader("Hỗ trợ & Bảo mật"),
                _buildSettingsGroup([
                  _buildSettingTile(
                      icon: Icons.lock_person_outlined,
                      title: "Bảo mật tài khoản",
                      color: Colors.greenAccent,
                      onTap: () {}
                  ),
                  _buildSettingTile(
                      icon: Icons.help_outline_rounded,
                      title: "Trung tâm trợ giúp",
                      color: Colors.purpleAccent,
                      onTap: () {}
                  ),
                  _buildSettingTile(
                      icon: Icons.info_outline,
                      title: "Phiên bản",
                      trailing: "2.4.1",
                      color: Colors.grey,
                      onTap: () {}
                  ),
                ]),

                const SizedBox(height: 35),

                // --- NÚT ĐĂNG XUẤT ---
                _buildLogoutButton(context),

                const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }

  // Widget hiển thị thông tin User theo dạng Card
  Widget _buildProfileCard(User? user) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.grey[900]!, Colors.black],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
        boxShadow: [BoxShadow(color: Colors.green.withOpacity(0.05), blurRadius: 10, spreadRadius: 5)],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 35,
            backgroundColor: Colors.green.withOpacity(0.2),
            child: const Icon(Icons.person, size: 40, color: Colors.green),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user?.displayName ?? "Chưa đặt tên",
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 5),
                Text(user?.email ?? "No Email",
                    style: TextStyle(color: Colors.grey[400], fontSize: 13)),
              ],
            ),
          ),
          const Icon(Icons.verified_user, color: Colors.blue, size: 20),
        ],
      ),
    );
  }

  // Widget tiêu đề nhóm
  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 25, bottom: 10),
      child: Text(title, style: const TextStyle(color: Colors.green, fontSize: 14, fontWeight: FontWeight.w600)),
    );
  }

  // Widget gom nhóm các nút cài đặt
  Widget _buildSettingsGroup(List<Widget> tiles) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(children: tiles),
    );
  }

  // Widget từng dòng cài đặt
  Widget _buildSettingTile({required IconData icon, required String title, String? trailing, required Color color, required VoidCallback onTap}) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null) Text(trailing, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios, color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  // Widget nút Đăng xuất hiện đại
  Widget _buildLogoutButton(BuildContext context) {
    return TextButton(
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen()),
              (route) => false,
        );
      },
      child: const Text("Đăng xuất tài khoản",
          style: TextStyle(color: Colors.redAccent, fontSize: 16, fontWeight: FontWeight.w500)),
    );
  }
}