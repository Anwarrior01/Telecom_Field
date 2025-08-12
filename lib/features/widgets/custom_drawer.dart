import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/core/utils/app_theme.dart';
import 'package:telecom_app/features/pages/history/history_screen.dart';
import 'package:telecom_app/features/pages/history/history_screen.dart';
import 'package:telecom_app/features/pages/profile/profile_screen.dart';

class CustomDrawer extends StatefulWidget {
  const CustomDrawer({super.key});

  @override
  State<CustomDrawer> createState() => _CustomDrawerState();
}

class _CustomDrawerState extends State<CustomDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _slideAnimation;
  String _technicianName = '';
  String _technicianDomain = '';

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _loadTechnicianInfo();
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadTechnicianInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _technicianName = prefs.getString('technician_name') ?? '';
      _technicianDomain = prefs.getString('technician_domain') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _slideAnimation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_slideAnimation.value * 300, 0),
          child: Drawer(
            child: Column(
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [AppTheme.accent, AppTheme.accentSecondary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _technicianName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Technicien $_technicianDomain',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Menu Items
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.person_outline,
                        title: 'Profil',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const ProfileScreen()),
                          );
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.history,
                        title: 'Historique',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => const HistoryScreen()),
                          );
                        },
                      ),
                     
                    ],
                  ),
                ),
                
                // Footer
                Container(
                  padding: const EdgeInsets.all(16),
                  child: const Text(
                    'TelecomField v1.0.0',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.accent.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppTheme.accent, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }
}
