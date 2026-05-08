import 'package:flutter/material.dart';
import '../models/transaction_model.dart';
import '../services/search_service.dart';

class AdvancedSearchScreen extends StatefulWidget {
  final List<TransactionModel> allTransactions;
  const AdvancedSearchScreen({super.key, required this.allTransactions});

  @override
  State<AdvancedSearchScreen> createState() => _AdvancedSearchScreenState();
}

class _AdvancedSearchScreenState extends State<AdvancedSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _history = [];
  List<TransactionModel> _results = [];
  bool _isSearching = false;
  String _currentQuery = "";

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  void _loadHistory() async {
    final history = await SearchService.getHistory();
    setState(() => _history = history);
  }

  void _performSearch(String query) {
    if (query.isEmpty) return;

    SearchService.saveHistory(query);
    _loadHistory();

    setState(() {
      _currentQuery = query;
      _isSearching = true;
      _results = widget.allTransactions.where((t) {
        return t.category.toLowerCase().contains(query.toLowerCase()) ||
            (t.note?.toLowerCase().contains(query.toLowerCase()) ?? false);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    // SỬA LỖI QUAY LẠI: Dùng PopScope để chặn thoát trang khi đang hiện kết quả
    return PopScope(
      canPop: !_isSearching,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_isSearching) {
          setState(() {
            _isSearching = false;
            _searchController.clear();
          });
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              if (_isSearching) {
                setState(() => _isSearching = false);
              } else {
                Navigator.pop(context);
              }
            },
          ),
          title: TextField(
            controller: _searchController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: "Tìm kiếm nhóm hoặc ghi chú...",
              hintStyle: TextStyle(color: Colors.grey, fontSize: 16),
              border: InputBorder.none,
            ),
            onSubmitted: _performSearch,
          ),
        ),
        body: Column(
          children: [
            if (!_isSearching) Expanded(child: _buildHistorySection()),
            if (_isSearching) ...[
              _buildStatsSummary(), // NÂNG CẤP: Hiện tổng tiền kết quả
              Expanded(child: _buildResultList()),
            ],
          ],
        ),
      ),
    );
  }

  // NÂNG CẤP: Hiển thị thống kê nhanh kết quả tìm được
  Widget _buildStatsSummary() {
    double total = _results.fold(0, (sum, item) => sum + item.amount);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: Colors.white.withOpacity(0.05),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text("Tìm thấy ${_results.length} giao dịch", style: const TextStyle(color: Colors.grey)),
          Text("Tổng: ${total.toStringAsFixed(0)} đ",
              style: TextStyle(color: total < 0 ? Colors.redAccent : Colors.blueAccent, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    if (_history.isEmpty) {
      return const Center(child: Text("Chưa có lịch sử tìm kiếm", style: TextStyle(color: Colors.grey)));
    }
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween, // Đã sửa từ 'separated'
            children: [
              const Text("Lịch sử gần đây", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
              TextButton(
                onPressed: () async {
                  await SearchService.clearHistory();
                  _loadHistory();
                },
                child: const Text("Xóa tất cả", style: TextStyle(color: Colors.green)),
              )
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Wrap(
            spacing: 8,
            children: _history.map((h) => ActionChip(
              backgroundColor: const Color(0xFF1A1A1A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              label: Text(h, style: const TextStyle(color: Colors.white, fontSize: 13)),
              onPressed: () {
                _searchController.text = h;
                _performSearch(h);
              },
            )).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildResultList() {
    if (_results.isEmpty) {
      // NÂNG CẤP: Trạng thái trống (Empty State)
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 80, color: Colors.grey),
            SizedBox(height: 10),
            Text("Không tìm thấy kết quả nào", style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (context, index) {
        final t = _results[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.grey[900], shape: BoxShape.circle),
            child: const Icon(Icons.receipt_long, color: Colors.green, size: 20),
          ),
          title: _highlightText(t.category, _currentQuery), // NÂNG CẤP: Highlight từ khóa
          subtitle: Text(t.note ?? "Không có ghi chú", style: const TextStyle(color: Colors.grey, fontSize: 12)),
          trailing: Text("${t.amount} đ",
              style: TextStyle(color: t.amount < 0 ? Colors.redAccent : Colors.blueAccent, fontWeight: FontWeight.bold)),
        );
      },
    );
  }

  // NÂNG CẤP: Hàm làm nổi bật từ khóa tìm kiếm
  Widget _highlightText(String text, String query) {
    if (query.isEmpty || !text.toLowerCase().contains(query.toLowerCase())) {
      return Text(text, style: const TextStyle(color: Colors.white));
    }
    final int startIndex = text.toLowerCase().indexOf(query.toLowerCase());
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.white, fontSize: 16),
        children: [
          TextSpan(text: text.substring(0, startIndex)),
          TextSpan(text: text.substring(startIndex, startIndex + query.length),
              style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          TextSpan(text: text.substring(startIndex + query.length)),
        ],
      ),
    );
  }
}