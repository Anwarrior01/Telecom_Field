import 'package:flutter/material.dart';
import 'dart:convert';
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
                      onTap: () => _viewOperation(_operations[index]),
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

  void _viewOperation(Operation operation) {
    // TODO: Navigate to operation details
  }
}