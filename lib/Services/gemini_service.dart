import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {

  static const String apiKey =
      "AQ.Ab8RN6IP1-i1DaTKWi0XFfV--3AmUdsTozjxJAua8fN5DM9Olg";

  static const String _baseUrl =
      "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.0-flash:generateContent?key=";

  static Future<http.Response?> _postWithRetry(
      String url,
      Map<String, dynamic> body,
      ) async {
    try {
      print("KEY = $apiKey");
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode(body),
      );

      print("================================");
      print("STATUS: ${response.statusCode}");
      print(response.body);
      print("================================");

      return response;
    } catch (e) {
      print("HTTP ERROR: $e");
      return null;
    }
  }

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
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
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
        },
      );

      if (response == null || response.statusCode != 200) return null;

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
      print("KEY = $apiKey");
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là trợ lý AI tài chính cá nhân.

QUY TẮC:
- Luôn trả lời bằng tiếng Việt.
- Thân thiện, ngắn gọn, dễ hiểu.
- Nếu câu hỏi liên quan đến tài chính, chi tiêu, tiết kiệm hoặc đầu tư thì trả lời trực tiếp.
- Nếu câu hỏi KHÔNG liên quan đến tài chính, vẫn trả lời bình thường nhưng phải khéo léo liên hệ đến quản lý chi tiêu, tiết kiệm hoặc tài chính cá nhân.
- Không bao giờ từ chối chỉ vì câu hỏi không thuộc lĩnh vực tài chính.
- Luôn cố gắng đưa ra một lời khuyên tài chính ngắn ở cuối câu trả lời nếu phù hợp.

Câu hỏi:
$message
"""
                }
              ]
            }
          ]
        },
      );

      if (response == null) {
        return " Không thể kết nối tới Gemini.";
      }

      if (response.statusCode == 429) {
        return "Đã vượt giới hạn Gemini miễn phí. Vui lòng đợi vài phút rồi thử lại.";
      }

      if (response.statusCode != 200) {
        return "Lỗi API (${response.statusCode})";
      }

      final data = jsonDecode(response.body);

      if (data["candidates"] == null ||
          data["candidates"].isEmpty) {
        return "Gemini không trả về dữ liệu.";
      }

      return data["candidates"][0]["content"]["parts"][0]["text"];
    } catch (e) {
      return "Lỗi: $e";
    }
  }

  static Future<String> askAIWithHistory(
      List<Map<String, dynamic>> history) async {

    try {
      print("KEY = $apiKey");
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
          "system_instruction": {
            "parts": [
              {
                "text": """
Bạn là trợ lý AI tài chính cá nhân.

Quy tắc:
- Luôn trả lời bằng tiếng Việt.
- Trả lời tự nhiên như một chatbot thông minh.
- Nếu câu hỏi liên quan đến tài chính thì trả lời đầy đủ.
- Nếu không liên quan đến tài chính thì vẫn trả lời bình thường, sau đó liên hệ nhẹ nhàng đến quản lý chi tiêu, tiết kiệm hoặc ngân sách cá nhân.
- Không được trả lời rằng bạn chỉ hỗ trợ tài chính.
- Giữ giọng điệu thân thiện và tích cực.
"""
              }
            ]
          },
          "contents": history,
        },
      );

      if (response == null) return "Server đang bận, thử lại sau!";
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
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
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
        },
      );

      if (response == null) return "Server đang bận, thử lại sau!";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return """
Status: ${response.statusCode}

${response.body}
""";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<String> analyzeSavingsGoal(
      String goalData, String financialData) async {
    try {
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là chuyên gia tài chính cá nhân.

$financialData

$goalData

Hãy:
1. Đánh giá khả năng đạt mục tiêu
2. Tính số tiền cần tiết kiệm mỗi tháng/tuần
3. Gợi ý cách đạt mục tiêu nhanh hơn
4. Động viên người dùng

Trả lời bằng tiếng Việt, ngắn gọn, thân thiện, dùng emoji.
"""
                }
              ]
            }
          ]
        },
      );

      if (response == null) return "Server đang bận, thử lại sau!";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return """
Status: ${response.statusCode}

${response.body}
""";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }

  static Future<String> predictEndOfMonth(
      String currentMonthData, String lastMonthData) async {
    try {
      final response = await _postWithRetry(
        "$_baseUrl$apiKey",
        {
          "contents": [
            {
              "parts": [
                {
                  "text": """
Bạn là chuyên gia tài chính cá nhân.

Dữ liệu tháng trước:
$lastMonthData

Dữ liệu tháng này (chưa kết thúc):
$currentMonthData

Hãy:
1. Dự đoán tổng chi tiêu cuối tháng này dựa trên xu hướng
2. So sánh với tháng trước (nhiều hơn hay ít hơn, bao nhiêu %)
3. Điểm cần chú ý
4. Lời khuyên cụ thể

Trả lời bằng tiếng Việt, ngắn gọn, dùng emoji.
"""
                }
              ]
            }
          ]
        },
      );

      if (response == null) return "Server đang bận, thử lại sau!";
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["candidates"][0]["content"]["parts"][0]["text"];
      }

      return """
Status: ${response.statusCode}

${response.body}
""";

    } catch (e) {
      return "Lỗi kết nối: $e";
    }
  }
}