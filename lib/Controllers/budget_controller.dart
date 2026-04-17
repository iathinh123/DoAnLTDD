import 'package:flutter/material.dart';
import '../Models/budget_model.dart';

class BudgetController extends ChangeNotifier {
  // Danh sách dữ liệu mẫu
  List<Budget> budgets = [
    Budget(title: "Ăn uống", limit: 5000000, spent: 1200000, icon: Icons.fastfood, color: Colors.orange),
    Budget(title: "Di chuyển", limit: 1000000, spent: 800000, icon: Icons.directions_car, color: Colors.blue),
  ];

// Sau này bạn sẽ thêm các hàm addBudget, deleteBudget ở đây
}