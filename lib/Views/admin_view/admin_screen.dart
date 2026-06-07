import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../Controllers/admin_controller.dart';
import '../login_screen.dart';
import 'user_management_tab.dart';
import 'group_jars_tab.dart';
import 'create_acount_tab.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final AdminController _adminController = AdminController();

  void _handleLogout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: const Color(0xFF121212),
        appBar: AppBar(
          backgroundColor: const Color(0xFF1E1E1E),
          elevation: 0,
          title: const Text(
            "HỆ THỐNG QUẢN TRỊ (ADMIN)",
            style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 1.1
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
              tooltip: "Đăng xuất",
              onPressed: _handleLogout,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Color(0xFF2DB15D),
            labelColor: Color(0xFF2DB15D),
            unselectedLabelColor: Colors.grey,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.people_alt_rounded), text: "Quản Lý Users"),
              Tab(icon: Icon(Icons.group_work_rounded), text: "Hũ Nhóm"),
              Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: "Tạo Tài Khoản"),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            TabUsersManagement(),
            TabGroupJars(),
            TabCreateAccount(),
          ],
        ),
      ),
    );
  }
}