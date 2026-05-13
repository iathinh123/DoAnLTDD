import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // Danh mục mặc định (đồng bộ với HomeScreen)
  final List<Map<String, dynamic>> defaultCategories = [
    // Expense categories
    {'label': 'Ăn uống', 'icon': 'fastfood', 'color': 0xFFFF9800, 'type': 'expense'},
    {'label': 'Mua sắm', 'icon': 'shopping_bag', 'color': 0xFFE91E63, 'type': 'expense'},
    {'label': 'Di chuyển', 'icon': 'directions_car', 'color': 0xFF2196F3, 'type': 'expense'},
    {'label': 'Giải trí', 'icon': 'movie', 'color': 0xFF9C27B0, 'type': 'expense'},
    {'label': 'Sức khỏe', 'icon': 'health_and_safety', 'color': 0xFF4CAF50, 'type': 'expense'},
    {'label': 'Giáo dục', 'icon': 'school', 'color': 0xFF00BCD4, 'type': 'expense'},
    {'label': 'Nhà cửa', 'icon': 'home', 'color': 0xFF009688, 'type': 'expense'},
    {'label': 'Hóa đơn', 'icon': 'receipt', 'color': 0xFF3F51B5, 'type': 'expense'},
    // Income categories
    {'label': 'Lương', 'icon': 'attach_money', 'color': 0xFF4CAF50, 'type': 'income'},
    {'label': 'Thưởng', 'icon': 'celebration', 'color': 0xFFFF9800, 'type': 'income'},
    {'label': 'Thu khác', 'icon': 'category', 'color': 0xFF9E9E9E, 'type': 'income'},
    // Debt categories
    {'label': 'Cho vay', 'icon': 'handshake', 'color': 0xFF2196F3, 'type': 'debt'},
    {'label': 'Trả nợ', 'icon': 'payments', 'color': 0xFFF44336, 'type': 'debt'},
    {'label': 'Thu nợ', 'icon': 'account_balance', 'color': 0xFF4CAF50, 'type': 'debt'},
  ];

  // Lấy danh sách categories từ Firestore (kết hợp mặc định + user custom)
  Stream<List<Map<String, dynamic>>> getCategories() {
    if (_uid == null) return Stream.value(defaultCategories);

    return _db
        .collection('NguoiDung')
        .doc(_uid)
        .collection('categories')
        .snapshots()
        .map((snapshot) {
      final userCategories = snapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'label': data['name'] ?? '',
          'icon': data['icon'] ?? 'category',
          'color': data['color'] ?? 0xFF9E9E9E,
          'type': data['type'] ?? 'expense',
          'isCustom': true,
          'id': doc.id,
        };
      }).toList();

      // Gộp danh mục mặc định và danh mục user tự tạo
      final allCategories = [...defaultCategories];
      for (var cat in userCategories) {
        // Tránh trùng lặp
        if (!allCategories.any((c) => c['label'] == cat['label'])) {
          allCategories.add(cat);
        }
      }

      return allCategories;
    });
  }

  // Lấy danh sách categories theo loại
  Stream<List<Map<String, dynamic>>> getCategoriesByType(String type) {
    return getCategories().map((categories) {
      return categories.where((cat) => cat['type'] == type).toList();
    });
  }

  // Lưu danh mục mới
  Future<void> saveCategory(String name, String type, String icon, int color) async {
    if (_uid == null) return;

    await _db
        .collection('NguoiDung')
        .doc(_uid)
        .collection('categories')
        .add({
      'name': name,
      'type': type,
      'icon': icon,
      'color': color,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Xóa danh mục custom
  Future<void> deleteCategory(String id) async {
    if (_uid == null) return;
    await _db.collection('NguoiDung').doc(_uid).collection('categories').doc(id).delete();
  }

  // Lấy icon từ string
  IconData getIconFromString(String iconName) {
    switch (iconName) {
      case 'fastfood': return Icons.fastfood;
      case 'shopping_bag': return Icons.shopping_bag;
      case 'directions_car': return Icons.directions_car;
      case 'movie': return Icons.movie;
      case 'health_and_safety': return Icons.health_and_safety;
      case 'school': return Icons.school;
      case 'home': return Icons.home;
      case 'receipt': return Icons.receipt;
      case 'attach_money': return Icons.attach_money;
      case 'celebration': return Icons.celebration;
      case 'category': return Icons.category;
      case 'handshake': return Icons.handshake;
      case 'payments': return Icons.payments;
      case 'account_balance': return Icons.account_balance;
      default: return Icons.category;
    }
  }

  // Lấy màu từ int
  Color getColorFromInt(int colorValue) {
    return Color(colorValue);
  }
}