import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'Controllers/language_provider.dart';
import 'Views/onboarding_screen.dart';
import 'Views/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      initialRoute: '/',
      routes: {
        '/': (context) => const RootHandler(),
        '/login': (context) => const LoginScreen(),
      },
    );
  }
}

class RootHandler extends StatelessWidget {
  const RootHandler({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return OnboardingScreen();
        }
        return OnboardingScreen();
      },
    );
  }
}