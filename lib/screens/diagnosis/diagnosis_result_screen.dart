import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';

/// Full-screen AI diagnosis result page.
/// Displayed outside the shell route (no bottom nav) for focus.
class DiagnosisResultScreen extends StatelessWidget {
  final DiagnosisModel diagnosis;
  const DiagnosisResultScreen({super.key, required this.diagnosis});

  Color get _statusColor {
    switch (diagnosis.status) {
      case DiagnosisStatus.healthy:    return AppColors.healthy;
      case DiagnosisStatus.infected:   return AppColors.infected;
      case DiagnosisStatus.recovering: return AppColors.recovering;
    }
  }

  IconData get _statusIcon {
    switch (diagnosis.status) {
      case DiagnosisStatus.healthy:    return Icons.check_circle;
      case DiagnosisStatus.infected:   return Icons.warning_rounded;
      case DiagnosisStatus.recovering: return Icons.trending_up_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(AppStrings.diagnosisResult),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new),
          onPressed: () => context.go(AppRoutes.diagnosis),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {},
            tooltip: 'Share result',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildResultCard(context),
            const SizedBox(height: 16),
            if (diagnosis.treatment != null) _buildTreatmentCard(),
            const SizedBox(height: 16),
            _buildMetaCard(),
            const SizedBox(height: 24),
            _buildActions(context),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ── Main result card ───────────────────────────────────────────
  Widget _buildResultCard(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _statusColor.withOpacity(0.35), width: 1.5),
      ),
      child: Column(
        children: [
          // Plant image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(21)),
            child: Image.network(
              diagnosis.plantImageUrl ?? '',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 220,
                color: AppColors.surfaceAlt,
                child: const Icon(
                  Icons.eco_outlined,
                  size: 64,
                  color: AppColors.textMuted,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(22),
            child: Column(
              children: [
                // Status badge
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.35), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, color: _statusColor, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        diagnosis.status.label.toUpperCase(),
                        style: TextStyle(
                          color: _statusColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                // Plant name
                Text(
                  diagnosis.plantName,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                // Disease name
                Text(
                  diagnosis.disease,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),

                // Confidence row
                Row(
                  children: [
                    const Text(
                      AppStrings.aiConfidence,
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      diagnosis.confidencePercent,
                      style: TextStyle(
                        color: _statusColor,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                // Confidence bar
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: diagnosis.confidence,
                    backgroundColor: AppColors.surfaceBorder,
                    color: _statusColor,
                    minHeight: 10,
                  ),
                ),
                // Confidence labels
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '0%',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Verified AI Results',
                        style: TextStyle(
                          color: AppColors.primaryLight,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Text(
                      '100%',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),

                if (diagnosis.diagnosisCode != null) ...[
                  const SizedBox(height: 14),
                  const Divider(color: AppColors.surfaceBorder),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.qr_code_2_outlined,
                        color: AppColors.textMuted,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Scan ID: ${diagnosis.diagnosisCode}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        diagnosis.formattedDate,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Treatment card ─────────────────────────────────────────────
  Widget _buildTreatmentCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.healing_outlined,
                  color: AppColors.primaryLight,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppStrings.treatment,
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  Text(
                    'Science-backed recommendation',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 14),
          Text(
            diagnosis.treatment!,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 14,
              height: 1.7,
            ),
          ),
        ],
      ),
    );
  }

  // ── Meta / timing card ─────────────────────────────────────────
  Widget _buildMetaCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          _MetaItem(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: diagnosis.formattedDate.split(' at ').first,
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.surfaceBorder,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _MetaItem(
            icon: Icons.access_time_outlined,
            label: 'Time',
            value: diagnosis.formattedDate.contains('at')
                ? diagnosis.formattedDate.split(' at ').last
                : '--',
          ),
          Container(
            width: 1,
            height: 36,
            color: AppColors.surfaceBorder,
            margin: const EdgeInsets.symmetric(horizontal: 16),
          ),
          _MetaItem(
            icon: Icons.eco_outlined,
            label: 'Species',
            value: diagnosis.plantName,
          ),
        ],
      ),
    );
  }

  // ── Action buttons ─────────────────────────────────────────────
  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.diagnosis),
                icon: const Icon(Icons.refresh_outlined, size: 17),
                label: const Text(AppStrings.scanAgain),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.shop),
                icon: const Icon(Icons.storefront_outlined, size: 17),
                label: const Text(AppStrings.shopTreatments),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => context.go(AppRoutes.history),
            icon: const Icon(Icons.history_outlined, size: 17),
            label: const Text('View All Diagnoses'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetaItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
