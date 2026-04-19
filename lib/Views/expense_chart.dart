import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';

class ExpenseChart extends StatelessWidget {
  final List<TransactionModel> transactions;

  const ExpenseChart({super.key, required this.transactions});

  // ================= THEO TUẦN =================
  Map<int, double> getWeeklyData() {
    Map<int, double> data = {
      for (int i = 1; i <= 7; i++) i: 0
    };

    for (var t in transactions) {
      // SỬA LẠI ĐIỀU KIỆN Ở ĐÂY
      if (t.type == 0 || (t.type == 2 && (t.category == "Trả nợ" || t.category == "Cho vay"))) {
        int day = t.date.weekday;
        data[day] = data[day]! + t.amount;
      }
    }
    return data;
  }

  // ================= THEO THÁNG =================
  Map<int, double> getMonthlyData() {
    Map<int, double> data = {
      for (int i = 1; i <= 12; i++) i: 0
    };

    for (var t in transactions) {
      // SỬA LẠI ĐIỀU KIỆN Ở ĐÂY
      if (t.type == 0 || (t.type == 2 && (t.category == "Trả nợ" || t.category == "Cho vay"))) {
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
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: true),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  const days = ["T2", "T3", "T4", "T5", "T6", "T7", "CN"];
                  return Text(days[value.toInt() - 1],
                      style: const TextStyle(color: Colors.white, fontSize: 10));
                },
              ),
            ),
          ),
          barGroups: weekly.entries.map((e) {
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  color: e.value > 0 ? Colors.cyan : Colors.red,
                  toY: e.value,
                  width: 12,
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}