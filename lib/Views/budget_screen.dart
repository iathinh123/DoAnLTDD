import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/budget_controller.dart';
import '../Models/budget_model.dart';
import '../Services/category_service.dart';

class BudgetScreen extends StatelessWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<BudgetController>();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Ngân sách",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync, color: Color(0xFF00BCD4)),
            tooltip: "Đồng bộ chi tiêu",
            onPressed: () async {
              await controller.syncSpent();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Đã đồng bộ chi tiêu!"),
                    backgroundColor: Colors.green,
                    duration: Duration(seconds: 1),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF00BCD4)),
            onPressed: () => _showAddEditDialog(context, controller),
          ),
        ],
      ),
      body: controller.isLoading
          ? const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00BCD4)),
        ),
      )
          : Column(
        children: [
          _buildMonthSelector(context, controller),
          _buildSummaryCard(controller),
          if (controller.warningBudgets.isNotEmpty)
            _buildWarningBanner(controller),
          const SizedBox(height: 8),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                await controller.syncSpent();
              },
              color: const Color(0xFF00BCD4),
              child: controller.budgets.isEmpty
                  ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.pie_chart_outline,
                      size: 64,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Chưa có ngân sách nào",
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () =>
                          _showAddEditDialog(context, controller),
                      icon: const Icon(Icons.add),
                      label: const Text("Thêm ngân sách mới"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF00BCD4),
                        foregroundColor: Colors.black,
                      ),
                    ),
                  ],
                ),
              )
                  : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: controller.budgets.length,
                itemBuilder: (context, index) {
                  return _buildBudgetCard(
                    context,
                    controller,
                    controller.budgets[index],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Chọn tháng ──
  Widget _buildMonthSelector(BuildContext context, BudgetController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: () {
              int m = controller.selectedMonth - 1;
              int y = controller.selectedYear;
              if (m < 1) {
                m = 12;
                y--;
              }
              controller.changeMonth(m, y);
            },
          ),
          Text(
            "Tháng ${controller.selectedMonth}/${controller.selectedYear}",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: () {
              int m = controller.selectedMonth + 1;
              int y = controller.selectedYear;
              if (m > 12) {
                m = 1;
                y++;
              }
              controller.changeMonth(m, y);
            },
          ),
        ],
      ),
    );
  }

  // ── Card tổng quan ──
  Widget _buildSummaryCard(BudgetController controller) {
    double percent = controller.totalLimit > 0
        ? controller.totalSpent / controller.totalLimit
        : 0;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[800]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Tổng quan tháng",
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _summaryItem(
                "Tổng hạn mức",
                "${_formatMoney(controller.totalLimit)}đ",
                Colors.white,
              ),
              _summaryItem(
                "Đã tiêu",
                "${_formatMoney(controller.totalSpent)}đ",
                Colors.orange,
              ),
              _summaryItem(
                "Còn lại",
                "${_formatMoney(controller.totalLimit - controller.totalSpent)}đ",
                controller.totalLimit - controller.totalSpent < 0
                    ? Colors.red
                    : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(
              percent > 0.9
                  ? Colors.red
                  : percent > 0.7
                  ? Colors.orange
                  : const Color(0xFF00BCD4),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            "${(percent * 100).toInt()}% đã sử dụng",
            style: TextStyle(
              color: percent > 0.9 ? Colors.red : Colors.white54,
              fontSize: 12,
            ),
            textAlign: TextAlign.end,
          ),
        ],
      ),
    );
  }

  Widget _summaryItem(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ── Banner cảnh báo ──
  Widget _buildWarningBanner(BudgetController controller) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${controller.warningBudgets.take(3).map((b) => b.title).join(', ')}${controller.warningBudgets.length > 3 ? '...' : ''} ${controller.warningBudgets.length > 1 ? 'đang' : 'đang'} sắp hoặc đã vượt hạn mức!",
              style: const TextStyle(color: Colors.red, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Card từng ngân sách ──
  Widget _buildBudgetCard(
      BuildContext context,
      BudgetController controller,
      Budget budget,
      ) {
    return Dismissible(
      key: Key(budget.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 16),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: Colors.red,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: const Color(0xFF1E1E1E),
            title: const Text(
              'Xóa ngân sách',
              style: TextStyle(color: Colors.white),
            ),
            content: Text(
              'Bạn có chắc muốn xóa ngân sách "${budget.title}"?',
              style: const TextStyle(color: Colors.white70),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Xóa', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) => controller.deleteBudget(budget.id),
      child: GestureDetector(
        onTap: () => _showAddEditDialog(context, controller, budget: budget),
        child: Container(
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: budget.isOverLimit
                ? Border.all(color: Colors.red.withOpacity(0.5), width: 1.5)
                : budget.isNearLimit
                ? Border.all(color: Colors.orange.withOpacity(0.5), width: 1.5)
                : null,
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: budget.color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(budget.icon, color: budget.color, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            budget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            budget.category,
                            style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (budget.isOverLimit)
                        const Icon(Icons.warning, color: Colors.red, size: 18),
                      if (budget.isNearLimit && !budget.isOverLimit)
                        const Icon(Icons.warning_amber,
                            color: Colors.orange, size: 18),
                      Text(
                        "${(budget.percent * 100).toInt()}%",
                        style: TextStyle(
                          color: budget.isOverLimit
                              ? Colors.red
                              : budget.isNearLimit
                              ? Colors.orange
                              : Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: budget.percent > 1 ? 1 : budget.percent,
                backgroundColor: Colors.grey[800],
                valueColor: AlwaysStoppedAnimation<Color>(
                  budget.isOverLimit
                      ? Colors.red
                      : budget.isNearLimit
                      ? Colors.orange
                      : budget.color,
                ),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Đã tiêu: ${_formatMoney(budget.spent)}đ",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    "Còn: ${_formatMoney(budget.remaining)}đ",
                    style: TextStyle(
                      color: budget.remaining < 0 ? Colors.red : Colors.green,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    "Hạn mức: ${_formatMoney(budget.limit)}đ",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog thêm/sửa ngân sách (DÙNG CATEGORIES ĐỘNG) ──
  // ── Dialog thêm/sửa ngân sách ──
  // ── Dialog thêm/sửa ngân sách ──
  void _showAddEditDialog(BuildContext context, BudgetController controller,
      {Budget? budget}) {
    final isEdit = budget != null;
    final titleController = TextEditingController(text: budget?.title ?? '');
    final limitController = TextEditingController(
      text: budget != null ? budget.limit.toInt().toString() : '',
    );
    String selectedCategory = budget?.category ?? 'Ăn uống';
    IconData selectedIcon = budget?.icon ?? Icons.fastfood;
    Color selectedColor = budget?.color ?? Colors.orange;

    // Lấy danh sách categories từ controller (đã đồng bộ với HomeScreen)
    final categories = controller.getBudgetCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    isEdit ? "Sửa ngân sách" : "Thêm ngân sách mới",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                TextField(
                  controller: titleController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Tên ngân sách", Icons.title),
                  autofocus: !isEdit,
                ),
                const SizedBox(height: 16),

                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: _inputDecoration("Hạn mức (đ)", Icons.attach_money),
                ),
                const SizedBox(height: 16),

                const Text(
                  "Danh mục chi tiêu",
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),

                if (categories.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      "Chưa có danh mục chi tiêu nào.\nHãy thêm giao dịch để tạo danh mục!",
                      style: TextStyle(color: Colors.grey),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((cat) {
                      final isSelected = selectedCategory == cat['label'];
                      final color = controller.getColor(cat['color'] as int);
                      final icon = controller.getIcon(cat['icon'] as String);

                      return GestureDetector(
                        onTap: () => setState(() {
                          selectedCategory = cat['label'] as String;
                          selectedIcon = icon;
                          selectedColor = color;
                        }),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? color.withOpacity(0.2) : Colors.grey[900],
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                icon,
                                color: color,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected ? Colors.white : Colors.grey,
                                  fontSize: 13,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF00BCD4),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final limit = double.tryParse(limitController.text) ?? 0;
                      if (title.isEmpty) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng nhập tên ngân sách"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      if (limit <= 0) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                            content: Text("Vui lòng nhập hạn mức hợp lệ"),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final newBudget = Budget(
                        id: budget?.id ?? '',
                        title: title,
                        category: selectedCategory,
                        limit: limit,
                        spent: budget?.spent ?? 0,
                        icon: selectedIcon,
                        color: selectedColor,
                        month: controller.selectedMonth,
                        year: controller.selectedYear,
                      );

                      if (isEdit) {
                        await controller.updateBudget(newBudget);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Đã cập nhật ngân sách"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        await controller.addBudget(newBudget);
                        if (ctx.mounted) {
                          ScaffoldMessenger.of(ctx).showSnackBar(
                            const SnackBar(
                              content: Text("Đã thêm ngân sách mới"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      }
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: Text(
                      isEdit ? "CẬP NHẬT" : "THÊM NGÂN SÁCH",
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
// Dialog thêm danh mục mới
  void _showAddCategoryDialog(BuildContext context, BudgetController controller) {
    final nameController = TextEditingController();
    String selectedType = 'expense';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text(
          'Thêm danh mục mới',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Tên danh mục',
                hintStyle: TextStyle(color: Colors.grey),
                filled: true,
                fillColor: Color(0xFF2C2C2E),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(8)),
                  borderSide: BorderSide.none,
                ),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            const Text(
              'Loại danh mục',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ChoiceChip(
                  label: const Text('Chi tiêu'),
                  selected: selectedType == 'expense',
                  onSelected: (selected) {
                    if (selected) selectedType = 'expense';
                  },
                  selectedColor: Colors.red.withOpacity(0.3),
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(
                    color: selectedType == 'expense' ? Colors.red : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Thu nhập'),
                  selected: selectedType == 'income',
                  onSelected: (selected) {
                    if (selected) selectedType = 'income';
                  },
                  selectedColor: Colors.green.withOpacity(0.3),
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(
                    color: selectedType == 'income' ? Colors.green : Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Vay/Nợ'),
                  selected: selectedType == 'debt',
                  onSelected: (selected) {
                    if (selected) selectedType = 'debt';
                  },
                  selectedColor: Colors.blue.withOpacity(0.3),
                  backgroundColor: Colors.grey[800],
                  labelStyle: TextStyle(
                    color: selectedType == 'debt' ? Colors.blue : Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final categoryService = CategoryService();
                await categoryService.saveCategory(
                  nameController.text,
                  selectedType,
                  'category', // icon mặc định
                  0xFF9E9E9E, // color mặc định
                );
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(
                      content: Text('Đã thêm danh mục mới'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00BCD4),
              foregroundColor: Colors.black,
            ),
            child: const Text('Thêm'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey),
      prefixIcon: Icon(icon, color: const Color(0xFF00BCD4), size: 20),
      filled: true,
      fillColor: Colors.grey[900],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatMoney(double amount) {
    return amount.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
    );
  }
}