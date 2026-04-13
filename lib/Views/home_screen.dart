import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int currentIndex = 0;

  double balance = -1000000; // test data
  double totalExpense = 1000000;
  double totalIncome = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,

      // ===== BODY =====
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ===== HEADER =====
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${balance.toStringAsFixed(2)} đ",
                        style: const TextStyle(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tổng số dư",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.remove_red_eye, color: Colors.white),
                      SizedBox(width: 12),
                      Icon(Icons.search, color: Colors.white),
                      SizedBox(width: 12),
                      Icon(Icons.notifications, color: Colors.white),
                    ],
                  )
                ],
              ),

              const SizedBox(height: 20),

              // ===== WALLET =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Ví của tôi",
                            style:
                            TextStyle(color: Colors.white, fontSize: 16)),
                        Text("Xem tất cả",
                            style:
                            TextStyle(color: Colors.green, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const CircleAvatar(
                          backgroundColor: Colors.orange,
                          child: Icon(Icons.account_balance_wallet),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Text("Tiền mặt",
                              style: TextStyle(color: Colors.white)),
                        ),
                        Text(
                          "${balance.toStringAsFixed(2)} đ",
                          style: const TextStyle(color: Colors.white),
                        )
                      ],
                    )
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ===== REPORT =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text("Báo cáo tháng này",
                            style:
                            TextStyle(color: Colors.white, fontSize: 16)),
                        Text("Xem báo cáo",
                            style:
                            TextStyle(color: Colors.green, fontSize: 14)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Expense / Income
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          children: [
                            const Text("Tổng đã chi",
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              totalExpense.toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.red, fontSize: 18),
                            )
                          ],
                        ),
                        Column(
                          children: [
                            const Text("Tổng thu",
                                style: TextStyle(color: Colors.grey)),
                            Text(
                              totalIncome.toStringAsFixed(2),
                              style: const TextStyle(
                                  color: Colors.blue, fontSize: 18),
                            )
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Fake chart box
                    Container(
                      height: 150,
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                      ),
                      child: const Center(
                        child: Text(
                          "Nhập giao dịch để xem báo cáo",
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 80),
            ],
          ),
        ),
      ),

      // ===== FLOAT BUTTON =====
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {},
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      // ===== BOTTOM NAV =====
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        backgroundColor: Colors.black,
        selectedItemColor: Colors.green,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Tổng quan"),
          BottomNavigationBarItem(
              icon: Icon(Icons.list), label: "Sổ giao dịch"),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: "Ngân sách"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Tài khoản"),
        ],
      ),
    );
  }
}