import 'package:flutter/material.dart';
import '../Models/budget_model.dart';
import '../Controllers/budget_controller.dart';

class BudgetScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Tạm thời khởi tạo controller ngay tại đây để hiện dữ liệu
    final controller = BudgetController();

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text("Ngân sách"),
        backgroundColor: Colors.black,
      ),
      body: ListView.builder(
        padding: EdgeInsets.all(16),
        itemCount: controller.budgets.length,
        itemBuilder: (context, index) {
          final item = controller.budgets[index];
          return _buildBudgetCard(item);
        },
      ),
    );
  }

  Widget _buildBudgetCard(Budget budget) {
    double percent = budget.percent;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1E1E1E), // Màu xám tối nhẹ
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(children: [
                Icon(budget.icon, color: budget.color),
                SizedBox(width: 10),
                Text(budget.title, style: TextStyle(color: Colors.white, fontSize: 16)),
              ]),
              Text("${(percent * 100).toInt()}%", style: TextStyle(color: Colors.white)),
            ],
          ),
          SizedBox(height: 10),
          LinearProgressIndicator(
            value: percent > 1 ? 1 : percent,
            backgroundColor: Colors.grey[800],
            valueColor: AlwaysStoppedAnimation<Color>(percent > 1 ? Colors.red : budget.color),
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("Đã tiêu: ${budget.spent.toInt()}đ", style: TextStyle(color: Colors.grey)),
              Text("Hạn mức: ${budget.limit.toInt()}đ", style: TextStyle(color: Colors.grey)),
            ],
          )
        ],
      ),
    );
  }
}