import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {

  static const String apiKey = "AIzaSyC1X-szcsThwq4pWp46sEHI-2MTzXnY8xw";
  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=";

  static Future<Map<String, dynamic>?> analyzeTransaction(
      String text,
      List<String> expenseCategories,
      List<String> incomeCategories,
      List<String> debtCategories,
      List<String> userCategories,
      ) async {

    List<String> allCategories = [
      ...expenseCategories,
      ...incomeCategories,
      ...debtCategories,
      ...userCategories,
    ];

    String categoryText = allCategories.map((e) => "- $e").join("\n");

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là AI phân tích giao dịch tài chính cá nhân.

Nhiệm vụ:
- Hiểu nội dung người dùng nhập
- Xác định: type, category, amount

Các loại:
- expense = khoản chi
- income = khoản thu
- debt = vay/nợ

Danh sách category hiện có:
$categoryText

QUY TẮC:
- Người dùng có thể gõ không dấu hoặc viết tắt
- Nếu nội dung khớp với category có sẵn (kể cả không dấu) → PHẢI dùng category đó, KHÔNG tạo mới
- Ví dụ: "cuoc dien thoai" → dùng "Cước điện thoại" nếu đã có trong danh sách
- Ví dụ: "an com" → dùng "Ăn uống" nếu đã có trong danh sách
- Nếu THẬT SỰ không có category phù hợp → đề xuất tên nhóm mới, thêm "isNewCategory": true
- Nếu nội dung KHÔNG phải giao dịch (là câu hỏi) → trả về null
- Chỉ trả về JSON, không giải thích

Ví dụ output (dùng category có sẵn):
{"type":"expense","category":"Ăn uống","amount":50000,"isNewCategory":false}

Ví dụ output (tạo nhóm mới):
{"type":"expense","category":"Cước 5G","amount":70000,"isNewCategory":true}

Ví dụ output (không phải giao dịch):
null

Nội dung:
$text
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];
      rawText = rawText
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      if (rawText == "null") return null;

      return jsonDecode(rawText);

    } catch (e) {
      print("analyzeTransaction ERROR: $e");
      return null;
    }
  }

  static Future<String> askAI(String message) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là trợ lý AI tài chính cá nhân.

Hãy:
- trả lời ngắn gọn
- dễ hiểu
- bằng tiếng Việt
- thân thiện
- đưa lời khuyên tài chính hợp lý

Câu hỏi:
$message
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return "Lỗi ${response.statusCode}";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<String> askAIWithHistory(
      List<Map<String, dynamic>> history) async {

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "system_instruction": {
            "parts": [
              {
                "text": "Bạn là trợ lý AI tài chính cá nhân. Trả lời ngắn gọn, dễ hiểu, bằng tiếng Việt, thân thiện. Khi được cung cấp dữ liệu tài chính thực tế, hãy dùng đúng số liệu đó để trả lời."
              }
            ]
          },
          "contents": history,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return "Lỗi ${response.statusCode}";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<String> analyzeMonthlySpending(
      String financialContext) async {

    try {
      final response = await http.post(
        Uri.parse("$_baseUrl$apiKey"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là chuyên gia tài chính cá nhân.

$financialContext

Hãy phân tích và đưa ra:
1. Nhận xét tổng quan tình hình tài chính
2. Nhóm chi tiêu nhiều nhất và lời khuyên
3. Điểm tích cực cần duy trì
4. 3 gợi ý cụ thể để cải thiện

Trả lời bằng tiếng Việt, ngắn gọn, thân thiện, dùng emoji.
"""
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return "Lỗi ${response.statusCode}";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}