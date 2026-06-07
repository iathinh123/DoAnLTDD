import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class ExpenseChart extends StatefulWidget {
  final List<TransactionModel> transactions;

  const ExpenseChart({super.key, required this.transactions});

  @override
  State<ExpenseChart> createState() => _ExpenseChartState();
}

class _ExpenseChartState extends State<ExpenseChart> {
  int weekOffset = 0; // 0 = tuần này, -1 = tuần trước, -2 = 2 tuần trước...
  double _dragStartX = 0;

  Map<int, double> getWeeklyData(int offset) {
    Map<int, double> data = {for (int i = 1; i <= 7; i++) i: 0};
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1 - offset * 7));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 7));

    for (var t in widget.transactions) {
      if (t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1))) &&
          t.date.isBefore(endOfWeek)) {
        int day = t.date.weekday;
        data[day] = data[day]! + t.amount;
      }
    }
    return data;
  }

  String getWeekLabel(int offset) {
    if (offset == 0) return "Tuần này";
    if (offset == -1) return "Tuần trước";

    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(
        Duration(days: now.weekday - 1 - offset * 7));
    DateTime endOfWeek = startOfWeek.add(const Duration(days: 6));

    return "${startOfWeek.day}/${startOfWeek.month} - ${endOfWeek.day}/${endOfWeek.month}";
  }

  @override
  Widget build(BuildContext context) {
    final weekly = getWeeklyData(weekOffset);

    double maxPositive = weekly.values.where((e) => e > 0).fold(0.0, (a, b) => a > b ? a : b);
    double maxNegative = weekly.values.where((e) => e < 0).map((e) => e.abs()).fold(0.0, (a, b) => a > b ? a : b);
    double maxVal = [maxPositive, maxNegative].reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) maxVal = 100000;

    return GestureDetector(
      onHorizontalDragStart: (details) {
        _dragStartX = details.localPosition.dx;
      },
      onHorizontalDragEnd: (details) {
        final diff = details.velocity.pixelsPerSecond.dx;
        if (diff > 200) {
          // Kéo phải → tuần trước
          setState(() => weekOffset--);
        } else if (diff < -200) {
          // Kéo trái → tuần sau (không vượt tuần hiện tại)
          if (weekOffset < 0) setState(() => weekOffset++);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Chi tiêu theo tuần",
                  style: TextStyle(
                      color: Theme.of(context).textTheme.bodyMedium?.color,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    _legendDot(Colors.redAccent, "Chi"),
                    const SizedBox(width: 12),
                    _legendDot(Colors.greenAccent, "Thu"),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Week selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left, color: Colors.grey),
                  onPressed: () => setState(() => weekOffset--),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 8),
                Text(
                  getWeekLabel(weekOffset),
                  style: TextStyle(
                    color: weekOffset == 0 ? Colors.green : Colors.grey,
                    fontSize: 13,
                    fontWeight: weekOffset == 0
                        ? FontWeight.bold
                        : FontWeight.normal,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    Icons.chevron_right,
                    color: weekOffset < 0 ? Colors.grey : Colors.grey.withOpacity(0.3),
                  ),
                  onPressed: weekOffset < 0
                      ? () => setState(() => weekOffset++)
                      : null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Chart
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  maxY: maxPositive > 0 ? maxPositive * 1.4 : maxVal * 0.3,
                  minY: maxNegative > 0 ? -maxNegative * 1.4 : -maxVal * 0.3,
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: maxVal / 3,
                    getDrawingHorizontalLine: (value) => FlLine(
                      color: Theme.of(context).dividerColor.withOpacity(0.3),
                      strokeWidth: 1,
                    ),
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (group) => Theme.of(context).colorScheme.surfaceVariant,
                      tooltipRoundedRadius: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
                        final day = days[group.x - 1];
                        final amount = rod.toY;
                        final formatted = amount.abs() >= 1000000
                            ? "${(amount.abs() / 1000000).toStringAsFixed(1)}M"
                            : "${(amount.abs() / 1000).toStringAsFixed(0)}K";
                        return BarTooltipItem(
                          "$day\n${amount >= 0 ? '+' : '-'}$formatted đ",
                          TextStyle(
                            color: amount >= 0
                                ? Colors.greenAccent
                                : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 45,
                        getTitlesWidget: (value, meta) {
                          if (value == 0) {
                            return const Text("0",
                                style: TextStyle(
                                    color: Colors.grey, fontSize: 10));
                          }
                          final abs = value.abs();
                          String label;
                          if (abs >= 1000000) {
                            label = "${(abs / 1000000).toStringAsFixed(1)}M";
                          } else {
                            label = "${(abs / 1000).toStringAsFixed(0)}K";
                          }
                          return Text(
                            value < 0 ? "-$label" : label,
                            style: const TextStyle(
                                color: Colors.grey, fontSize: 9),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
                          int index = value.toInt() - 1;
                          if (index < 0 || index >= days.length) {
                            return const SizedBox();
                          }
                          final isToday = weekOffset == 0 &&
                              value.toInt() == DateTime.now().weekday;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              days[index],
                              style: TextStyle(
                                color: isToday ? Theme.of(context).textTheme.bodyMedium?.color : Colors.grey,
                                fontSize: 11,
                                fontWeight: isToday
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: weekly.entries.map((e) {
                    final isToday = weekOffset == 0 &&
                        e.key == DateTime.now().weekday;
                    final isPositive = e.value >= 0;
                    final isEmpty = e.value == 0;

                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: isEmpty ? 0.01 : e.value,
                          width: 18,
                          borderRadius: e.value >= 0
                              ? const BorderRadius.vertical(
                              top: Radius.circular(6))
                              : const BorderRadius.vertical(
                              bottom: Radius.circular(6)),
                          gradient: isEmpty
                              ? null
                              : LinearGradient(
                            begin: isPositive
                                ? Alignment.bottomCenter
                                : Alignment.topCenter,
                            end: isPositive
                                ? Alignment.topCenter
                                : Alignment.bottomCenter,
                            colors: isPositive
                                ? [
                              Colors.green.withOpacity(0.6),
                              Colors.greenAccent,
                            ]
                                : [
                              Colors.red.withOpacity(0.6),
                              Colors.redAccent,
                            ],
                          ),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: isToday,
                            toY: maxPositive > 0 ? maxPositive * 1.4 : maxVal * 0.3,
                            fromY: maxNegative > 0 ? -maxNegative * 1.4 : -maxVal * 0.3,
                            color: Theme.of(context).dividerColor.withOpacity(0.3),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

            // Hint kéo
            const SizedBox(height: 8),
            Center(
              child: Text(
                "← Kéo hoặc bấm mũi tên để xem tuần trước →",
                style: TextStyle(
                    color: Colors.grey.withOpacity(0.5), fontSize: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}