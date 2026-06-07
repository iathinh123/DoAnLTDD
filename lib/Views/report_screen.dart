import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'transaction_type_report_screen.dart';

class ReportScreen extends StatefulWidget {
  final String userId;

  const ReportScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  // Chế độ lọc hiện tại (Mặc định ban đầu là Lọc theo Tháng như cũ)
  String _filterType = "Tháng";
  DateTime _selectedDate = DateTime.now();
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  // Danh sách các tùy chọn khoảng thời gian hiển thị khi click vào Lịch
  final List<String> _timeOptions = ["Ngày", "Tuần", "Tháng", "Quý", "Năm", "Tất cả", "Tùy chỉnh"];

  // Biến lưu trữ khoảng ngày tùy chỉnh
  DateTimeRange? _customDateRange;

  // Hàm hiển thị Bottom Sheet chọn khoảng thời gian giống mẫu thiết kế của bạn
  void _showTimeFilterBottomSheet() {
    // Lấy nhanh màu sắc từ Theme hệ thống để đồng bộ Sáng/Tối cho BottomSheet
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor, // Đổi theo nền Sáng/Tối của App
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "Khoảng thời gian",
                style: TextStyle(
                    color: theme.textTheme.bodyLarge?.color,
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                ),
              ),
              const SizedBox(height: 16),
              // Tạo danh sách các nút bo tròn xếp dọc theo ảnh mẫu
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: _timeOptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    String option = _timeOptions[index];
                    bool isCurrent = _filterType == option;

                    // Tính toán màu nền cho các item nút bấm dựa trên chế độ Sáng/Tối
                    Color itemBgColor;
                    if (isCurrent) {
                      itemBgColor = isDark ? const Color(0xFF3A3A3C) : Colors.green.withOpacity(0.2);
                    } else {
                      itemBgColor = isDark ? const Color(0xFF2C2C2E) : theme.cardColor;
                    }

                    return InkWell(
                      onTap: () {
                        setState(() {
                          _filterType = option;
                        });
                        Navigator.pop(context); // Đóng menu sau khi chọn

                        // Nếu chọn Tùy chỉnh thì kích hoạt Picker riêng biệt
                        if (option == "Tùy chỉnh") {
                          _pickCustomDateRange();
                        }
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        decoration: BoxDecoration(
                          color: itemBgColor,
                          borderRadius: BorderRadius.circular(25), // Bo tròn thuôn dài chuẩn mẫu
                          border: isCurrent ? Border.all(color: Colors.green, width: 1) : null,
                        ),
                        child: Center(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: isCurrent ? Colors.green : theme.textTheme.bodyLarge?.color,
                              fontSize: 16,
                              fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Xử lý chọn khoảng ngày Tùy chỉnh (Date Range Picker)
  void _pickCustomDateRange() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: isDark
              ? ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Color(0xFF1C1C1E),
              onSurface: Colors.white,
            ),
          )
              : ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.green,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _customDateRange = picked;
      });
    }
  }

  // Hàm bổ sung: Tính toán cấu trúc khoảng thời gian (startDate, endDate, titlePeriod) dựa vào trạng thái bộ lọc
  Map<String, dynamic> _getFilterRange() {
    DateTime start = _selectedDate;
    DateTime end = _selectedDate;
    String title = _getFilterSubTitle();

    switch (_filterType) {
      case "Ngày":
        start = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 0, 0, 0);
        end = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, 23, 59, 59);
        break;
      case "Tuần":
        DateTime firstDayOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
        start = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day, 0, 0, 0);
        end = DateTime(lastDayOfWeek.year, lastDayOfWeek.month, lastDayOfWeek.day, 23, 59, 59);
        break;
      case "Tháng":
        start = DateTime(_selectedDate.year, _selectedDate.month, 1, 0, 0, 0);
        end = DateTime(_selectedDate.year, _selectedDate.month + 1, 0, 23, 59, 59);
        break;
      case "Quý":
        int quarter = ((_selectedDate.month - 1) / 3).floor();
        start = DateTime(_selectedDate.year, (quarter * 3) + 1, 1, 0, 0, 0);
        end = DateTime(_selectedDate.year, (quarter * 3) + 4, 0, 23, 59, 59);
        break;
      case "Năm":
        start = DateTime(_selectedDate.year, 1, 1, 0, 0, 0);
        end = DateTime(_selectedDate.year, 12, 31, 23, 59, 59);
        break;
      case "Tất cả":
        start = DateTime(2000, 1, 1, 0, 0, 0);
        end = DateTime(2100, 12, 31, 23, 59, 59);
        break;
      case "Tùy chỉnh":
        if (_customDateRange != null) {
          start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day, 0, 0, 0);
          end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
        }
        break;
    }
    return {"start": start, "end": end, "title": title};
  }

  // Hàm kiểm tra xem một bản ghi giao dịch có thỏa mãn điều kiện lọc thời gian hay không
  bool _checkFilterCondition(DateTime txDate) {
    switch (_filterType) {
      case "Ngày":
        return txDate.year == _selectedDate.year &&
            txDate.month == _selectedDate.month &&
            txDate.day == _selectedDate.day;

      case "Tuần":
        DateTime firstDayOfWeek = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime lastDayOfWeek = firstDayOfWeek.add(const Duration(days: 6));
        DateTime start = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
        DateTime end = DateTime(lastDayOfWeek.year, lastDayOfWeek.month, lastDayOfWeek.day, 23, 59, 59);
        return txDate.isAfter(start.subtract(const Duration(seconds: 1))) && txDate.isBefore(end.add(const Duration(seconds: 1)));

      case "Tháng":
        return txDate.year == _selectedDate.year && txDate.month == _selectedDate.month;

      case "Quý":
        int currentQuarter = ((_selectedDate.month - 1) / 3).floor() + 1;
        int txQuarter = ((txDate.month - 1) / 3).floor() + 1;
        return txDate.year == _selectedDate.year && currentQuarter == txQuarter;

      case "Năm":
        return txDate.year == _selectedDate.year;

      case "Tất cả":
        return true;

      case "Tùy chỉnh":
        if (_customDateRange == null) return false;
        return txDate.isAfter(_customDateRange!.start.subtract(const Duration(seconds: 1))) &&
            txDate.isBefore(_customDateRange!.end.add(const Duration(seconds: 1)));

      default:
        return false;
    }
  }

  // Chuỗi text hiển thị tiêu đề phụ dựa trên bộ lọc đang dùng
  String _getFilterSubTitle() {
    if (_filterType == "Tất cả") return "Toàn bộ thời gian";
    if (_filterType == "Tùy chỉnh" && _customDateRange != null) {
      return "${DateFormat('dd/MM').format(_customDateRange!.start)} - ${DateFormat('dd/MM/yyyy').format(_customDateRange!.end)}";
    }
    switch (_filterType) {
      case "Ngày":
        return DateFormat('dd/MM/yyyy').format(_selectedDate);
      case "Tuần":
        DateTime firstDay = _selectedDate.subtract(Duration(days: _selectedDate.weekday - 1));
        DateTime lastDay = firstDay.add(const Duration(days: 6));
        return "Tuần: ${DateFormat('dd/MM').format(firstDay)} - ${DateFormat('dd/MM').format(lastDay)}";
      case "Quý":
        int quarter = ((_selectedDate.month - 1) / 3).floor() + 1;
        return "Quý $quarter / ${_selectedDate.year}";
      case "Năm":
        return "Năm ${_selectedDate.year}";
      case "Tháng":
      default:
        return DateFormat('MM/yyyy').format(_selectedDate);
    }
  }

  // Danh sách lướt nhanh cho chế độ lọc Tháng
  List<DateTime> _getMonthsList() {
    DateTime now = DateTime.now();
    return [
      DateTime(now.year, now.month - 1, 1),
      DateTime(now.year, now.month, 1),
      DateTime(now.year, now.month + 1, 1),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Tự động nhận màu nền Sáng/Tối từ hệ thống
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, // Tự động nhận màu nền đồng bộ
        elevation: 0,
        // ĐÃ SỬA: Chuyển text button "Đóng" bị lỗi xuống dòng thành icon quay lại chuẩn UX
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: theme.cardColor, // Đổi màu hộp tiêu đề theo Theme Sáng/Tối
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.public, color: Colors.grey, size: 18),
              const SizedBox(width: 6),
              Text(
                "Chế độ: $_filterType",
                style: TextStyle(color: textColor, fontSize: 14),
              ),
              const Icon(Icons.unfold_more, color: Colors.grey, size: 16),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.calendar_today, color: textColor),
            onPressed: _showTimeFilterBottomSheet,
          ),
          IconButton(icon: Icon(Icons.help_outline, color: textColor), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // HIỂN THỊ ĐIỀU HƯỚNG THEO CHẾ ĐỘ LỌC
          if (_filterType == "Tháng")
            Container(
              height: 50,
              color: theme.scaffoldBackgroundColor,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _getMonthsList().map((monthDateTime) {
                  bool isSelected = monthDateTime.year == _selectedDate.year &&
                      monthDateTime.month == _selectedDate.month;
                  String label = (monthDateTime.month == DateTime.now().month) ? "THÁNG NÀY" :
                  (monthDateTime.month == DateTime.now().month - 1) ? "THÁNG TRƯỚC" :
                  DateFormat('MM/yyyy').format(monthDateTime);

                  Color currentTextColor = isSelected
                      ? (textColor ?? Colors.white)
                      : Colors.grey;

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = monthDateTime),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                              color: currentTextColor,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          height: 2,
                          width: 60,
                          color: isSelected ? currentTextColor : Colors.transparent,
                        )
                      ],
                    ),
                  );
                }).toList(),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: theme.cardColor, // Tự động chuyển màu nền thanh điều hướng (Sáng/Tối)
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: textColor),
                    onPressed: _filterType == "Tất cả" || _filterType == "Tùy chỉnh" ? null : () {
                      setState(() {
                        if (_filterType == "Ngày") _selectedDate = _selectedDate.subtract(const Duration(days: 1));
                        if (_filterType == "Tuần") _selectedDate = _selectedDate.subtract(const Duration(days: 7));
                        if (_filterType == "Quý") _selectedDate = DateTime(_selectedDate.year, _selectedDate.month - 3, 1);
                        if (_filterType == "Năm") _selectedDate = DateTime(_selectedDate.year - 1, _selectedDate.month, 1);
                      });
                    },
                  ),
                  Text(
                    _getFilterSubTitle(),
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: textColor),
                    onPressed: _filterType == "Tất cả" || _filterType == "Tùy chỉnh" ? null : () {
                      setState(() {
                        if (_filterType == "Ngày") _selectedDate = _selectedDate.add(const Duration(days: 1));
                        if (_filterType == "Tuần") _selectedDate = _selectedDate.add(const Duration(days: 7));
                        if (_filterType == "Quý") _selectedDate = DateTime(_selectedDate.year, _selectedDate.month + 3, 1);
                        if (_filterType == "Năm") _selectedDate = DateTime(_selectedDate.year + 1, _selectedDate.month, 1);
                      });
                    },
                  ),
                ],
              ),
            ),

          // STREAMBUILDER KẾT NỐI DATA FIREBASE HỖ TRỢ BỘ LỌC ĐA NĂNG
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(widget.userId)
                  .collection('transactions')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.green));
                }

                double totalIncome = 0;
                double totalExpense = 0;
                Map<String, double> incomeCategoryData = {};
                Map<String, double> expenseCategoryData = {};

                if (snapshot.hasData) {
                  for (var doc in snapshot.data!.docs) {
                    final data = doc.data() as Map<String, dynamic>;

                    DateTime date = DateTime.now();
                    if (data['date'] != null) {
                      if (data['date'] is Timestamp) {
                        date = (data['date'] as Timestamp).toDate();
                      } else if (data['date'] is String) {
                        date = DateTime.parse(data['date']);
                      }
                    }

                    if (_checkFilterCondition(date)) {
                      double amount = (data['amount'] ?? 0).toDouble();
                      String category = data['category'] ?? 'Khác';

                      if (amount > 0) {
                        totalIncome += amount;
                        incomeCategoryData[category] = (incomeCategoryData[category] ?? 0) + amount;
                      } else {
                        totalExpense += amount.abs();
                        expenseCategoryData[category] = (expenseCategoryData[category] ?? 0) + amount.abs();
                      }
                    }
                  }
                }

                double netIncome = totalIncome - totalExpense;
                double maxBarWidth = MediaQuery.of(context).size.width - 64;
                double incomeWidth = totalIncome + totalExpense > 0 ? (totalIncome / (totalIncome + totalExpense)) * maxBarWidth : 0;
                double expenseWidth = totalIncome + totalExpense > 0 ? (totalExpense / (totalIncome + totalExpense)) * maxBarWidth : 0;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Số dư đầu", style: TextStyle(color: Colors.grey)),
                          Text(currencyFormat.format(0), style: TextStyle(color: textColor)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Số dư cuối", style: TextStyle(color: Colors.grey)),
                          Text(currencyFormat.format(netIncome), style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const Divider(color: Colors.grey, height: 32),

                      // Khối Thu Nhập Ròng
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: theme.cardColor, // Hộp bo góc đổi màu nền tự động theo hệ thống
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text("Thu nhập ròng", style: TextStyle(color: textColor, fontSize: 16)),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "${netIncome >= 0 ? '+' : ''}${currencyFormat.format(netIncome)}",
                              style: TextStyle(color: netIncome >= 0 ? Colors.green : Colors.red, fontSize: 20, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 16),
                            Text(currencyFormat.format(totalIncome), style: const TextStyle(color: Colors.blue)),
                            const SizedBox(height: 4),
                            Container(height: 12, width: incomeWidth > 10 ? incomeWidth : 10, decoration: BoxDecoration(color: Colors.blue, borderRadius: BorderRadius.circular(4))),
                            const SizedBox(height: 16),
                            Text(currencyFormat.format(totalExpense), style: const TextStyle(color: Colors.red)),
                            const SizedBox(height: 4),
                            Container(height: 12, width: expenseWidth > 10 ? expenseWidth : 10, decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(4))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Phần Biểu Đồ Tròn
                      Text(
                        "Báo cáo theo nhóm",
                        style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          // Truyền đầy đủ các thông số thời gian sang màn hình phân tích Khoản Thu
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                var range = _getFilterRange();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionTypeReportScreen(
                                      userId: widget.userId,
                                      isIncome: true,
                                      startDate: range["start"],
                                      endDate: range["end"],
                                      titlePeriod: range["title"],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor, // Đổi màu tự động theo theme
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Khoản thu", style: TextStyle(color: Colors.grey)),
                                    Text(currencyFormat.format(totalIncome), style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Truyền đầy đủ các thông số thời gian sang màn hình phân tích Khoản Chi
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                var range = _getFilterRange();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TransactionTypeReportScreen(
                                      userId: widget.userId,
                                      isIncome: false,
                                      startDate: range["start"],
                                      endDate: range["end"],
                                      titlePeriod: range["title"],
                                    ),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: theme.cardColor, // Đổi màu tự động theo theme
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text("Khoản chi", style: TextStyle(color: Colors.grey)),
                                    Text(currencyFormat.format(totalExpense), style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      if (incomeCategoryData.isNotEmpty || expenseCategoryData.isNotEmpty)
                        Container(
                          height: 180,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: theme.cardColor, // Đổi màu tự động theo theme
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              if (incomeCategoryData.isNotEmpty) _buildPieChart("Thu", incomeCategoryData, Colors.blue, textColor),
                              if (expenseCategoryData.isNotEmpty) _buildPieChart("Chi", expenseCategoryData, Colors.red, textColor),
                            ],
                          ),
                        )
                      else
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Text("Không có dữ liệu trong khoảng thời gian này", style: TextStyle(color: Colors.grey)),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPieChart(String title, Map<String, double> data, Color baseColor, Color? textColor) {
    List<PieChartSectionData> sections = [];
    double total = data.values.fold(0, (sum, val) => sum + val);
    int index = 0;

    data.forEach((key, val) {
      sections.add(PieChartSectionData(
        color: baseColor.withOpacity(1.0 - (index * 0.2).clamp(0.0, 0.6)),
        value: val,
        title: '${((val / total) * 100).toStringAsFixed(0)}%',
        radius: 30,
        titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
      ));
      index++;
    });

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(width: 100, height: 100, child: PieChart(PieChartData(sectionsSpace: 2, centerSpaceRadius: 22, sections: sections))),
        Text(title, style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 12)),
      ],
    );
  }
}