import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/models/client_info.dart';
import 'package:telecom_app/features/pages/photo/photo_capture_screen.dart';
import 'package:telecom_app/core/utils/app_theme.dart';

class ClientInfoScreen extends StatefulWidget {
  const ClientInfoScreen({super.key});

  @override
  State<ClientInfoScreen> createState() => _ClientInfoScreenState();
}

class _ClientInfoScreenState extends State<ClientInfoScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _sipController = TextEditingController();
  final _workOrderController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  
  bool _isProcessing = false; // Added to prevent multiple taps

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _sipController.dispose();
    _workOrderController.dispose();
    _contactNameController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    super.dispose();
  }

  Future<void> _proceedToPhotos() async {
    if (_isProcessing) return; // Prevent multiple taps
    
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isProcessing = true;
      });

      try {
        final clientInfo = ClientInfo(
          sip: _sipController.text.trim(),
          workOrder: _workOrderController.text.trim(),
          contactName: _contactNameController.text.trim(),
          phoneNumber: _phoneController.text.trim(),
          id: _idController.text.trim(),
        );

        final prefs = await SharedPreferences.getInstance();
        final technicianName = prefs.getString('technician_name') ?? '';
        final technicianNumber = prefs.getString('technician_number') ?? ''; // Changed from domain to number

        if (mounted) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => PhotoCaptureScreen(
                clientInfo: clientInfo,
                technicianName: technicianName,
                technicianNumber: technicianNumber, // Updated parameter
              ),
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isProcessing = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Informations Client'),
        elevation: 0,
      ),
      body: SafeArea( // Added SafeArea to prevent overflow
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(), // Better scroll physics
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Header Card
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [AppTheme.accent, AppTheme.accentSecondary],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.person_add,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                            const SizedBox(width: 16),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Nouvelle Intervention',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    'Saisissez les données client',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Form Fields
                    _buildFormField(
                      controller: _sipController,
                      label: 'SIP',
                      icon: Icons.numbers,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le SIP';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _workOrderController,
                      label: 'Work Order',
                      icon: Icons.assignment,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le Work Order';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _contactNameController,
                      label: 'Nom du contact',
                      icon: Icons.person,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le nom du contact';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _phoneController,
                      label: 'Numéro de téléphone',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir le numéro de téléphone';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 16),
                    
                    _buildFormField(
                      controller: _idController,
                      label: 'ID',
                      icon: Icons.badge,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Veuillez saisir l\'ID';
                        }
                        return null;
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Next Button with loading state
                    SizedBox(
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isProcessing ? null : _proceedToPhotos,
                        child: _isProcessing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Suivant',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward),
                                ],
                              ),
                      ),
                    ),
                    
                    // Extra bottom padding to prevent overflow
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: AppTheme.accent),
          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppTheme.accent, width: 2),
          ),
          filled: true,
          fillColor: AppTheme.secondaryDark,
        ),
      ),
    );
  }
}