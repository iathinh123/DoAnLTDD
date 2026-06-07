import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../Controllers/language_provider.dart';
import 'login_screen.dart';
import 'register_screen.dart';

const Color moneyLoverGreen = Color(0xFF2DB15D);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  List<Map<String, dynamic>> getOnboardingData(LanguageProvider lang) {
    return [
      {
        "title": lang.getText("ob_title_1"),
        "icon": Icons.content_cut_rounded,
        "color": Colors.orangeAccent,
      },
      {
        "title": lang.getText("ob_title_2"),
        "icon": Icons.savings_rounded,
        "color": moneyLoverGreen,
      },
      {
        "title": lang.getText("ob_title_3"),
        "icon": Icons.account_balance_wallet_rounded,
        "color": Colors.lightBlueAccent,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final onboardingData = getOnboardingData(lang);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leadingWidth: 200,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Row(
            children: [
              const Icon(Icons.account_balance_wallet_rounded, color: moneyLoverGreen, size: 28),
              const SizedBox(width: 8),
              Text(
                "Wallet",
                style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 1),
              ),
            ],
          ),
        ),
        actions: [
          _buildLanguageButton(lang),
          const SizedBox(width: 20),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: size.height * 0.02),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (value) => setState(() => _currentPage = value),
                itemCount: onboardingData.length,
                itemBuilder: (context, index) => _buildPageContent(
                  size,
                  onboardingData[index]["title"]!,
                  onboardingData[index]["icon"]!,
                  onboardingData[index]["color"]!,
                ),
              ),
            ),
            _buildDotsIndicator(onboardingData.length),
            SizedBox(height: size.height * 0.05),
            _buildActionButtons(lang),
            _buildVersionFooter(),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageButton(LanguageProvider lang) {
    return PopupMenuButton<String>(
      color: Theme.of(context).cardColor,
      onSelected: (value) => lang.changeLanguage(value),
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: "vi",
          child: Row(
            children: [
              const Icon(Icons.language, color: moneyLoverGreen, size: 18),
              const SizedBox(width: 10),
              Text("Tiếng Việt", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        ),
        PopupMenuItem(
          value: "en",
          child: Row(
            children: [
              const Icon(Icons.language, color: moneyLoverGreen, size: 18),
              const SizedBox(width: 10),
              Text("English", style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color)),
            ],
          ),
        ),
      ],
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
        ),
        child: Row(
          children: [
            const Icon(Icons.language_rounded, color: moneyLoverGreen, size: 18),
            const SizedBox(width: 6),
            Text(
              lang.languageCode == 'vi' ? "TIẾNG VIỆT" : "ENGLISH",
              style: TextStyle(color: Theme.of(context).textTheme.bodyMedium?.color, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            Icon(Icons.arrow_drop_down, color: Theme.of(context).textTheme.bodySmall?.color, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPageContent(Size size, String title, IconData icon, Color iconColor) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 45),
        child: Column(
          children: [
            Container(
              height: size.height * 0.35,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withOpacity(0.05)),
              ),
              child: Icon(
                icon,
                size: 150,
                color: iconColor.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 40),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                color: Theme.of(context).textTheme.bodyMedium?.color,
                fontWeight: FontWeight.bold,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDotsIndicator(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        count,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.symmetric(horizontal: 6),
          height: 8,
          width: _currentPage == index ? 20 : 8,
          decoration: BoxDecoration(
            color: _currentPage == index ? moneyLoverGreen : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(LanguageProvider lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 55,
            child: ElevatedButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const RegisterScreen())),
              style: ElevatedButton.styleFrom(
                backgroundColor: moneyLoverGreen,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: Text(
                lang.getText("register").toUpperCase(),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextButton(
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const LoginScreen())),
            child: Text(
              lang.getText("login").toUpperCase(),
              style: const TextStyle(color: moneyLoverGreen, fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVersionFooter() {
    return const Text(
      "Phiên bản 1.0.0 (Wallet)",
      style: TextStyle(color: Colors.grey, fontSize: 12),
    );
  }
}