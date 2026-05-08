import 'package:shared_preferences/shared_preferences.dart';

class SearchService {
  static const String _historyKey = 'search_history';

  // Lưu lịch sử
  static Future<void> saveHistory(String query) async {
    final prefs = await SharedPreferences.getInstance();
    List<String> history = prefs.getStringList(_historyKey) ?? [];
    if (!history.contains(query)) {
      history.insert(0, query); // Thêm lên đầu
      if (history.length > 10) history.removeLast(); // Giới hạn 10 mục
      await prefs.setStringList(_historyKey, history);
    }
  }

  // Lấy lịch sử
  static Future<List<String>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_historyKey) ?? [];
  }

  // Xóa lịch sử
  static Future<void> clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_historyKey);
  }
}