import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../models/transaction_model.dart';

class TransactionScreen extends StatefulWidget {
  final List<TransactionModel> transactions;

  const TransactionScreen({
    super.key,
    required this.transactions,
  });

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  String _searchQuery = '';
  int? _selectedType; // null: tất cả, 0: chi, 1: thu, 2: vay nợ
  String? _selectedCategory;

  final TextEditingController _searchController = TextEditingController();

  String get userId => FirebaseAuth.instance.currentUser?.uid ?? "";

  // Format tiền
  String formatMoney(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: 'đ',
      decimalDigits: 0,
    );
    return formatter.format(amount);
  }

  // Xóa giao dịch
  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transactionId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã xóa giao dịch'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Cập nhật giao dịch
  Future<void> _updateTransaction(TransactionModel transaction) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('transactions')
          .doc(transaction.id)
          .update(transaction.toMap());

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Đã cập nhật giao dịch'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: const Text(
          'Giao Dịch',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(144),
          child: Column(
            children: [
              _buildSearchBar(),
              _buildFilterBar(),
            ],
          ),
        ),
      ),
      body: _buildTransactionList(),
    );
  }

  // Thanh tìm kiếm
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12),
        ),
        child: TextField(
          controller: _searchController,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm giao dịch...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
              icon: const Icon(Icons.clear, color: Colors.grey),
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _searchController.clear();
                });
              },
            )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );
  }

  // Bộ lọc
  Widget _buildFilterBar() {
    // Lấy danh sách category duy nhất từ transactions
    final Set<String> uniqueCategories = {};
    for (var t in widget.transactions) {
      uniqueCategories.add(t.category);
    }
    final categoryList = uniqueCategories.toList()..sort();

    return Column(
      children: [
        // Lọc theo loại
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            children: [
              _buildFilterChip('Tất cả', null),
              const SizedBox(width: 8),
              _buildFilterChip('💸 Chi', 0),
              const SizedBox(width: 8),
              _buildFilterChip('💰 Thu', 1),
              const SizedBox(width: 8),
              _buildFilterChip('🔄 Vay/Nợ', 2),
            ],
          ),
        ),
        // Lọc theo danh mục
        if (categoryList.isNotEmpty)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                _buildCategoryChip('Tất cả', null),
                const SizedBox(width: 8),
                ...categoryList.map((category) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildCategoryChip(category, category),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, int? type) {
    bool isSelected = _selectedType == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedType = selected ? type : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: const Color(0xFF00BCD4),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? category) {
    bool isSelected = _selectedCategory == category;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedCategory = selected ? category : null;
        });
      },
      backgroundColor: Colors.grey[800],
      selectedColor: const Color(0xFF00BCD4),
      labelStyle: TextStyle(
        color: isSelected ? Colors.black : Colors.white,
      ),
    );
  }

  // Danh sách giao dịch
  Widget _buildTransactionList() {
    var transactions = List<TransactionModel>.from(widget.transactions);

    // Lọc theo loại
    if (_selectedType != null) {
      transactions = transactions.where((t) => t.type == _selectedType).toList();
    }

    // Lọc theo danh mục
    if (_selectedCategory != null) {
      transactions = transactions.where((t) => t.category == _selectedCategory).toList();
    }

    // Lọc theo tìm kiếm
    if (_searchQuery.isNotEmpty) {
      transactions = transactions.where((t) =>
      t.note.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          t.category.toLowerCase().contains(_searchQuery.toLowerCase())
      ).toList();
    }

    if (transactions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt, size: 64, color: Colors.grey[700]),
            const SizedBox(height: 16),
            Text(
              'Chưa có giao dịch nào',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: transactions.length,
      itemBuilder: (context, index) {
        final transaction = transactions[index];
        return _buildTransactionCard(transaction);
      },
    );
  }

  // Card giao dịch
  Widget _buildTransactionCard(TransactionModel transaction) {
    final isExpense = transaction.amount < 0;
    final amountColor = isExpense ? Colors.red[400] : Colors.green[400];
    final amountText = isExpense
        ? '- ${formatMoney(-transaction.amount)}'
        : '+ ${formatMoney(transaction.amount)}';

    String typeIcon;
    switch (transaction.type) {
      case 0:
        typeIcon = '💸';
        break;
      case 1:
        typeIcon = '💰';
        break;
      case 2:
        typeIcon = '🔄';
        break;
      default:
        typeIcon = '📝';
    }

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white, size: 30),
      ),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            title: const Text(
              'Xóa giao dịch',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Bạn có chắc muốn xóa giao dịch này?',
              style: TextStyle(color: Colors.white70),
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
      onDismissed: (direction) async {
        await _deleteTransaction(transaction.id);
      },
      child: Card(
        color: Colors.grey[900],
        margin: const EdgeInsets.only(bottom: 8),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: isExpense ? Colors.red[900] : Colors.green[900],
            child: Text(typeIcon, style: const TextStyle(fontSize: 20)),
          ),
          title: Text(
            transaction.category,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (transaction.note.isNotEmpty)
                Text(
                  transaction.note,
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              Text(
                _formatDate(transaction.date),
                style: TextStyle(color: Colors.grey[600], fontSize: 11),
              ),
            ],
          ),
          trailing: Text(
            amountText,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: amountColor,
            ),
          ),
          onTap: () => _showEditTransactionForm(context, transaction),
        ),
      ),
    );
  }

  // Form SỬA giao dịch
  void _showEditTransactionForm(BuildContext context, TransactionModel transaction) {
    final formKey = GlobalKey<FormState>();

    double amount = transaction.amount.abs();
    int type = transaction.type;
    String category = transaction.category;
    String note = transaction.note;
    DateTime date = transaction.date;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sửa Giao Dịch',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Loại giao dịch
                    SegmentedButton<int>(
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.resolveWith((states) {
                          if (states.contains(WidgetState.selected)) {
                            return const Color(0xFF00BCD4);
                          }
                          return Colors.grey[800];
                        }),
                        foregroundColor: WidgetStateProperty.all(Colors.white),
                      ),
                      segments: const [
                        ButtonSegment(value: 0, label: Text('💸 Chi')),
                        ButtonSegment(value: 1, label: Text('💰 Thu')),
                        ButtonSegment(value: 2, label: Text('🔄 Vay/Nợ')),
                      ],
                      selected: {type},
                      onSelectionChanged: (selected) {
                        setState(() {
                          type = selected.first;
                        });
                      },
                    ),
                    const SizedBox(height: 16),

                    // Số tiền
                    TextFormField(
                      initialValue: amount.toString(),
                      style: const TextStyle(color: Colors.white),
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Số tiền',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        prefixText: '₫ ',
                        prefixStyle: const TextStyle(color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập số tiền';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Vui lòng nhập số hợp lệ';
                        }
                        return null;
                      },
                      onSaved: (value) {
                        amount = double.parse(value!);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Danh mục
                    TextFormField(
                      initialValue: category,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Danh mục',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                      onSaved: (value) {
                        category = value!;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ghi chú
                    TextFormField(
                      initialValue: note,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Ghi chú',
                        labelStyle: TextStyle(color: Colors.grey[400]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: Colors.grey[700]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF00BCD4)),
                        ),
                        filled: true,
                        fillColor: Colors.grey[850],
                      ),
                      onSaved: (value) {
                        note = value ?? '';
                      },
                    ),
                    const SizedBox(height: 16),

                    // Ngày tháng
                    ListTile(
                      tileColor: Colors.grey[850],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        'Ngày giao dịch',
                        style: TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        _formatDate(date),
                        style: const TextStyle(color: Color(0xFF00BCD4)),
                      ),
                      trailing: const Icon(Icons.calendar_today, color: Colors.white),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: date,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now(),
                          builder: (context, child) {
                            return Theme(
                              data: ThemeData.dark(),
                              child: child!,
                            );
                          },
                        );
                        if (picked != null) {
                          setState(() {
                            date = picked;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey[800],
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text('Hủy'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () async {
                              if (formKey.currentState!.validate()) {
                                formKey.currentState!.save();

                                final updatedTransaction = TransactionModel(
                                  id: transaction.id,
                                  amount: amount,
                                  category: category,
                                  note: note,
                                  type: type,
                                  date: date,
                                );

                                await _updateTransaction(updatedTransaction);
                                if (mounted) {
                                  Navigator.pop(context);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00BCD4),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Cập nhật',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}