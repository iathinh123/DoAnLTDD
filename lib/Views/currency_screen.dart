import 'package:flutter/material.dart';
import '../Controllers/currency_service.dart';

class CurrencyScreen extends StatefulWidget {
  @override
  _CurrencyScreenState createState() => _CurrencyScreenState();
}

class _CurrencyScreenState extends State<CurrencyScreen> {
  String selectedCurrency = "VND";

  @override
  void initState() {
    super.initState();
    loadCurrency();
  }

  void loadCurrency() async {
    selectedCurrency = await CurrencyService.getCurrency();
    setState(() {});
  }

  void saveCurrency() async {
    await CurrencyService.setCurrency(selectedCurrency);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Chọn tiền tệ")),
      body: Column(
        children: [
          ListTile(
            title: Text("VND"),
            leading: Radio(
              value: "VND",
              groupValue: selectedCurrency,
              onChanged: (value) {
                setState(() {
                  selectedCurrency = value!;
                });
              },
            ),
          ),
          ListTile(
            title: Text("USD"),
            leading: Radio(
              value: "USD",
              groupValue: selectedCurrency,
              onChanged: (value) {
                setState(() {
                  selectedCurrency = value!;
                });
              },
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: saveCurrency,
            child: Text("Tiếp tục"),
          )
        ],
      ),
    );
  }
}