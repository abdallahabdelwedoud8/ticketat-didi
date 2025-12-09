import 'package:flutter/material.dart';
import 'package:eventide/utils/constants.dart';
import 'package:eventide/screens/auth_screen.dart';
import 'package:eventide/services/language_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  String _languageCode = 'fr';

  @override
  void initState() {
    super.initState();
    _languageCode = LanguageService.getLanguage();
  }

  String _t(String key) => Languages.translate(key, _languageCode);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () => _pageController.previousPage(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: const Icon(Icons.arrow_back, color: AppConstants.primaryColor),
                    )
                  else
                    const SizedBox(width: 48),
                  Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.language, color: AppConstants.primaryColor, size: 20),
                          SizedBox(width: 6),
                          Text(
                            'Language',
                            style: TextStyle(fontSize: 12, color: AppConstants.greyColor, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppConstants.primaryColor, width: 1.5),
                        ),
                        child: DropdownButton<String>(
                          value: _languageCode,
                          underline: Container(),
                          isDense: true,
                          icon: const Icon(Icons.arrow_drop_down, color: AppConstants.primaryColor, size: 20),
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppConstants.textColor),
                          items: const [
                            DropdownMenuItem(
                              value: 'en',
                              child: Row(
                                children: [
                                  Text('🇬🇧', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('English'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'fr',
                              child: Row(
                                children: [
                                  Text('🇫🇷', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('Français'),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'ar',
                              child: Row(
                                children: [
                                  Text('🇲🇷', style: TextStyle(fontSize: 18)),
                                  SizedBox(width: 8),
                                  Text('العربية'),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) async {
                            if (value != null) {
                              await LanguageService.setLanguage(value);
                              setState(() => _languageCode = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AuthScreen()),
                    ),
                    child: Text(_t('skip'), style: const TextStyle(color: AppConstants.greyColor, fontSize: 16)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage(
                    icon: Icons.celebration,
                    title: _t('welcome'),
                    description: _t('tagline'),
                    color: AppConstants.primaryColor,
                  ),
                  _buildPage(
                    icon: Icons.qr_code_2,
                    title: _t('buy_store'),
                    description: _t('qr_instant'),
                    color: AppConstants.secondaryColor,
                  ),
                  _buildPage(
                    icon: Icons.analytics,
                    title: _t('organize_sponsor'),
                    description: _t('data_visibility'),
                    color: AppConstants.accentColor,
                  ),
                  _buildPage(
                    icon: Icons.rocket_launch,
                    title: _t('join_movement'),
                    description: _t('digital_revolution'),
                    color: AppConstants.primaryColor,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      4,
                      (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _currentPage == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? AppConstants.primaryColor
                              : AppConstants.greyColor.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_currentPage < 3) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => const AuthScreen()),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        _currentPage < 3 ? _t('next') : _t('get_started'),
                        style: const TextStyle(color: AppConstants.whiteColor, fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage({required IconData icon, required String title, required String description, required Color color}) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 80, color: color),
          ),
          const SizedBox(height: 48),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppConstants.textColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: const TextStyle(fontSize: 16, color: AppConstants.greyColor, height: 1.5),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
