import 'package:doanltdd/Views/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/language_provider.dart';
import '../models/transaction_model.dart';

const Color moneyLoverGreen = Color(0xFF2DB15D);
const Color darkBackground = Color(0xFF000000);
const Color surfaceColor = Color(0xFF1A1A1A);

class TransactionScreen extends StatefulWidget {
  const TransactionScreen({super.key, required List<TransactionModel> transactions});

  @override
  State<TransactionScreen> createState() => _TransactionScreenState();
}

class _TransactionScreenState extends State<TransactionScreen> {
  @override
  Widget build(BuildContext context) {

    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      backgroundColor: darkBackground,
      appBar: AppBar(
        backgroundColor: darkBackground,
        elevation: 0,
        leading: const Icon(Icons.help_outline, color: Colors.white70),
        title: InkWell(
          onTap: () {},
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.account_balance_wallet, color: moneyLoverGreen, size: 20),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Wallet", style: TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                  Text(lang.getText("total_balance") ?? "Tổng cộng", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                ],
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.white70),
            ],
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.search, color: Colors.white70), onPressed: () {}),
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white70), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          // Số dư
          _buildModernBalanceCard(),

          _buildTimeFilter(),

          // Thu chi
          _buildSummarySection(),

          const Divider(color: Colors.white10, height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              children: [
                _buildTransactionGroup(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Số dư
  Widget _buildModernBalanceCard() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              moneyLoverGreen.withOpacity(0.2),
              const Color(0xFF121212),
            ],
          ),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
          boxShadow: [
            BoxShadow(
              color: moneyLoverGreen.withOpacity(0.05),
              blurRadius: 20,
              spreadRadius: 1,
            )
          ]
      ),
      child: Column(
        children: [
          Text(
            "SỐ DƯ HIỆN TẠI",
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11, letterSpacing: 2, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          const Text(
            "-200,000 đ",
            style: TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeFilter() {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _timeTab("THÁNG TRƯỚC", false),
          _timeTab("THÁNG NÀY", true),
          _timeTab("TƯƠNG LAI", false),
        ],
      ),
    );
  }

  Widget _timeTab(String label, bool isSelected) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white38,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
        const SizedBox(height: 6),
        if (isSelected)
          Container(height: 2, width: 30, decoration: BoxDecoration(color: moneyLoverGreen, borderRadius: BorderRadius.circular(2))),
      ],
    );
  }

  // Thu chi
  Widget _buildSummarySection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          _rowAmount("Tiền vào", "0", Colors.blueAccent),
          const SizedBox(height: 12),
          _rowAmount("Tiền ra", "200,000", Colors.redAccent),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Colors.white10, thickness: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Text("-200,000", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 15),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: moneyLoverGreen.withOpacity(0.1),
                foregroundColor: moneyLoverGreen,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("XEM BÁO CÁO", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            ),
          )
        ],
      ),
    );
  }

  Widget _rowAmount(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(color: Colors.white54, fontSize: 13)),
        Text(value, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildTransactionGroup() {
    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text("13", style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Thứ Hai", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text("tháng 4 2026", style: TextStyle(color: Colors.white38, fontSize: 11)),
                  ],
                ),
                const Spacer(),
                const Text("-200,000", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Colors.white10, height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.orangeAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.restaurant, color: Colors.orangeAccent, size: 22),
            ),
            title: const Text("Ăn uống", style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
            subtitle: const Text("Ăn trưa ", style: TextStyle(color: Colors.white38, fontSize: 12)),
            trailing: const Text("200,000", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 15)),
          ),
        ],
      ),
    );
  }
}