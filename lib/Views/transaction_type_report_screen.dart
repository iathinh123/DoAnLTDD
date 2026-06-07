import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionTypeReportScreen extends StatefulWidget {
  final String userId;
  final bool isIncome;        // true: Thu, false: Chi
  final DateTime startDate;   // Ngày bắt đầu của khoảng lọc
  final DateTime endDate;     // Ngày kết thúc của khoảng lọc
  final String titlePeriod;   // Tiêu đề hiển thị (Ví dụ: "Hôm nay", "Tuần này", "Quý 2/2026")

  const TransactionTypeReportScreen({
    Key? key,
    required this.userId,
    required this.isIncome,
    required this.startDate,
    required this.endDate,
    required this.titlePeriod,
  }) : super(key: key);

  @override
  State<TransactionTypeReportScreen> createState() => _TransactionTypeReportScreenState();
}

class _TransactionTypeReportScreenState extends State<TransactionTypeReportScreen> {
  final currencyFormat = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late String screenTitle;

  final List<Color> colorPalette = [
    const Color(0xFF2ecc71),
    const Color(0xFF3498db),
    const Color(0xFF9b59b6),
    const Color(0xFFf1c40f),
    const Color(0xFFe67e22),
    const Color(0xFF1abc9c),
    const Color(0xFFe74c3c),
    const Color(0xFFe84393),
  ];

  IconData _getCategoryIcon(String category) {
    String lower = category.toLowerCase().trim();
    if (lower.contains('ăn') || lower.contains('uống') || lower.contains('food')) return Icons.restaurant;
    if (lower.contains('xe') || lower.contains('di chuyển') || lower.contains('xăng')) return Icons.directions_car;
    if (lower.contains('nhà') || lower.contains('phòng') || lower.contains('điện')) return Icons.home;
    if (lower.contains('lương') || lower.contains('thu nhập')) return Icons.attach_money;
    if (lower.contains('mua sắm') || lower.contains('shopping')) return Icons.shopping_bag;
    if (lower.contains('giải trí') || lower.contains('phim') || lower.contains('game')) return Icons.movie;
    return Icons.category;
  }

  @override
  void initState() {
    super.initState();
    screenTitle = widget.isIncome ? "Phân tích Khoản Thu" : "Phân tích Khoản Chi";
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textColor = theme.textTheme.bodyLarge?.color;

    // Chuẩn hóa startDate về 00:00:00 và endDate về 23:59:59 để lọc không sót giao dịch trong ngày
    final start = DateTime(widget.startDate.year, widget.startDate.month, widget.startDate.day, 0, 0, 0);
    final end = DateTime(widget.endDate.year, widget.endDate.month, widget.endDate.day, 23, 59, 59);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ nền động sáng tối
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor, // Đồng bộ nền AppBar động
        elevation: 0,
        title: Text(
            screenTitle,
            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold)
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(widget.userId)
            .collection('transactions')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Colors.green));
          }

          double totalAmount = 0;
          Map<String, double> categoryMap = {};

          // Dùng Map động để lưu xu hướng thời gian linh hoạt (theo ngày hoặc theo tháng tùy khoảng lọc rộng/hẹp)
          Map<int, double> trendMap = {};

          if (snapshot.hasData) {
            for (var doc in snapshot.data!.docs) {
              final data = doc.data() as Map<String, dynamic>;
              double amount = (data['amount'] ?? 0).toDouble();
              String category = data['category'] ?? 'Khác';

              DateTime date = DateTime.now();
              if (data['date'] != null) {
                if (data['date'] is Timestamp) date = (data['date'] as Timestamp).toDate();
                else if (data['date'] is String) date = DateTime.parse(data['date']);
              }

              // Kiểm tra giao dịch nằm TRONG khoảng start và end (Lọc được cả ngày, tuần, quý, năm)
              if (date.isAfter(start.subtract(const Duration(seconds: 1))) &&
                  date.isBefore(end.add(const Duration(seconds: 1)))) {

                if ((widget.isIncome && amount > 0) || (!widget.isIncome && amount < 0)) {
                  double value = amount.abs();
                  totalAmount += value;
                  categoryMap[category] = (categoryMap[category] ?? 0) + value;

                  // Thống kê xu hướng:
                  // Nếu khoảng lọc > 90 ngày (như lọc cả Năm), gom xu hướng theo Tháng (1-12).
                  // Ngược lại (Ngày, Tuần, Tháng, Quý), gom xu hướng theo Ngày trong tháng (1-31).
                  int timeKey = (end.difference(start).inDays > 90) ? date.month : date.day;
                  trendMap[timeKey] = (trendMap[timeKey] ?? 0) + value;
                }
              }
            }
          }

          if (totalAmount == 0) {
            return Center(
                child: Text(
                    "Không có dữ liệu trong khoảng (${widget.titlePeriod})",
                    style: const TextStyle(color: Colors.grey, fontSize: 15)
                )
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hiển thị tiêu đề khoảng thời gian động lựa chọn bên bộ lọc
                Center(
                  child: Column(
                    children: [
                      Text(
                        widget.isIncome
                            ? "Tổng thu nhập (${widget.titlePeriod})"
                            : "Tổng chi tiêu (${widget.titlePeriod})",
                        style: const TextStyle(color: Colors.grey, fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        currencyFormat.format(totalAmount),
                        style: TextStyle(
                            color: widget.isIncome ? const Color(0xFF3498db) : const Color(0xFFe74c3c),
                            fontSize: 26,
                            fontWeight: FontWeight.bold
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                Container(
                  height: 260,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 4,
                      centerSpaceRadius: 55,
                      sections: _generatePieSections(categoryMap, totalAmount),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                Text(
                    "Xu hướng thời gian",
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                Container(
                  height: 210, // Tăng nhẹ chiều cao để tooltip hiển thị thoải mái hơn
                  padding: const EdgeInsets.only(right: 24, top: 24, bottom: 8, left: 8),
                  decoration: BoxDecoration(
                      color: theme.cardColor, // Đồng bộ nền hộp đồ thị xu hướng theo sáng tối
                      borderRadius: BorderRadius.circular(16)
                  ),
                  child: LineChart(
                    _getLineChartData(trendMap, end.difference(start).inDays > 90, theme),
                  ),
                ),
                const SizedBox(height: 28),

                Text(
                    "Chi tiết danh mục",
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                      color: theme.cardColor, // Đồng bộ màu nền khối danh mục theo sáng tối
                      borderRadius: BorderRadius.circular(16)
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryMap.length,
                    separatorBuilder: (_, __) => Divider(color: theme.dividerColor, height: 1),
                    itemBuilder: (context, index) {
                      String category = categoryMap.keys.elementAt(index);
                      double amount = categoryMap.values.elementAt(index);
                      double percent = (amount / totalAmount) * 100;
                      Color itemColor = colorPalette[index % colorPalette.length];

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: itemColor.withOpacity(0.15),
                          child: Icon(_getCategoryIcon(category), color: itemColor, size: 20),
                        ),
                        title: Text(
                            category,
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 14)
                        ),
                        subtitle: Text("${percent.toStringAsFixed(1)}%", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                        trailing: Text(
                            currencyFormat.format(amount),
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 15)
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<PieChartSectionData> _generatePieSections(Map<String, double> data, double total) {
    List<PieChartSectionData> sections = [];
    int index = 0;

    data.forEach((category, value) {
      final percentage = (value / total) * 100;
      final color = colorPalette[index % colorPalette.length];
      final icon = _getCategoryIcon(category);

      sections.add(PieChartSectionData(
        color: color,
        value: value,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 38,
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
        badgeWidget: _buildBadgeIcon(icon, color),
        badgePositionPercentageOffset: 1.65,
      ));
      index++;
    });
    return sections;
  }

  Widget _buildBadgeIcon(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor, // Thay màu cố định bằng nền động hệ thống
          shape: BoxShape.circle,
          border: Border.all(color: color, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))
          ]
      ),
      child: Icon(icon, color: Theme.of(context).textTheme.bodyLarge?.color, size: 15),
    );
  }

  LineChartData _getLineChartData(Map<int, double> trendData, bool isYearly, ThemeData theme) {
    List<FlSpot> spots = [];
    double maxAmount = 0;
    int maxLimit = isYearly ? 12 : 31;

    for (int i = 1; i <= maxLimit; i++) {
      double val = trendData[i] ?? 0;
      spots.add(FlSpot(i.toDouble(), val));
      if (val > maxAmount) maxAmount = val;
    }

    if (maxAmount == 0) maxAmount = 100000;
    double maxY = maxAmount * 1.25;

    final mainColor = widget.isIncome ? const Color(0xFF3498db) : const Color(0xFFe74c3c);

    return LineChartData(
      minX: 1,
      maxX: maxLimit.toDouble(),
      minY: 0,
      maxY: maxY,
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (touchedSpot) => theme.colorScheme.inverseSurface, // Nghịch đảo màu nền tooltip để nổi bật theo theme
          tooltipRoundedRadius: 8,
          getTooltipItems: (List<LineBarSpot> touchedSpots) {
            return touchedSpots.map((barSpot) {
              String timeLabel = isYearly ? 'Tháng ${barSpot.x.toInt()}' : 'Ngày ${barSpot.x.toInt()}';
              return LineTooltipItem(
                '$timeLabel\n${currencyFormat.format(barSpot.y)}',
                TextStyle(color: theme.colorScheme.onInverseSurface, fontWeight: FontWeight.bold, fontSize: 11),
              );
            }).toList();
          },
        ),
      ),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        horizontalInterval: maxY / 4,
        getDrawingHorizontalLine: (value) => FlLine(color: theme.dividerColor.withOpacity(0.4), strokeWidth: 0.5),
      ),
      titlesData: FlTitlesData(
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 45,
            interval: maxY / 4,
            getTitlesWidget: (value, meta) {
              if (value == 0) return const Text('0', style: TextStyle(color: Colors.grey, fontSize: 10));
              if (value >= 1000000) return Text('${(value / 1000000).toStringAsFixed(1)}M', style: const TextStyle(color: Colors.grey, fontSize: 10));
              if (value >= 1000) return Text('${(value / 1000).toStringAsFixed(0)}K', style: const TextStyle(color: Colors.grey, fontSize: 10));
              return Text('${value.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 10));
            },
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 22,
            interval: isYearly ? 2 : 5,
            getTitlesWidget: (value, meta) {
              int intVal = value.toInt();
              if (intVal == maxLimit && intVal % (isYearly ? 2 : 5) != 0) {
                return const SizedBox.shrink();
              }

              String label = isYearly ? 'Th$intVal' : 'T$intVal';
              return Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10)),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.18,
          color: mainColor,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: spot.y > 0 ? 2.5 : 0,
                color: mainColor,
                strokeWidth: 1,
                strokeColor: theme.scaffoldBackgroundColor,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            gradient: LinearGradient(
              colors: [
                mainColor.withOpacity(0.25),
                mainColor.withOpacity(0.0),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ],
    );
  }
}