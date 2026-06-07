import 'package:flutter/material.dart';
import '../../Controllers/admin_controller.dart';

class TabCreateAccount extends StatefulWidget {
  const TabCreateAccount({super.key});

  @override
  State<TabCreateAccount> createState() => _TabCreateAccountState();
}

class _TabCreateAccountState extends State<TabCreateAccount> {
  final AdminController _adminController = AdminController();

  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _isLoading = false;

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.redAccent : Colors.green,
    ));
  }

  void _onSubmit() async {
    if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
      _showSnackBar("Vui lòng điền đầy đủ thông tin.", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    String? error = await _adminController.createAccountWithRole(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passCtrl.text.trim(),
      role: _selectedRole,
    );

    setState(() => _isLoading = false);

    if (error == null) {
      _showSnackBar("Tạo tài khoản thành công!");
      _nameCtrl.clear();
      _emailCtrl.clear();
      _passCtrl.clear();
    } else {
      _showSnackBar("Lỗi: $error", isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Đăng Ký Tài Khoản Cho Hệ Thống", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5),
          const Text("Admin có quyền cấp tài khoản trực tiếp làm Quản trị viên hoặc Người dùng thường.", style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 20),
          _buildInputBox(controller: _nameCtrl, hintText: "Họ và tên", icon: Icons.person_outline),
          const SizedBox(height: 15),
          _buildInputBox(controller: _emailCtrl, hintText: "Email đăng nhập", icon: Icons.email_outlined),
          const SizedBox(height: 15),
          _buildInputBox(controller: _passCtrl, hintText: "Mật khẩu hệ thống", icon: Icons.lock_outline, isSecure: true),
          const SizedBox(height: 20),
          const Text("Phân quyền tài khoản:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("User thường", style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: 'user',
                  groupValue: _selectedRole,
                  activeColor: const Color(0xFF2DB15D),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
              ),
              Expanded(
                child: RadioListTile<String>(
                  title: const Text("Quản trị Admin", style: TextStyle(color: Colors.white, fontSize: 14)),
                  value: 'admin',
                  groupValue: _selectedRole,
                  activeColor: const Color(0xFF2DB15D),
                  onChanged: (val) => setState(() => _selectedRole = val!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2DB15D),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
              ),
              onPressed: _isLoading ? null : _onSubmit,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("TẠO TÀI KHOẢN", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInputBox({required TextEditingController controller, required String hintText, required IconData icon, bool isSecure = false}) {
    return Container(
      decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10)),
      child: TextField(
        controller: controller,
        obscureText: isSecure,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF2DB15D)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
        ),
      ),
    );
  }
}