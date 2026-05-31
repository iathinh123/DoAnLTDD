import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CategoryService {
  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  final List<Map<String, dynamic>> defaultCategories = [
    {'label': 'Ăn uống', 'icon': 'fastfood', 'color': 0xFFFF9800, 'type': 'expense'},
    {'label': 'Mua sắm', 'icon': 'shopping_bag', 'color': 0xFFE91E63, 'type': 'expense'},
    {'label': 'Di chuyển', 'icon': 'directions_car', 'color': 0xFF2196F3, 'type': 'expense'},
    {'label': 'Giải trí', 'icon': 'movie', 'color': 0xFF9C27B0, 'type': 'expense'},
    {'label': 'Sức khỏe', 'icon': 'health_and_safety', 'color': 0xFF4CAF50, 'type': 'expense'},
    {'label': 'Giáo dục', 'icon': 'school', 'color': 0xFF00BCD4, 'type': 'expense'},
    {'label': 'Nhà cửa', 'icon': 'home', 'color': 0xFF009688, 'type': 'expense'},
    {'label': 'Hóa đơn', 'icon': 'receipt', 'color': 0xFF3F51B5, 'type': 'expense'},
    {'label': 'Lương', 'icon': 'attach_money', 'color': 0xFF4CAF50, 'type': 'income'},
    {'label': 'Thưởng', 'icon': 'celebration', 'color': 0xFFFF9800, 'type': 'income'},
    {'label': 'Thu khác', 'icon': 'category', 'color': 0xFF9E9E9E, 'type': 'income'},
    {'label': 'Cho vay', 'icon': 'handshake', 'color': 0xFF2196F3, 'type': 'debt'},
    {'label': 'Trả nợ', 'icon': 'payments', 'color': 0xFFF44336, 'type': 'debt'},
    {'label': 'Thu nợ', 'icon': 'account_balance', 'color': 0xFF4CAF50, 'type': 'debt'},
  ];

  // ĐỔI COLLECTION TỪ NguoiDung → users
  Stream<List<Map<String, dynamic>>> getCategories() {
    if (_uid == null) return Stream.value(defaultCategories);

    return _db
        .collection('users')       // ← ĐỔI ĐÂY
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

      final allCategories = [...defaultCategories];
      for (var cat in userCategories) {
        // Tránh trùng lặp kể cả không dấu
        if (!allCategories.any((c) => _normalize(c['label']) == _normalize(cat['label']))) {
          allCategories.add(cat);
        }
      }

      return allCategories;
    });
  }

  Stream<List<Map<String, dynamic>>> getCategoriesByType(String type) {
    return getCategories().map((categories) {
      return categories.where((cat) => cat['type'] == type).toList();
    });
  }

  Future<void> saveCategory(String name, String type, String icon, int color) async {
    if (_uid == null) return;

    await _db
        .collection('users')       // ← ĐỔI ĐÂY
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

  Future<void> deleteCategory(String id) async {
    if (_uid == null) return;
    await _db
        .collection('users')       // ← ĐỔI ĐÂY
        .doc(_uid)
        .collection('categories')
        .doc(id)
        .delete();
  }

  // Thêm hàm normalize để so sánh không dấu
  String _normalize(String text) {
    const vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    const latin =      'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    String result = text.toLowerCase();
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }
    return result;
  }

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

  Color getColorFromInt(int colorValue) {
    return Color(colorValue);
  }
}