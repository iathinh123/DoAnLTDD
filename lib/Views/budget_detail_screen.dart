import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/budget_controller.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../Services/transaction_service.dart';

class BudgetDetailScreen extends StatefulWidget {
  final Budget budget;

  const BudgetDetailScreen({super.key, required this.budget});

  @override
  State<BudgetDetailScreen> createState() => _BudgetDetailScreenState();
}

class _BudgetDetailScreenState extends State<BudgetDetailScreen> {
  final TransactionService _transactionService = TransactionService();
  List<TransactionModel> _transactions = [];
  bool _isLoading = true;
  StreamSubscription? _transactionSubscription;

  Color get _accent => const Color(0xFF00BCD4);

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _transactionSubscription?.cancel();
    super.dispose();
  }

  void _loadTransactions() {
    _transactionSubscription = _transactionService
        .getTransactions()
        .listen((transactions) {
      if (mounted) {
        setState(() {
          _transactions = transactions.where((t) =>
              t.category == widget.budget.category &&
              t.date.month == widget.budget.month &&
              t.date.year == widget.budget.year).toList();
          _isLoading = false;
        });
      }
    });
  }

  void _showEditDialog() {
    final theme = Theme.of(context);
    final controller = context.read<BudgetController>();
    final titleController = TextEditingController(text: widget.budget.title);
    final limitController = TextEditingController(
      text: widget.budget.limit.toInt().toString(),
    );
    String selectedCategory = widget.budget.category;
    IconData selectedIcon = widget.budget.icon;
    Color selectedColor = widget.budget.color;
    final categories = controller.getBudgetCategories();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: theme.cardColor,
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
                    'Sửa ngân sách',
                    style: TextStyle(
                      color: Theme.of(ctx).textTheme.bodyMedium?.color,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: titleController,
                  style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color),
                  decoration: _inputDecoration(ctx, 'Tên ngân sách', Icons.title),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: limitController,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Theme.of(ctx).textTheme.bodyMedium?.color),
                  decoration: _inputDecoration(ctx, 'Hạn mức (đ)', Icons.attach_money),
                ),
                const SizedBox(height: 16),
                Text(
                  'Danh mục chi tiêu',
                  style: TextStyle(
                    color: Theme.of(ctx).textTheme.bodySmall?.color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Chưa có danh mục chi tiêu nào.',
                      style: TextStyle(color: Theme.of(ctx).textTheme.bodySmall?.color),
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
                            color: isSelected
                                ? color.withAlpha(51)
                                : Theme.of(ctx).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(
                              color: isSelected ? color : Colors.transparent,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(icon, color: color, size: 18),
                              const SizedBox(width: 6),
                              Text(
                                cat['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? Theme.of(ctx).textTheme.bodyMedium?.color
                                      : Theme.of(ctx).textTheme.bodySmall?.color,
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w500
                                      : FontWeight.normal,
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
                      backgroundColor: _accent,
                      foregroundColor: theme.textTheme.bodyMedium?.color,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final limit = double.tryParse(limitController.text) ?? 0;
                      if (title.isEmpty || limit <= 0) return;

                      final updated = Budget(
                        id: widget.budget.id,
                        title: title,
                        category: selectedCategory,
                        limit: limit,
                        spent: widget.budget.spent,
                        icon: selectedIcon,
                        color: selectedColor,
                        month: widget.budget.month,
                        year: widget.budget.year,
                      );
                      await controller.updateBudget(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (mounted) Navigator.pop(context, true);
                    },
                    child: const Text(
                      'CẬP NHẬT',
                      style: TextStyle(
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

  Future<void> _confirmDelete() async {
    final theme = Theme.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          'Xóa ngân sách',
          style: TextStyle(color: theme.textTheme.bodyMedium?.color),
        ),
        content: Text(
          'Bạn có chắc muốn xóa ngân sách "${widget.budget.title}"?',
          style: TextStyle(color: theme.textTheme.bodySmall?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Hủy', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<BudgetController>().deleteBudget(widget.budget.id);
      if (mounted) Navigator.pop(context, true);
    }
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    final theme = Theme.of(context);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: theme.textTheme.bodySmall?.color),
      prefixIcon: Icon(icon, color: _accent, size: 20),
      filled: true,
      fillColor: theme.colorScheme.surfaceVariant,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  String _formatMoney(double amount) {
    return amount
        .toInt()
        .toString()
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final budget = widget.budget;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textTheme.bodyMedium?.color),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          budget.title,
          style: TextStyle(
            color: theme.textTheme.bodyMedium?.color,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF00BCD4)),
            onPressed: _showEditDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: _confirmDelete,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildBudgetHeader(budget),
            const SizedBox(height: 24),
            _buildTransactionSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildBudgetHeader(Budget budget) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: budget.color.withAlpha(51),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(budget.icon, color: budget.color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.title,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      budget.category,
                      style: TextStyle(
                        color: theme.textTheme.bodySmall?.color,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          LinearProgressIndicator(
            value: budget.percent > 1 ? 1 : budget.percent,
            backgroundColor: theme.dividerColor,
            valueColor: AlwaysStoppedAnimation<Color>(
              budget.isOverLimit
                  ? Colors.red
                  : budget.isNearLimit
                  ? Colors.orange
                  : budget.color,
            ),
            minHeight: 10,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatItem('Đã tiêu', '${_formatMoney(budget.spent)}đ',
                  Colors.orange),
              Container(
                width: 1,
                height: 40,
                color: theme.dividerColor,
              ),
              _buildStatItem('Còn lại', '${_formatMoney(budget.remaining)}đ',
                  budget.remaining < 0 ? Colors.red : Colors.green),
              Container(
                width: 1,
                height: 40,
                color: theme.dividerColor,
              ),
              _buildStatItem('Hạn mức', '${_formatMoney(budget.limit)}đ',
                  theme.textTheme.bodyMedium?.color ?? Colors.white70),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${(budget.percent * 100).toStringAsFixed(1)}% đã sử dụng - Tháng ${budget.month}/${budget.year}',
            style: TextStyle(
              color: budget.isOverLimit ? Colors.red : theme.textTheme.bodySmall?.color,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Giao dịch trong tháng',
              style: TextStyle(
                color: theme.textTheme.bodyMedium?.color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              '${_transactions.length} giao dịch',
              style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 13),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_isLoading)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(_accent),
              ),
            ),
          )
        else if (_transactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: theme.cardColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(Icons.receipt_long, size: 48, color: theme.disabledColor),
                const SizedBox(height: 12),
                Text(
                  'Chưa có giao dịch nào',
                  style: TextStyle(color: theme.textTheme.bodySmall?.color),
                ),
              ],
            ),
          )
        else
          ...List.generate(_transactions.length, (index) {
            final t = _transactions[index];
            return _buildTransactionItem(t);
          }),
      ],
    );
  }

  Widget _buildTransactionItem(TransactionModel t) {
    final theme = Theme.of(context);
    final isExpense = t.amount < 0;
    final amountColor = isExpense ? Colors.red[400] : Colors.green[400];
    final amountText = isExpense
        ? '- ${_formatMoney(-t.amount)}đ'
        : '+ ${_formatMoney(t.amount)}đ';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: widget.budget.color.withAlpha(51),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isExpense ? Icons.trending_down : Icons.trending_up,
              color: amountColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.note.isNotEmpty ? t.note : t.category,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(t.date),
                  style: TextStyle(color: theme.textTheme.bodySmall?.color, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            amountText,
            style: TextStyle(
              color: amountColor,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
