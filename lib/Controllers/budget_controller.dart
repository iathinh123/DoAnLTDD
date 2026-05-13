import 'package:flutter/material.dart';
import '../Models/budget_model.dart';
import '../Services/budget_service.dart';
import '../Services/category_service.dart';

class BudgetController extends ChangeNotifier {
  final BudgetService _service = BudgetService();
  final CategoryService _categoryService = CategoryService();

  List<Budget> budgets = [];
  int selectedMonth = DateTime.now().month;
  int selectedYear = DateTime.now().year;
  bool isLoading = false;

  // Danh sách categories động
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> get categories => _categories;

  // Tổng hạn mức
  double get totalLimit => budgets.fold(0, (sum, b) => sum + b.limit);

  // Tổng đã tiêu
  double get totalSpent => budgets.fold(0, (sum, b) => sum + b.spent);

  // Danh sách ngân sách cảnh báo
  List<Budget> get warningBudgets =>
      budgets.where((b) => b.isNearLimit || b.isOverLimit).toList();

  // Lắng nghe realtime budgets
  void listenBudgets() {
    isLoading = true;
    notifyListeners();

    _service.getBudgets(selectedMonth, selectedYear).listen((data) {
      budgets = data;
      isLoading = false;
      notifyListeners();
    });

    _service.listenToTransactionsAndSync(selectedMonth, selectedYear);
    _listenToCategories();
  }

  // Lắng nghe categories
  void _listenToCategories() {
    _categoryService.getCategories().listen((categories) {
      _categories = categories;
      notifyListeners();
    });
  }

  // Đổi tháng
  void changeMonth(int month, int year) {
    selectedMonth = month;
    selectedYear = year;
    listenBudgets();
  }

  // Thêm ngân sách
  Future<void> addBudget(Budget budget) async {
    await _service.addBudget(budget);
    await _service.syncAllSpent(selectedMonth, selectedYear);
  }

  // Cập nhật ngân sách
  Future<void> updateBudget(Budget budget) async {
    await _service.updateBudget(budget);
    await _service.syncAllSpent(selectedMonth, selectedYear);
  }

  // Xóa ngân sách
  Future<void> deleteBudget(String id) async {
    await _service.deleteBudget(id);
  }

  // Sync spent
  Future<void> syncSpent() async {
    isLoading = true;
    notifyListeners();
    await _service.syncAllSpent(selectedMonth, selectedYear);
    isLoading = false;
    notifyListeners();
  }

  // Lấy danh sách categories cho budget (chỉ expense)
  List<Map<String, dynamic>> getBudgetCategories() {
    return _categories.where((cat) => cat['type'] == 'expense').toList();
  }

  // Helper để lấy icon
  IconData getIcon(String iconName) {
    return _categoryService.getIconFromString(iconName);
  }

  // Helper để lấy màu
  Color getColor(int colorValue) {
    return _categoryService.getColorFromInt(colorValue);
  }
}