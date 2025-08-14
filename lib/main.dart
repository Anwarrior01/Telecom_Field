import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/features/pages/onboarding/registration_screen.dart';
import 'package:telecom_app/features/pages/home/home_screen.dart';
import 'package:telecom_app/core/utils/app_theme.dart';

void main() {
  runApp(const TelecomFieldApp());
}

class TelecomFieldApp extends StatelessWidget {
  const TelecomFieldApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TelecomField',
      theme: AppTheme.darkTheme,
      home: const InitialScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class InitialScreen extends StatefulWidget {
  const InitialScreen({super.key});

  @override
  State<InitialScreen> createState() => _InitialScreenState();
}

class _InitialScreenState extends State<InitialScreen> {
  bool _isLoading = true;
  bool _isRegistered = false;

  @override
  void initState() {
    super.initState();
    _checkRegistration();
  }

  Future<void> _checkRegistration() async {
    final prefs = await SharedPreferences.getInstance();
    final name = prefs.getString('technician_name');
    final technicianNumber = prefs.getString('technician_number'); // Changed from domain to number
    
    setState(() {
      _isRegistered = name != null && technicianNumber != null; // Updated condition
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1A1A),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFF64FFDA)),
        ),
      );
    }

    return _isRegistered ? const HomeScreen() : const RegistrationScreen();
  }
}