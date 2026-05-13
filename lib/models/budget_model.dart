import 'package:flutter/material.dart';

class Budget {
  final String id;
  final String title;
  final String category;
  final double limit;
  double spent;
  final IconData icon;
  final Color color;
  final int month;
  final int year;

  Budget({
    required this.id,
    required this.title,
    required this.category,
    required this.limit,
    this.spent = 0,
    required this.icon,
    required this.color,
    required this.month,
    required this.year,
  });

  double get percent => limit > 0 ? spent / limit : 0;
  double get remaining => limit - spent;
  bool get isOverLimit => spent > limit;
  bool get isNearLimit => percent >= 0.8 && percent <= 1.0;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'limit': limit,
      'spent': spent,
      'icon': icon.codePoint,
      'iconFontFamily': icon.fontFamily,
      'color': color.value,
      'month': month,
      'year': year,
    };
  }

  factory Budget.fromMap(String id, Map<String, dynamic> map) {
    return Budget(
      id: id,
      title: map['title'] ?? '',
      category: map['category'] ?? '',
      limit: (map['limit'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
      icon: IconData(
        map['icon'] ?? Icons.category.codePoint,
        fontFamily: map['iconFontFamily'] ?? 'MaterialIcons',
      ),
      color: Color(map['color'] ?? Colors.blue.value),
      month: map['month'] ?? DateTime.now().month,
      year: map['year'] ?? DateTime.now().year,
    );
  }

  Budget copyWith({double? spent}) {
    return Budget(
      id: id,
      title: title,
      category: category,
      limit: limit,
      spent: spent ?? this.spent,
      icon: icon,
      color: color,
      month: month,
      year: year,
    );
  }
}