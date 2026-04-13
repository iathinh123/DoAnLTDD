import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = "vi";

  String get languageCode => _languageCode;

  Map<String, Map<String, String>> translations = {
    "vi": {
      "login": "Đăng nhập",
      "register": "Đăng ký",
      "email": "Email",
      "password": "Mật khẩu",
      "forgot": "Quên mật khẩu?",
      "google": "Đăng nhập bằng Google",
    },
    "en": {
      "login": "Login",
      "register": "Register",
      "email": "Email",
      "password": "Password",
      "forgot": "Forgot Password?",
      "google": "Login with Google",
    }
  };

  String getText(String key) {
    return translations[_languageCode]![key] ?? key;
  }

  Future changeLanguage(String code) async {
    _languageCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", code);

    notifyListeners();
  }

  Future loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString("lang") ?? "vi";
    notifyListeners();
  }
}