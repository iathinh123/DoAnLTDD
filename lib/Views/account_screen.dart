import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Controllers/language_provider.dart';
import 'currency_screen.dart';
import 'login_screen.dart';

typedef _TransFunc = String Function(LanguageProvider, String, String);
typedef _SnackFunc = void Function(BuildContext, LanguageProvider, String, String, {bool isError});

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            backgroundColor: Colors.black,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                _t(lang, "Tài khoản", "Account"),
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20),
              ),
              centerTitle: true,
            ),
          ),
          SliverToBoxAdapter(
            child: Column(
              children: [
                _buildProfileCard(user, lang),
                const SizedBox(height: 25),
                _buildSectionHeader(
                    _t(lang, "Cài đặt ứng dụng", "App Settings")),
                _buildSettingsGroup([
                  _buildSettingTile(
                    icon: Icons.language,
                    title: _t(lang, "Ngôn ngữ", "Language"),
                    trailing: lang.languageCode == "vi" ? "Tiếng Việt" : "English",
                    color: Colors.blueAccent,
                    onTap: () => _showLanguageDialog(context, lang),
                  ),
                  _buildSettingTile(
                    icon: Icons.currency_exchange,
                    title: _t(lang, "Tiền tệ", "Currency"),
                    trailing: "VND",
                    color: Colors.orangeAccent,
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(
                          builder: (context) => CurrencyScreen()));
                    },
                  ),
                ]),
                const SizedBox(height: 20),
                _buildSectionHeader(
                    _t(lang, "Hỗ trợ & Bảo mật", "Support & Security")),
                _buildSettingsGroup([
                  _buildSettingTile(
                    icon: Icons.lock_person_outlined,
                    title: _t(lang, "Bảo mật tài khoản", "Account Security"),
                    color: Colors.greenAccent,
                    onTap: () => _showChangePasswordDialog(context, lang),
                  ),
                  _buildSettingTile(
                    icon: Icons.help_outline_rounded,
                    title: _t(lang, "Trung tâm trợ giúp", "Help Center"),
                    color: Colors.purpleAccent,
                    onTap: () => _showHelpDialog(context, lang),
                  ),
                  _buildSettingTile(
                    icon: Icons.info_outline,
                    title: _t(lang, "Phiên bản", "Version"),
                    trailing: "2.4.1",
                    color: Colors.grey,
                    onTap: () {},
                  ),
                ]),
                const SizedBox(height: 35),
                _buildLogoutButton(context, lang),
                const SizedBox(height: 50),
              ],
            ),
          )
        ],
      ),
    );
  }

  String _t(LanguageProvider lang, String vi, String en) {
    return lang.languageCode == "vi" ? vi : en;
  }

  Widget _buildProfileCard(User? user, LanguageProvider lang) {
    String? photoUrl = user?.photoURL;
    String name = user?.displayName ?? _t(lang, "Chưa đặt tên", "No name");
    String email = user?.email ?? "No Email";

    return GestureDetector(
      onTap: () => _showEditProfileDialog(context, lang),
      child: Container(
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
          boxShadow: [
            BoxShadow(
                color: Colors.green.withOpacity(0.05),
                blurRadius: 10,
                spreadRadius: 5)
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.green.withOpacity(0.1),
                  backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person, size: 40, color: Colors.green)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: const Icon(Icons.edit, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text(email,
                      style:
                          TextStyle(color: Colors.grey[400], fontSize: 13)),
                ],
              ),
            ),
            const Icon(Icons.verified_user, color: Colors.blue, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 25, bottom: 10),
      child: Text(title,
          style: const TextStyle(
              color: Colors.green,
              fontSize: 14,
              fontWeight: FontWeight.w600)),
    );
  }

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

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? trailing,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: color, size: 22),
      ),
      title:
          Text(title, style: const TextStyle(color: Colors.white, fontSize: 15)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (trailing != null)
            Text(trailing,
                style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white24, size: 14),
        ],
      ),
    );
  }

  // ── CHỈNH SỬA PROFILE ──
  void _showEditProfileDialog(BuildContext context, LanguageProvider lang) {
    final user = FirebaseAuth.instance.currentUser;
    _nameController.text = user?.displayName ?? '';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t(lang, "Chỉnh sửa hồ sơ", "Edit Profile"),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: _t(lang, "Họ và tên", "Full name"),
                labelStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.camera_alt, size: 18),
                label: Text(
                    _t(lang, "Đổi ảnh đại diện", "Change Avatar")),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[800],
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
                _t(lang, "Hủy", "Cancel"),
                style: const TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => _saveProfile(ctx, lang),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_t(lang, "Lưu", "Save")),
          ),
        ],
      ),
    );
  }

  Future<void> _saveProfile(BuildContext context, LanguageProvider lang) async {
    final user = FirebaseAuth.instance.currentUser;
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;

    try {
      await user?.updateDisplayName(newName);
      await user?.reload();
      if (context.mounted) {
        Navigator.pop(context);
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _t(lang, "Đã cập nhật hồ sơ!", "Profile updated!")),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("${_t(lang, "Lỗi", "Error")}: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // ── NGÔN NGỮ ──
  void _showLanguageDialog(BuildContext context, LanguageProvider lang) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t(lang, "Chọn ngôn ngữ", "Select Language"),
          style: const TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text("Tiếng Việt",
                  style: TextStyle(color: Colors.white)),
              value: "vi",
              groupValue: lang.languageCode,
              activeColor: Colors.green,
              onChanged: (value) {
                lang.changeLanguage(value!);
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
            RadioListTile<String>(
              title: const Text("English",
                  style: TextStyle(color: Colors.white)),
              value: "en",
              groupValue: lang.languageCode,
              activeColor: Colors.green,
              onChanged: (value) {
                lang.changeLanguage(value!);
                Navigator.pop(ctx);
                setState(() {});
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── ĐỔI MẬT KHẨU ──
  void _showChangePasswordDialog(BuildContext context, LanguageProvider lang) {
    final currentPwController = TextEditingController();
    final newPwController = TextEditingController();
    final confirmPwController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(
        lang: lang,
        currentPwController: currentPwController,
        newPwController: newPwController,
        confirmPwController: confirmPwController,
        t: _t,
        showSnack: _showSnack,
      ),
    );
  }

  // ── TRUNG TÂM TRỢ GIÚP ──
  void _showHelpDialog(BuildContext context, LanguageProvider lang) {
    final isVi = lang.languageCode == "vi";

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          _t(lang, "Trung tâm trợ giúp", "Help Center"),
          style: const TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _helpItem(
                icon: Icons.question_answer,
                title: isVi ? "Cách thêm giao dịch?" : "How to add a transaction?",
                desc: isVi
                    ? "Nhấn nút + ở màn hình chính, chọn loại giao dịch, nhập số tiền và danh mục."
                    : "Tap the + button on the home screen, select transaction type, enter amount and category.",
              ),
              const Divider(color: Colors.grey),
              _helpItem(
                icon: Icons.pie_chart,
                title: isVi ? "Cách đặt ngân sách?" : "How to set a budget?",
                desc: isVi
                    ? "Vào tab Ngân sách, nhấn nút + để tạo ngân sách mới cho từng danh mục."
                    : "Go to Budget tab, tap + to create a new budget for each category.",
              ),
              const Divider(color: Colors.grey),
              _helpItem(
                icon: Icons.sync,
                title: isVi ? "Đồng bộ dữ liệu?" : "How to sync data?",
                desc: isVi
                    ? "Dữ liệu được tự động đồng bộ qua Firebase. Nhấn nút đồng bộ trên tab Ngân sách để cập nhật."
                    : "Data is auto-synced via Firebase. Tap sync button on Budget tab to refresh.",
              ),
              const Divider(color: Colors.grey),
              _helpItem(
                icon: Icons.contact_mail,
                title: isVi ? "Liên hệ hỗ trợ" : "Contact Support",
                desc: isVi
                    ? "Email: support@example.com\nHotline: 1900 XXXX"
                    : "Email: support@example.com\nHotline: 1900 XXXX",
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(_t(lang, "Đóng", "Close"),
                style: const TextStyle(color: Colors.green)),
          ),
        ],
      ),
    );
  }

  Widget _helpItem({
    required IconData icon,
    required String title,
    required String desc,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.green, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14)),
                const SizedBox(height: 4),
                Text(desc,
                    style: const TextStyle(
                        color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── ĐĂNG XUẤT ──
  Widget _buildLogoutButton(BuildContext context, LanguageProvider lang) {
    return TextButton(
      onPressed: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1A1A1A),
            title: Text(_t(lang, "Đăng xuất", "Logout"),
                style: const TextStyle(color: Colors.white)),
            content: Text(
                _t(lang, "Bạn có chắc chắn muốn đăng xuất không?",
                    "Are you sure you want to logout?"),
                style: const TextStyle(color: Colors.grey)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(_t(lang, "Hủy", "Cancel"),
                    style: const TextStyle(color: Colors.green)),
              ),
              TextButton(
                onPressed: () async {
                  await FirebaseAuth.instance.signOut();
                  if (context.mounted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  }
                },
                child: Text(_t(lang, "Đăng xuất", "Logout"),
                    style:
                        const TextStyle(color: Colors.redAccent)),
              ),
            ],
          ),
        );
      },
      child: Text(
        _t(lang, "Đăng xuất tài khoản", "Logout Account"),
        style: const TextStyle(
            color: Colors.redAccent,
            fontSize: 16,
            fontWeight: FontWeight.w500),
      ),
    );
  }

  void _showSnack(BuildContext context, LanguageProvider lang, String vi,
      String en,
      {bool isError = true}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_t(lang, vi, en)),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }
}

// ── WIDGET ĐỔI MẬT KHẨU (riêng để quản lý state nội bộ) ──
class _ChangePasswordDialog extends StatefulWidget {
  final LanguageProvider lang;
  final TextEditingController currentPwController;
  final TextEditingController newPwController;
  final TextEditingController confirmPwController;
  final _TransFunc t;
  final _SnackFunc showSnack;

  const _ChangePasswordDialog({
    required this.lang,
    required this.currentPwController,
    required this.newPwController,
    required this.confirmPwController,
    required this.t,
    required this.showSnack,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(
        widget.t(lang, "Đổi mật khẩu", "Change Password"),
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.currentPwController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.t(lang, "Mật khẩu hiện tại", "Current password"),
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.newPwController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.t(lang, "Mật khẩu mới", "New password"),
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: widget.confirmPwController,
            obscureText: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              labelText: widget.t(lang, "Xác nhận mật khẩu", "Confirm password"),
              labelStyle: const TextStyle(color: Colors.grey),
              filled: true,
              fillColor: const Color(0xFF2C2C2E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.only(top: 16),
              child: CircularProgressIndicator(color: Colors.green),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: Text(widget.t(lang, "Hủy", "Cancel"),
              style: const TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _changePassword,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
          child: Text(widget.t(lang, "Đổi mật khẩu", "Change Password")),
        ),
      ],
    );
  }

  Future<void> _changePassword() async {
    final lang = widget.lang;
    final current = widget.currentPwController.text.trim();
    final newPassword = widget.newPwController.text.trim();
    final confirm = widget.confirmPwController.text.trim();

    if (current.isEmpty || newPassword.isEmpty || confirm.isEmpty) {
      widget.showSnack(context, lang, "Vui lòng nhập đầy đủ thông tin",
          "Please fill all fields");
      return;
    }
    if (newPassword.length < 6) {
      widget.showSnack(context, lang, "Mật khẩu mới phải có ít nhất 6 ký tự",
          "New password must be at least 6 characters");
      return;
    }
    if (newPassword != confirm) {
      widget.showSnack(context, lang, "Mật khẩu xác nhận không khớp",
          "Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      final credential = EmailAuthProvider.credential(
        email: user!.email!,
        password: current,
      );
      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);

      if (context.mounted) {
        Navigator.pop(context);
        widget.showSnack(context, lang, "Đã đổi mật khẩu thành công!",
            "Password changed successfully!",
            isError: false);
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg = e.code == "wrong-password"
          ? (widget.t(lang, "Mật khẩu hiện tại không đúng",
              "Current password is incorrect"))
          : (widget.t(lang, "Lỗi: ", "Error: ") + e.message!);
      widget.showSnack(context, lang, msg, msg);
    } catch (e) {
      setState(() => _isLoading = false);
      widget.showSnack(context, lang, "Lỗi hệ thống", "System error");
    }
  }
}
