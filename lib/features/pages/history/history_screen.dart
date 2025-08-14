import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:telecom_app/models/operation.dart';
import 'package:telecom_app/core/utils/app_theme.dart';
import 'package:telecom_app/features/widgets/operation_card.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<Operation> _operations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadOperations();
  }

  Future<void> _loadOperations() async {
    final prefs = await SharedPreferences.getInstance();
    final operationsJson = prefs.getStringList('operations') ?? [];
    
    setState(() {
      _operations = operationsJson
          .map((json) => Operation.fromJson(jsonDecode(json)))
          .toList();
      _operations.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      _isLoading = false;
    });
  }

  void _viewOperationDetails(Operation operation) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => OperationDetailsScreen(operation: operation),
      ),
    );
  }

  Future<void> _deleteOperation(Operation operation) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.secondaryDark,
        title: const Text(
          'Supprimer l\'opération',
          style: TextStyle(color: AppTheme.textPrimary),
        ),
        content: const Text(
          'Êtes-vous sûr de vouloir supprimer cette opération?',
          style: TextStyle(color: AppTheme.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getStringList('operations') ?? [];
      operationsJson.removeWhere((json) {
        final op = Operation.fromJson(jsonDecode(json));
        return op.id == operation.id;
      });
      await prefs.setStringList('operations', operationsJson);
      _loadOperations();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historique'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.accent.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '${_operations.length}',
              style: const TextStyle(
                color: AppTheme.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppTheme.accent),
            )
          : _operations.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _operations.length,
                  itemBuilder: (context, index) {
                    return OperationCard(
                      operation: _operations[index],
                      onTap: () => _viewOperationDetails(_operations[index]),
                      onDelete: () => _deleteOperation(_operations[index]),
                    );
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.secondaryDark,
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.history,
              size: 60,
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Aucune opération',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vos interventions terminées\napparaîtront ici',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class OperationDetailsScreen extends StatelessWidget {
  final Operation operation;

  const OperationDetailsScreen({super.key, required this.operation});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Détails de l\'opération'),
        // actions: [
        //   IconButton(
        //     icon: const Icon(Icons.share),
        //     onPressed: () {
        //       // TODO: Implement sharing
        //     },
        //   ),
        // ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Info Card
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'INFORMATIONS CLIENT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nom:', operation.clientInfo.contactName),
                    _buildInfoRow('SIP:', operation.clientInfo.sip),
                    _buildInfoRow('Work Order:', operation.clientInfo.workOrder),
                    _buildInfoRow('Téléphone:', operation.clientInfo.phoneNumber),
                    _buildInfoRow('ID:', operation.clientInfo.id),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Photos Section
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PHOTOS (${operation.photos.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...operation.photos.asMap().entries.map((entry) {
                      final index = entry.key;
                      final photo = entry.value;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.secondaryDark.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 80,
                                  height: 80,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: FileImage(photo.imageFile),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Photo ${index + 1}',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatDateTime(photo.timestamp),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              photo.description,
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Technician Info
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TECHNICIEN',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.accent,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildInfoRow('Nom:', operation.technicianName),
                    _buildInfoRow('Numero:', operation.technicianNumber),
                    _buildInfoRow('Date:', _formatDate(operation.createdAt)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                color: AppTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _formatDateTime(DateTime date) {
    return '${_formatDate(date)} à ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}