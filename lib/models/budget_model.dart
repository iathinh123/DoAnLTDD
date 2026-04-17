import 'package:flutter/material.dart';

class Budget {
  final String title;
  final double limit;
  final double spent;
  final IconData icon;
  final Color color;

  Budget({
    required this.title,
    required this.limit,
    required this.spent,
    required this.icon,
    required this.color,
  });

  double get percent => spent / limit;
}