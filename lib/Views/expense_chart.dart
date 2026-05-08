import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpenseChart({super.key, required this.transactions});

  // ================= LỌC VÀ LẤY DỮ LIỆU THEO TUẦN HIỆN TẠI =================
  Map<int, double> getWeeklyData() {
    Map<int, double> data = {for (int i = 1; i <= 7; i++) i: 0};
    DateTime now = DateTime.now();
    DateTime startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    startOfWeek = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);

    for (var t in transactions) {
      if (t.date.isAfter(startOfWeek.subtract(const Duration(seconds: 1)))) {
        int day = t.date.weekday;
        data[day] = data[day]! + t.amount;
      }
    }
    return data;
  }

  // ================= LỌC VÀ LẤY DỮ LIỆU THEO THÁNG HIỆN TẠI =================
  Map<int, double> getMonthlyData() {
    Map<int, double> data = {for (int i = 1; i <= 12; i++) i: 0};
    DateTime now = DateTime.now();

    for (var t in transactions) {

      if (t.date.year == now.year) {
        int month = t.date.month;
        data[month] = data[month]! + t.amount;
      }
    }
    return data;
  }

  @override
  Widget build(BuildContext context) {
    final weekly = getWeeklyData();

    return SizedBox(
      height: 250,
      child: BarChart(
        BarChartData(
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: 200000,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white10,
              strokeWidth: 1,
            ),
          ),
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  if (value == 0) return const Text("0", style: TextStyle(color: Colors.grey, fontSize: 10));
                  return Text("${(value / 1000).toStringAsFixed(0)}K",
                      style: const TextStyle(color: Colors.grey, fontSize: 10));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
                  int index = value.toInt() - 1;
                  if (index < 0 || index >= days.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(days[index], style: const TextStyle(color: Colors.white, fontSize: 10)),
                  );
                },
              ),
            ),
          ),
          barGroups: weekly.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  // Màu đỏ cho số âm (Chi), Cyan cho số dương (Thu)
                  color: e.value >= 0 ? Colors.cyan : Colors.redAccent,
                  toY: e.value,
                  width: 14,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                    bottom: Radius.circular(4),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}