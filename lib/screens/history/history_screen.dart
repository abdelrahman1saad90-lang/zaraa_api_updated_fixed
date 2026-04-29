import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';

/// Diagnosis history screen — mirrors /users/diagnosis-history.
/// Filterable list of past AI scans with status and confidence info.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  String _activeFilter = AppStrings.all;

  // In a real app these would come from a HistoryCubit fetching the API.
  // Using sample data to match the website's demo content.
  final List<DiagnosisModel> _allItems = DiagnosisModel.sampleHistory;

  static const _filters = [
    AppStrings.all,
    AppStrings.healthy,
    AppStrings.infected,
    AppStrings.recovering,
  ];

  List<DiagnosisModel> get _filtered {
    if (_activeFilter == AppStrings.all) return _allItems;
    return _allItems
        .where((d) => d.status.label == _activeFilter)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(AppStrings.diagnosisHistory),
        actions: [
          TextButton.icon(
            onPressed: _exportReport,
            icon: const Icon(Icons.download_outlined, size: 16),
            label: const Text(
              AppStrings.exportReport,
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Subtitle ────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Text(
              AppStrings.historySubtitle,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          // ── Filter chips ─────────────────────────────────────
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: _filters.map((f) {
                final isActive = f == _activeFilter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(f),
                    selected: isActive,
                    onSelected: (_) =>
                        setState(() => _activeFilter = f),
                    backgroundColor: AppColors.surfaceAlt,
                    selectedColor: _filterColor(f),
                    checkmarkColor: Colors.white,
                    labelStyle: TextStyle(
                      color: isActive
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: isActive
                          ? _filterColor(f)
                          : AppColors.surfaceBorder,
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 4),
                  ),
                );
              }).toList(),
            ),
          ),
          // ── Count ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              '${_filtered.length} result${_filtered.length != 1 ? 's' : ''}',
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // ── List ───────────────────────────────────────────
          Expanded(
            child: _filtered.isEmpty
                ? _buildEmpty()
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    itemCount: _filtered.length,
                    itemBuilder: (_, i) =>
                        _HistoryCard(diagnosis: _filtered[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Color _filterColor(String filter) {
    switch (filter) {
      case AppStrings.healthy:    return AppColors.healthy;
      case AppStrings.infected:   return AppColors.infected;
      case AppStrings.recovering: return AppColors.recovering;
      default:                    return AppColors.primary;
    }
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 56,
            color: AppColors.textMuted.withOpacity(0.5),
          ),
          const SizedBox(height: 14),
          Text(
            'No $_activeFilter diagnoses found.',
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  void _exportReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Export feature coming soon!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HISTORY CARD
// ══════════════════════════════════════════════════════════════

class _HistoryCard extends StatelessWidget {
  final DiagnosisModel diagnosis;
  const _HistoryCard({required this.diagnosis});

  Color get _statusColor {
    switch (diagnosis.status) {
      case DiagnosisStatus.healthy:    return AppColors.healthy;
      case DiagnosisStatus.infected:   return AppColors.infected;
      case DiagnosisStatus.recovering: return AppColors.recovering;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: _statusColor.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // ── Main content row ─────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    diagnosis.plantImageUrl ?? '',
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_outlined,
                        color: AppColors.textMuted,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Info column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name + status badge
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              diagnosis.plantName,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(
                              color: _statusColor.withOpacity(0.13),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              diagnosis.status.label,
                              style: TextStyle(
                                color: _statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      // Scan ID
                      if (diagnosis.diagnosisCode != null)
                        Text(
                          diagnosis.diagnosisCode!,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      const SizedBox(height: 6),
                      // Disease
                      Text(
                        diagnosis.disease,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Confidence row
                      Row(
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            color: AppColors.primaryLight,
                            size: 13,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'AI Confidence ${diagnosis.confidencePercent}',
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Footer: date + mini confidence bar ───────────────
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius:
                  const BorderRadius.vertical(bottom: Radius.circular(17)),
              border: Border(
                top: BorderSide(
                    color: _statusColor.withOpacity(0.15)),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.schedule_outlined,
                  size: 13,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 5),
                Text(
                  diagnosis.formattedDate,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                ),
                const Spacer(),
                // Mini bar
                SizedBox(
                  width: 80,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: diagnosis.confidence,
                      backgroundColor: AppColors.surfaceBorder,
                      color: _statusColor,
                      minHeight: 6,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
