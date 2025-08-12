import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/core/utils/app_theme.dart';
import 'dart:convert';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _domainController = TextEditingController();
  bool _isEditing = false;
  int _totalOperations = 0;
  int _totalPdfs = 0;
  String _memberSince = '';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadStatistics();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _domainController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _nameController.text = prefs.getString('technician_name') ?? '';
      _domainController.text = prefs.getString('technician_domain') ?? '';
    });
  }

  Future<void> _loadStatistics() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load operations count
    final operationsJson = prefs.getStringList('operations') ?? [];
    
    // Load registration date
    final registrationDate = prefs.getString('registration_date');
    String memberSinceText;
    
    if (registrationDate != null) {
      final regDate = DateTime.parse(registrationDate);
      final now = DateTime.now();
      final difference = now.difference(regDate).inDays;
      
      if (difference == 0) {
        memberSinceText = 'Aujourd\'hui';
      } else if (difference == 1) {
        memberSinceText = 'Hier';
      } else if (difference < 30) {
        memberSinceText = '$difference jours';
      } else if (difference < 365) {
        final months = (difference / 30).round();
        memberSinceText = '$months mois';
      } else {
        final years = (difference / 365).round();
        memberSinceText = '$years an${years > 1 ? 's' : ''}';
      }
    } else {
      // Save current date as registration date if not exists
      await prefs.setString('registration_date', DateTime.now().toIso8601String());
      memberSinceText = 'Aujourd\'hui';
    }
    
    setState(() {
      _totalOperations = operationsJson.length;
      _totalPdfs = operationsJson.length; // Each operation generates one PDF
      _memberSince = memberSinceText;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('technician_name', _nameController.text.trim());
      await prefs.setString('technician_domain', _domainController.text.trim());
      
      setState(() {
        _isEditing = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil mis à jour avec succès'),
          backgroundColor: AppTheme.accent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil'),
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: AppTheme.accent),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            TextButton(
              onPressed: _saveProfile,
              child: const Text('Sauvegarder', style: TextStyle(color: AppTheme.accent)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Avatar
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
                Icons.person,
                size: 60,
                color: Colors.white,
              ),
            ),
            
            const SizedBox(height: 32),
            
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
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          prefixIcon: const Icon(Icons.person, color: AppTheme.accent),
                          suffixIcon: _isEditing ? null : const Icon(Icons.lock, color: AppTheme.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
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
                        controller: _domainController,
                        enabled: _isEditing,
                        decoration: InputDecoration(
                          labelText: 'Domaine de spécialité',
                          prefixIcon: const Icon(Icons.work, color: AppTheme.accent),
                          suffixIcon: _isEditing ? null : const Icon(Icons.lock, color: AppTheme.textSecondary),
                          contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Veuillez saisir votre domaine';
                          }
                          return null;
                        },
                      ),
                      
                      if (_isEditing) ...[
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton(
                                onPressed: () {
                                  setState(() => _isEditing = false);
                                  _loadProfile(); // Reset fields
                                },
                                child: const Text('Annuler',style : TextStyle(fontSize: 12),),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                child: const Text('Sauvegarder',style : TextStyle(fontSize: 12),),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Stats Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Statistiques',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatItem('Opérations terminées', _totalOperations.toString()),
                    _buildStatItem('PDF générés', _totalPdfs.toString()),
                    _buildStatItem('Membre depuis', _memberSince),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.accent,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}