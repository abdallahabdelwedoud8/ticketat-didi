import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:eventide/firebase_options.dart';
import 'package:eventide/theme.dart';
import 'package:eventide/models/app_models.dart';
import 'package:eventide/services/firebase_user_service.dart';
import 'package:eventide/services/firebase_auth_manager.dart';
import 'package:eventide/screens/onboarding_screen.dart';
import 'package:eventide/screens/buyer_dashboard.dart';
import 'package:eventide/screens/organizer_dashboard.dart';
import 'package:eventide/screens/sponsor_dashboard.dart';
import 'package:eventide/screens/security_dashboard.dart';
import 'package:eventide/utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Auth Manager
  final authManager = FirebaseAuthManager();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    await Future.delayed(const Duration(seconds: 1));
    
    final authManager = FirebaseAuthManager();
    final firebaseUser = authManager.currentFirebaseUser;
    
    if (!mounted) return;
    
    if (firebaseUser == null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const OnboardingScreen()),
      );
    } else {
      // Fetch user data from Firestore
      final currentUser = await FirebaseUserService.getUserById(firebaseUser.uid);
      
      if (currentUser == null) {
        // User deleted or not found - sign out
        await authManager.signOut();
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnboardingScreen()),
        );
        return;
      }
      
      Widget dashboard;
      switch (currentUser.role) {
        case UserRole.buyer:
          dashboard = const BuyerDashboard();
          break;
        case UserRole.organizer:
          dashboard = const OrganizerDashboard();
          break;
        case UserRole.sponsor:
          dashboard = const SponsorDashboard();
          break;
        case UserRole.security:
          dashboard = const SecurityDashboard();
          break;
        default:
          dashboard = const BuyerDashboard();
      }
      
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => dashboard),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.2,
            colors: [
              Color(0xFF9FE5D5),
              Color(0xFF7DD3C0),
            ],
          ),
        ),
        child: Center(
          child: Image.asset(
            'assets/images/splash_screen_logo.png',
            width: MediaQuery.of(context).size.width * 0.7,
            errorBuilder: (context, error, stackTrace) {
              return const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ticketat.',
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 8),
                  CircularProgressIndicator(color: Colors.white),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
