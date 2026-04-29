import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// My Garden screen — mirrors /users/my-garden.
/// The web app shows "Coming Soon" for this section.
/// We match that with an attractive placeholder + teaser UI.
class MyGardenScreen extends StatelessWidget {
  const MyGardenScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        title: const Text(AppStrings.myGardenTitle),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            // Animated garden icon
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(
                  color: AppColors.primaryLight.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: const Center(
                child: Icon(
                  Icons.local_florist,
                  size: 60,
                  color: AppColors.primaryLight,
                ),
              ),
            ),
            const SizedBox(height: 28),
            const Text(
              AppStrings.comingSoon,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'The plant registry feature is currently under development.\nYou\'ll be able to track and manage all your plants from one place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.65,
              ),
            ),
            const SizedBox(height: 40),

            // ── Upcoming features preview ─────────────────────
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'What\'s coming:',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 14),
            ..._upcomingFeatures.map(
              (f) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(f.icon,
                          color: AppColors.primaryLight, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            f.title,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            f.description,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.accentYellow.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Soon',
                        style: TextStyle(
                          color: AppColors.accentYellow,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ── CTA — go to diagnosis ─────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => context.go(AppRoutes.diagnosis),
                icon: const Icon(Icons.biotech, size: 18),
                label: const Text('Start a Diagnosis Now'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static const _upcomingFeatures = [
    _Feature(
      icon: Icons.add_circle_outline,
      title: 'Register Your Plants',
      description:
          'Add each plant in your garden with species, location, and planting date.',
    ),
    _Feature(
      icon: Icons.timeline_outlined,
      title: 'Daily Care Routines',
      description:
          'Plan and track watering, fertilizing, and treatment schedules.',
    ),
    _Feature(
      icon: Icons.bar_chart_outlined,
      title: 'Health Analytics',
      description:
          'Visualise the health history of every plant over time.',
    ),
    _Feature(
      icon: Icons.notifications_outlined,
      title: 'Smart Reminders',
      description:
          'Get notified when it\'s time to water, prune, or spray.',
    ),
  ];
}

class _Feature {
  final IconData icon;
  final String title;
  final String description;
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });
}
