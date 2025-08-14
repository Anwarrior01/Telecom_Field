import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/features/pages/home/home_screen.dart';
import 'package:telecom_app/core/utils/app_theme.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _technicianNumberController = TextEditingController(); // Changed from domain to technician number
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isRegistering = false; // Added to prevent multiple taps

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _nameController.dispose();
    _technicianNumberController.dispose(); // Updated variable name
    super.dispose();
  }

  Future<void> _register() async {
    if (_isRegistering) return; // Prevent multiple taps
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isRegistering = true;
      });

      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('technician_name', _nameController.text.trim());
        await prefs.setString('technician_number', _technicianNumberController.text.trim()); // Changed from domain to number
        await prefs.setString('registration_date', DateTime.now().toIso8601String());
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isRegistering = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur lors de l\'enregistrement: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(), // Better scroll physics
                  padding: const EdgeInsets.all(24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 1),
                          
                          // Logo/Title
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppTheme.accent, AppTheme.accentSecondary],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: [
                                BoxShadow(
                                  color: AppTheme.accent.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.engineering,
                              size: 60,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 32),
                          const Text(
                            'TelecomField',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Identification du technicien',
                            style: TextStyle(
                              fontSize: 16,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 48),
                          
                          // Form
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  children: [
                                    TextFormField(
                                      controller: _nameController,
                                      enabled: !_isRegistering, // Disable when registering
                                      decoration: const InputDecoration(
                                        labelText: 'Nom complet',
                                        prefixIcon: Icon(Icons.person, color: AppTheme.accent),
                                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Veuillez saisir votre nom complet';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 20),
                                    TextFormField(
                                      controller: _technicianNumberController, // Updated controller
                                      enabled: !_isRegistering, // Disable when registering
                                      keyboardType: TextInputType.phone, // Added phone keyboard type
                                      decoration: const InputDecoration(
                                        labelText: 'Numéro du technicien', // Updated label
                                        prefixIcon: Icon(Icons.phone, color: AppTheme.accent), // Updated icon
                                        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                                        hintText: 'Ex: 0770000204', // Added hint
                                      ),
                                      validator: (value) {
                                        if (value == null || value.trim().isEmpty) {
                                          return 'Veuillez saisir votre numéro'; // Updated validation message
                                        }
                                        // Optional: Add phone number format validation
                                        if (!RegExp(r'^[0-9+\-\s]+$').hasMatch(value.trim())) {
                                          return 'Format de numéro invalide';
                                        }
                                        return null;
                                      },
                                    ),
                                    const SizedBox(height: 32),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 50,
                                      child: ElevatedButton(
                                        onPressed: _isRegistering ? null : _register,
                                        child: _isRegistering
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  color: Colors.white,
                                                ),
                                              )
                                            : const Text(
                                                'Commencer',
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          
                          const Spacer(flex: 1),
                          // Extra space for keyboard
                          SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}