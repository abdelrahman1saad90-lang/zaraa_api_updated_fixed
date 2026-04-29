import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/auth/auth_cubit.dart';
import '../../cubits/auth/auth_state.dart';
import '../../cubits/weather/weather_cubit.dart';

// ═══════════════════════════════════════════════════════════════════════
// DASHBOARD SCREEN  —  all logic preserved, full UI redesign
// ═══════════════════════════════════════════════════════════════════════

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _tasks = TaskModel.sampleTasks;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final scans = RecentScanModel.sampleScans;

    return Scaffold(
      backgroundColor: const Color(0xFFF2F7F4),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── AppBar — UNCHANGED ────────────────────────────────────
          _DashboardAppBar(
            user: user,
            onProfileTap: () => _showProfileSheet(context, user),
          ),

          // ── Body ─────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Welcome hero card
                _WelcomeBanner(
                  user: user,
                  pulseController: _pulseController,
                ),
                const SizedBox(height: 24),

                // Environmental metrics — live from Visual Crossing
                BlocBuilder<WeatherCubit, WeatherState>(
                  builder: (context, wState) {
                    final weather = wState is WeatherLoaded
                        ? wState.weather
                        : wState is WeatherError
                            ? wState.fallback
                            : WeatherModel.demo;
                    final isLoading = wState is WeatherLoading ||
                        wState is WeatherInitial;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionLabel(
                          title: AppStrings.environmentalMetrics,
                          subtitle: isLoading ? 'Updating…' : weather.location,
                          icon: Icons.location_on_rounded,
                          action: isLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.primary,
                                  ),
                                )
                              : GestureDetector(
                                  onTap: () => context
                                      .read<WeatherCubit>()
                                      .refresh(),
                                  child: const Icon(
                                    Icons.refresh_rounded,
                                    size: 18,
                                    color: AppColors.textMuted,
                                  ),
                                ),
                        ),
                        const SizedBox(height: 10),
                        _WeatherGrid(weather: weather),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Stats
                _SectionLabel(title: 'This Month', icon: Icons.bar_chart_rounded),
                const SizedBox(height: 10),
                _StatsRow(),
                const SizedBox(height: 24),

                // Recent scans
                _SectionLabel(
                  title: AppStrings.recentScans,
                  icon: Icons.auto_awesome_rounded,
                  action: _PillAction(
                    label: 'View All',
                    onTap: () => context.go(AppRoutes.history),
                  ),
                ),
                const SizedBox(height: 10),
                _RecentScansList(scans: scans),
                const SizedBox(height: 24),

                // Schedule
                _SectionLabel(
                  title: AppStrings.todaySchedule,
                  subtitle: _todayLabel(),
                  icon: Icons.calendar_today_rounded,
                  action: _PillAction(
                    label: '+ Add Task',
                    onTap: () {},
                  ),
                ),
                const SizedBox(height: 10),
                _ScheduleList(
                  tasks: _tasks,
                  onTaskChanged: () => setState(() {}),
                ),
                const SizedBox(height: 24),

                // Quick access
                _SectionLabel(
                    title: 'Quick Access',
                    icon: Icons.grid_view_rounded),
                const SizedBox(height: 10),
                const _QuickAccessGrid(),
                const SizedBox(height: 8),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month]} ${now.day}';
  }

  void _showProfileSheet(BuildContext context, UserModel? user) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _ProfileSheet(
        user: user,
        onLogout: () {
          Navigator.pop(context);
          context.read<AuthCubit>().logout().then(
                (_) => context.go(AppRoutes.landing),
              );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// APP BAR  —  KEPT EXACTLY AS DESIGNED (unchanged logic + layout)
// ═══════════════════════════════════════════════════════════════════════

class _DashboardAppBar extends StatelessWidget {
  final UserModel? user;
  final VoidCallback onProfileTap;
  const _DashboardAppBar({this.user, required this.onProfileTap});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 0,
      backgroundColor: AppColors.primary,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/images/zaraa_logo.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Text('Z',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 16)),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            'Zaraa',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
      actions: [
        if (user != null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: onProfileTap,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.22),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.5), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    user!.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// PROFILE SHEET
// ═══════════════════════════════════════════════════════════════════════

class _ProfileSheet extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;
  const _ProfileSheet({required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 42, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 22),
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Center(
              child: Text(user.initials,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 26)),
            ),
          ),
          const SizedBox(height: 12),
          Text(user.fullName,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 19,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 3),
          Text(user.email,
              style: const TextStyle(
                  color: AppColors.textSecondary, fontSize: 13)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary]),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(user.planType ?? 'Basic',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFEEF2EE)),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: AppColors.infected.withOpacity(0.09),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.infected, size: 20),
            ),
            title: const Text('Log Out',
                style: TextStyle(
                    color: AppColors.infected,
                    fontWeight: FontWeight.w600,
                    fontSize: 15)),
            subtitle: const Text('Sign out of your account',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SECTION LABEL  — reusable header row
// ═══════════════════════════════════════════════════════════════════════

class _SectionLabel extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? action;

  const _SectionLabel({
    required this.title,
    required this.icon,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              subtitle!,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ] else
          const Spacer(),
        if (action != null) action!,
      ],
    );
  }
}

class _PillAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PillAction({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.09),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label,
            style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700)),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// WELCOME BANNER
// ═══════════════════════════════════════════════════════════════════════

class _WelcomeBanner extends StatelessWidget {
  final UserModel? user;
  final AnimationController pulseController;
  const _WelcomeBanner({this.user, required this.pulseController});

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = user?.fullName.split(' ').first ?? 'User';

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF1B5235),
            Color(0xFF2D7A50),
            Color(0xFF3A9E65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -35,
            top: -35,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.055),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -25,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            left: -15,
            bottom: -15,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI badge
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(20),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedBuilder(
                            animation: pulseController,
                            builder: (_, __) => Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF69F0AE),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF69F0AE)
                                        .withOpacity(0.35 +
                                            0.45 * pulseController.value),
                                    blurRadius: 7,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 7),
                          const Text(
                            'AI ENGINE: ACTIVE',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Greeting
                Text(
                  '$_greeting,',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$firstName 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  AppStrings.readyToCheck,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.70),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),

                // CTA button
                GestureDetector(
                  onTap: () => context.go(AppRoutes.diagnosis),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.12),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.document_scanner_rounded,
                            color: AppColors.primary, size: 18),
                        SizedBox(width: 8),
                        Text(
                          AppStrings.startNewDiagnosis,
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
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

// ═══════════════════════════════════════════════════════════════════════
// WEATHER GRID
// ═══════════════════════════════════════════════════════════════════════

class _WeatherGrid extends StatelessWidget {
  final WeatherModel weather;
  const _WeatherGrid({required this.weather});

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.65,
      children: [
        _WeatherTile(
          icon: Icons.thermostat_rounded,
          iconColor: const Color(0xFFFF6B35),
          label: AppStrings.temperature,
          value: '${weather.temperature.toInt()}°C',
          badge: 'OPTIMAL',
          badgeColor: AppColors.healthy,
        ),
        _WeatherTile(
          icon: Icons.water_drop_rounded,
          iconColor: const Color(0xFF4DA6FF),
          label: AppStrings.humidity,
          value: '${weather.humidity}%',
        ),
        _WeatherTile(
          icon: Icons.air_rounded,
          iconColor: const Color(0xFF8BA3B0),
          label: AppStrings.windSpeed,
          value: '${weather.windSpeed.toInt()} km/h',
        ),
        _WeatherTile(
          icon: Icons.eco_rounded,
          iconColor: AppColors.primaryLight,
          label: AppStrings.airQuality,
          value: weather.airQuality,
          badge: 'GOOD',
          badgeColor: AppColors.healthy,
        ),
      ],
    );
  }
}

class _WeatherTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String? badge;
  final Color? badgeColor;

  const _WeatherTile({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.badge,
    this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F2EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
              if (badge != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: (badgeColor ?? AppColors.healthy)
                        .withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      color: badgeColor ?? AppColors.healthy,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: value.length > 8 ? 15 : 22,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// STATS ROW
// ═══════════════════════════════════════════════════════════════════════

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _StatTile(
            icon: Icons.document_scanner_outlined,
            iconColor: Color(0xFF7C4DFF),
            value: '28',
            label: AppStrings.monthlyScans,
            trend: '+4',
            trendPositive: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.spa_outlined,
            iconColor: AppColors.primaryLight,
            value: '94',
            label: AppStrings.totalCrops,
            trend: '+2',
            trendPositive: true,
          ),
        ),
        SizedBox(width: 10),
        Expanded(
          child: _StatTile(
            icon: Icons.verified_outlined,
            iconColor: Color(0xFF26C6DA),
            value: '09',
            label: AppStrings.issuesSolved,
            trend: '9/20',
            trendPositive: false,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final String label;
  final String? trend;
  final bool trendPositive;

  const _StatTile({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.label,
    this.trend,
    this.trendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE8F2EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, color: iconColor, size: 16),
              ),
              if (trend != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.09),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                        color: iconColor,
                        fontSize: 9,
                        fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(value,
              style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 9.5),
              overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// RECENT SCANS
// ═══════════════════════════════════════════════════════════════════════

class _RecentScansList extends StatelessWidget {
  final List<RecentScanModel> scans;
  const _RecentScansList({required this.scans});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8F2EC)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          for (int i = 0; i < scans.length; i++) ...[
            _ScanRow(scan: scans[i]),
            if (i < scans.length - 1)
              const Divider(
                  height: 1, indent: 16, endIndent: 16, color: Color(0xFFF0F5F2)),
          ],
        ],
      ),
    );
  }
}

class _ScanRow extends StatelessWidget {
  final RecentScanModel scan;
  const _ScanRow({required this.scan});

  Color get _statusColor {
    switch (scan.status) {
      case DiagnosisStatus.healthy:
        return AppColors.healthy;
      case DiagnosisStatus.infected:
        return AppColors.infected;
      case DiagnosisStatus.recovering:
        return AppColors.recovering;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.network(
              scan.imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(Icons.eco_rounded,
                    color: AppColors.primaryLight, size: 24),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(scan.plantName,
                    style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13.5),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        scan.status.label.toUpperCase(),
                        style: TextStyle(
                            color: _statusColor,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${scan.confidencePercent}% confidence',
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Arrow
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// SCHEDULE LIST
// ═══════════════════════════════════════════════════════════════════════

class _ScheduleList extends StatelessWidget {
  final List<TaskModel> tasks;
  final VoidCallback onTaskChanged;
  const _ScheduleList({required this.tasks, required this.onTaskChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: tasks
          .map((t) => _TaskTile(task: t, onChanged: onTaskChanged))
          .toList(),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final TaskModel task;
  final VoidCallback onChanged;
  const _TaskTile({required this.task, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final borderColor = task.isPriority
        ? AppColors.recovering.withOpacity(0.35)
        : const Color(0xFFE8F2EC);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Checkbox
            SizedBox(
              width: 22,
              height: 22,
              child: Checkbox(
                value: task.isDone,
                activeColor: AppColors.primary,
                checkColor: Colors.white,
                side: const BorderSide(color: Color(0xFFCCDDD4), width: 1.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(5)),
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                onChanged: (val) {
                  task.isDone = val ?? false;
                  onChanged();
                },
              ),
            ),
            const SizedBox(width: 12),

            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.time.split(' ')[0],
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (task.time.split(' ').length > 1)
                  Text(
                    task.time.split(' ')[1],
                    style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 9,
                        fontWeight: FontWeight.w600),
                  ),
              ],
            ),
            const SizedBox(width: 12),

            // Vertical rule
            Container(
              width: 1,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primaryLight.withOpacity(0.15),
                    AppColors.primaryLight.withOpacity(0.6),
                    AppColors.primaryLight.withOpacity(0.15),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          task.title,
                          style: TextStyle(
                            color: task.isDone
                                ? AppColors.textMuted
                                : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                            decorationColor: AppColors.textMuted,
                          ),
                        ),
                      ),
                      if (task.isPriority)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.recovering.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(5),
                          ),
                          child: const Text(
                            'URGENT',
                            style: TextStyle(
                                color: AppColors.recovering,
                                fontSize: 8,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.3),
                          ),
                        ),
                    ],
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(task.description,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 11)),
                  ],
                ],
              ),
            ),

            // Task icon
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Icon(
                task.isPriority
                    ? Icons.priority_high_rounded
                    : task.title.toLowerCase().contains('water')
                        ? Icons.water_drop_outlined
                        : Icons.grass_outlined,
                color: task.isPriority
                    ? AppColors.recovering.withOpacity(0.6)
                    : AppColors.textMuted.withOpacity(0.5),
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════
// QUICK ACCESS GRID
// ═══════════════════════════════════════════════════════════════════════

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  static const _items = [
    _QuickItem(
      icon: Icons.document_scanner_rounded,
      label: 'New Scan',
      color: Color(0xFF7C4DFF),
      route: AppRoutes.diagnosis,
    ),
    _QuickItem(
      icon: Icons.spa_rounded,
      label: 'My Garden',
      color: AppColors.primaryLight,
      route: AppRoutes.myGarden,
    ),
    _QuickItem(
      icon: Icons.storefront_rounded,
      label: 'Shop',
      color: Color(0xFFF4A261),
      route: AppRoutes.shop,
    ),
    _QuickItem(
      icon: Icons.history_edu_rounded,
      label: 'History',
      color: Color(0xFF26C6DA),
      route: AppRoutes.history,
    ),
    _QuickItem(
      icon: Icons.receipt_long_rounded,
      label: 'Orders',
      color: Color(0xFFE74C3C),
      route: AppRoutes.orders,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _items
          .map((item) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: item == _items.last ? 0 : 10,
                  ),
                  child: _QuickTile(item: item),
                ),
              ))
          .toList(),
    );
  }
}

class _QuickItem {
  final IconData icon;
  final String label;
  final Color color;
  final String route;
  const _QuickItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.route,
  });
}

class _QuickTile extends StatelessWidget {
  final _QuickItem item;
  const _QuickTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go(item.route),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8F2EC)),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.07),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.09),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              item.label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
