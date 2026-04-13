import 'package:shared_preferences/shared_preferences.dart';

class CurrencyService {
  static const String key = "currency";

  static Future<void> setCurrency(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key) ?? "VND";
  }
}