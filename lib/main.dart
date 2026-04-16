import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Controllers/language_provider.dart';
import 'Views/onboarding_screen.dart';
import 'package:firebase_core/firebase_core.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  final langProvider = LanguageProvider();
  await langProvider.loadLanguage();

  runApp(
    ChangeNotifierProvider(
      create: (_) => langProvider,
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: OnboardingScreen (),
    );
  }
}