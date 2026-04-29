import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

/// Public landing page — mirrors /visitor on the web app.
/// Shows hero carousel, feature cards, stats, and CTA sections.
class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> {
  int _carouselIndex = 0;

  static const _heroImages = [
    'https://zaraa-eta.vercel.app/images/smart-agriculture.png',
    'https://zaraa-eta.vercel.app/images/food-crops.png',
    'https://zaraa-eta.vercel.app/images/farm-overview.png',
    'https://zaraa-eta.vercel.app/images/agriculture-hero.png',
    'https://zaraa-eta.vercel.app/images/women-in-agriculture.png',
    'https://zaraa-eta.vercel.app/images/sustainable-farming.png',
    'https://zaraa-eta.vercel.app/images/harvest-process.png',
  ];

  static const _features = [
    _Feature(
      icon: Icons.auto_awesome,
      badge: 'Instant AI Detection',
      title: 'Snap & Detect',
      description:
          'Let our neural network identify diseases and pests in seconds with 98.4% precision.',
    ),
    _Feature(
      icon: Icons.healing_outlined,
      badge: 'Reliable Treatments',
      title: 'Science-Backed Cures',
      description:
          'Remedies ranging from organic solutions to professional products tailored to your plant.',
    ),
    _Feature(
      icon: Icons.shopping_cart_outlined,
      badge: 'One-Click Shopping',
      title: 'Buy Treatments',
      description:
          'Directly purchase recommended treatments. Fast, secure checkout for fertilizers and tools.',
    ),
    _Feature(
      icon: Icons.history_edu_outlined,
      badge: 'Health Journal',
      title: 'Track & Recover',
      description:
          'A complete history of your garden\'s health. Track every diagnosis and recovery progress.',
    ),
  ];

  static const _services = [
    _Service(
      imageUrl: 'https://zaraa-eta.vercel.app/images/field-robotics.png',
      badge: 'Field Robotics',
      title: 'Smart Field Monitoring',
      description: 'Crop and plant health analysis powered by autonomous ground robots.',
    ),
    _Service(
      imageUrl: 'https://zaraa-eta.vercel.app/images/smart-agriculture.png',
      badge: 'Fruits',
      title: 'Disease Detection',
      description: 'Upload plant photos and get AI-driven insights to detect diseases instantly.',
    ),
    _Service(
      imageUrl: 'https://zaraa-eta.vercel.app/images/Treatment-for-plants.png',
      badge: 'Custom Treatments',
      title: 'Curated Remedies',
      description: 'Shop specialized, organic products tailored specifically for your plants.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildHeroSection(context)),
          SliverToBoxAdapter(child: _buildFeatureSection()),
          SliverToBoxAdapter(child: _buildServicesSection()),
          SliverToBoxAdapter(child: _buildWhyChooseSection()),
          SliverToBoxAdapter(child: _buildCTASection(context)),
          SliverToBoxAdapter(child: _buildFooter(context)),
        ],
      ),
    );
  }

  // ── App Bar ────────────────────────────────────────────────────
  SliverAppBar _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      floating: true,
      snap: true,
      backgroundColor: Theme.of(context).colorScheme.surface.withOpacity(0.96),
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.primaryGradient,
            ),
            child: const Center(
              child: Text(
                'Z',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Zaraa',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w800,
              fontSize: 18,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text(
            AppStrings.login,
            style: TextStyle(color: AppColors.textSecondary),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 14),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              textStyle: const TextStyle(fontSize: 13),
            ),
            onPressed: () => context.go(AppRoutes.register),
            child: const Text(AppStrings.joinFree),
          ),
        ),
      ],
    );
  }

  // ── Hero ───────────────────────────────────────────────────────
  Widget _buildHeroSection(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroGradient),
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Auto-play carousel
          CarouselSlider(
            options: CarouselOptions(
              height: 240,
              autoPlay: true,
              autoPlayInterval: const Duration(seconds: 4),
              autoPlayCurve: Curves.easeInOutCubic,
              enlargeCenterPage: true,
              viewportFraction: 0.82,
              onPageChanged: (i, _) => setState(() => _carouselIndex = i),
            ),
            items: _heroImages.map((url) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  url,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (_, __, ___) => Container(
                    color: AppColors.surfaceAlt,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.textMuted,
                      size: 40,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          // Dot indicators
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: _heroImages.asMap().entries.map((e) {
              final active = e.key == _carouselIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: active ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: active ? AppColors.primaryLight : AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
          // Hero text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                // AI badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primaryLight.withOpacity(0.4),
                    ),
                  ),
                  child: const Text(
                    'Advanced AI Ecosystem',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  AppStrings.heroTitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.25,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  AppStrings.heroSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                    height: 1.65,
                  ),
                ),
                const SizedBox(height: 30),
                // CTA buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.login),
                        icon: const Icon(Icons.biotech, size: 17),
                        label: const Text('Start Free Diagnosis'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.register),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        child: const Text('Create Account'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 52),
        ],
      ),
    );
  }

  // ── Feature cards ─────────────────────────────────────────────
  Widget _buildFeatureSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Join us',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Register Now...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ..._features.map(
            (f) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(f.icon, color: AppColors.primaryLight, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          f.badge,
                          style: const TextStyle(
                            color: AppColors.primaryLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          f.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.55,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Services ──────────────────────────────────────────────────
  Widget _buildServicesSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Our Services',
            style: TextStyle(
              color: AppColors.primaryLight,
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            AppStrings.aiPoweredPlantCare,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 20),
          ..._services.map(
            (s) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(17)),
                    child: Image.network(
                      s.imageUrl,
                      width: double.infinity,
                      height: 160,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 160,
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.image_outlined,
                            color: AppColors.textMuted, size: 40),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.badge,
                            style: const TextStyle(
                              color: AppColors.primaryLight,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          s.title,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.description,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Why Choose ────────────────────────────────────────────────
  Widget _buildWhyChooseSection() {
    const points = [
      (Icons.flash_on_outlined, 'Instant AI Scan',
          'Take a photo — our AI detects diseases, pests & deficiencies in seconds.'),
      (Icons.science_outlined, 'Proven Treatments',
          'Get tailored recommendations — natural or chemical — that actually work.'),
      (Icons.local_shipping_outlined, 'Easy Shopping',
          'Buy recommended products directly — secure & fast delivery.'),
    ];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 36, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            AppStrings.whyChoose,
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Simple, fast, and powerful tools designed for every grower — from beginners to professionals.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ...points.map(
            (p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(p.$1, color: AppColors.primaryLight, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.$2,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.$3,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── CTA Banner ────────────────────────────────────────────────
  Widget _buildCTASection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 32, 20, 0),
      padding: const EdgeInsets.all(30),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Powered by Advanced AI',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Save Your Plants Before It\'s Too Late',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w800,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Snap a photo of any leaf, fruit or plant — get instant disease detection, science-backed treatments, and shop the right remedies in one tap.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Color(0xFFB7E4C7),
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.go(AppRoutes.login),
              icon: const Icon(Icons.biotech, size: 18),
              label: const Text(
                AppStrings.startFreeDiagnosis,
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white60),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: () => context.go(AppRoutes.register),
              child: const Text(AppStrings.createFreeAccount),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Fast • Accurate • Free to Start',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────
  Widget _buildFooter(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 40),
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
      color: Theme.of(context).colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppColors.primaryGradient,
                ),
                child: const Center(
                  child: Text(
                    'Z',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Z a r a a',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Empowering farmers with AI-driven insights to protect crops and ensure a healthier harvest for the future.',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 24),
          // Quick nav links
          const Text(
            'Explore',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FooterLink(label: 'Dashboard', onTap: () => context.go(AppRoutes.login)),
              _FooterLink(label: 'Diagnosis', onTap: () => context.go(AppRoutes.login)),
              _FooterLink(label: 'My Garden', onTap: () => context.go(AppRoutes.login)),
              _FooterLink(label: 'Shop', onTap: () => context.go(AppRoutes.login)),
            ],
          ),
          const SizedBox(height: 28),
          const Divider(color: AppColors.surfaceBorder),
          const SizedBox(height: 14),
          const Row(
            children: [
              Text(
                '© 2026 Zaraa AI. All rights reserved.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 11),
              ),
              Spacer(),
              Text(
                '● All Systems Operational',
                style: TextStyle(color: AppColors.healthy, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Supporting data classes ───────────────────────────────────

class _Feature {
  final IconData icon;
  final String badge;
  final String title;
  final String description;
  const _Feature({
    required this.icon,
    required this.badge,
    required this.title,
    required this.description,
  });
}

class _Service {
  final String imageUrl;
  final String badge;
  final String title;
  final String description;
  const _Service({
    required this.imageUrl,
    required this.badge,
    required this.title,
    required this.description,
  });
}

class _FooterLink extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _FooterLink({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
