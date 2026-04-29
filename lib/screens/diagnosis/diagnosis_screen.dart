import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/models/models.dart';
import '../../cubits/diagnosis/diagnosis_cubit.dart';

/// 3-step plant diagnosis wizard.
/// Step 0: Select plant species
/// Step 1: Upload / capture photo → analyze
/// All business logic preserved — UI redesigned.
class DiagnosisScreen extends StatefulWidget {
  const DiagnosisScreen({super.key});

  @override
  State<DiagnosisScreen> createState() => _DiagnosisScreenState();
}

class _DiagnosisScreenState extends State<DiagnosisScreen>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  PlantModel? _selectedPlant;
  File? _imageFile;

  final _picker = ImagePicker();
  final _plants = PlantModel.defaultPlants;

  late final AnimationController _shimmerCtrl;

  @override
  void initState() {
    super.initState();
    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (picked != null) {
        setState(() => _imageFile = File(picked.path));
      }
    } catch (_) {}
  }

  Future<void> _analyze() async {
    if (_imageFile == null || _selectedPlant == null) return;

    await context.read<DiagnosisCubit>().analyze(
          imageFile: _imageFile!,
          plant: _selectedPlant!,
        );

    if (!mounted) return;

    final state = context.read<DiagnosisCubit>().state;
    if (state is DiagnosisSuccess) {
      context.go(AppRoutes.diagnosisResult, extra: state.result);
      context.read<DiagnosisCubit>().reset();
    } else if (state is DiagnosisError) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(state.message),
          backgroundColor: AppColors.infected,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _DiagnosisHeader(
            step: _step,
            selectedPlant: _selectedPlant,
          ),
          _ProgressBar(currentStep: _step),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0.04, 0),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                      parent: anim, curve: Curves.easeOut)),
                  child: child,
                ),
              ),
              child: _step == 0
                  ? _SelectPlantStep(
                      key: const ValueKey('step0'),
                      plants: _plants,
                      selectedPlant: _selectedPlant,
                      onPlantSelected: (p) =>
                          setState(() => _selectedPlant = p),
                      onContinue: () => setState(() => _step = 1),
                    )
                  : _UploadPhotoStep(
                      key: const ValueKey('step1'),
                      imageFile: _imageFile,
                      selectedPlant: _selectedPlant,
                      onPickImage: _pickImage,
                      onBack: () => setState(() => _step = 0),
                      onAnalyze: _analyze,
                      shimmerCtrl: _shimmerCtrl,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// HEADER
// ══════════════════════════════════════════════════════════════

class _DiagnosisHeader extends StatelessWidget {
  final int step;
  final PlantModel? selectedPlant;
  const _DiagnosisHeader({required this.step, this.selectedPlant});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 18),
          child: Row(
            children: [
              // Back
              GestureDetector(
                onTap: () => context.go(AppRoutes.dashboard),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 16),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      AppStrings.smartDiagnosis,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      step == 0
                          ? 'Step 1 of 2 — Choose your plant'
                          : 'Step 2 of 2 — Upload a photo',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.72),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // AI badge
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.25)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.auto_awesome,
                        color: Color(0xFFFFF176), size: 13),
                    SizedBox(width: 5),
                    Text('AI',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// PROGRESS BAR
// ══════════════════════════════════════════════════════════════

class _ProgressBar extends StatelessWidget {
  final int currentStep;
  const _ProgressBar({required this.currentStep});

  static const _steps = [
    AppStrings.selectPlant,
    AppStrings.uploadPhoto,
    AppStrings.results,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 18),
      child: Row(
        children: List.generate(_steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            final stepIdx = (i - 1) ~/ 2;
            final done = stepIdx < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: done
                      ? AppColors.primaryLight
                      : AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(1),
                ),
              ),
            );
          }

          final idx = i ~/ 2;
          final active = idx == currentStep;
          final done = idx < currentStep;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOut,
                width: active ? 38 : 32,
                height: active ? 38 : 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: (active || done)
                      ? AppColors.primary
                      : AppColors.surfaceAlt,
                  border: Border.all(
                    color: (active || done)
                        ? AppColors.primary
                        : AppColors.surfaceBorder,
                    width: active ? 2.5 : 1.5,
                  ),
                  boxShadow: active
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: done
                      ? const Icon(Icons.check_rounded,
                          color: Colors.white, size: 15)
                      : Text(
                          '${idx + 1}',
                          style: TextStyle(
                            color: active
                                ? Colors.white
                                : AppColors.textMuted,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                _steps[idx],
                style: TextStyle(
                  color: active
                      ? AppColors.primary
                      : AppColors.textMuted,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STEP 1 — SELECT PLANT
// ══════════════════════════════════════════════════════════════

class _SelectPlantStep extends StatelessWidget {
  final List<PlantModel> plants;
  final PlantModel? selectedPlant;
  final ValueChanged<PlantModel> onPlantSelected;
  final VoidCallback onContinue;

  const _SelectPlantStep({
    super.key,
    required this.plants,
    required this.selectedPlant,
    required this.onPlantSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hint banner
        Container(
          width: double.infinity,
          margin: const EdgeInsets.fromLTRB(18, 16, 18, 0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surfaceAlt,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.surfaceBorder),
          ),
          child: Row(
            children: const [
              Icon(Icons.info_outline_rounded,
                  color: AppColors.primaryLight, size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  AppStrings.choosePlantType,
                  style: TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        // Plant grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 0.82,
              ),
              itemCount: plants.length,
              itemBuilder: (_, i) {
                final plant = plants[i];
                final isSelected = selectedPlant?.id == plant.id;
                return _PlantCard(
                  plant: plant,
                  selected: isSelected,
                  onTap: () => onPlantSelected(plant),
                );
              },
            ),
          ),
        ),
        // Bottom action bar
        _BottomActionBar(
          leftLabel: AppStrings.back,
          rightLabel: AppStrings.continueToUpload,
          onLeft: () => context.go(AppRoutes.dashboard),
          onRight: selectedPlant != null ? onContinue : null,
        ),
      ],
    );
  }
}

class _PlantCard extends StatelessWidget {
  final PlantModel plant;
  final bool selected;
  final VoidCallback onTap;

  const _PlantCard({
    required this.plant,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.surfaceBorder,
            width: selected ? 2 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.20),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(14)),
                    child: Image.network(
                      plant.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => Container(
                        color: AppColors.surfaceAlt,
                        child: const Icon(Icons.eco,
                            color: AppColors.textMuted, size: 32),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 6),
                  child: Text(
                    plant.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: selected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 13),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// STEP 2 — UPLOAD PHOTO
// ══════════════════════════════════════════════════════════════

class _UploadPhotoStep extends StatelessWidget {
  final File? imageFile;
  final PlantModel? selectedPlant;
  final Future<void> Function(ImageSource) onPickImage;
  final VoidCallback onBack;
  final Future<void> Function() onAnalyze;
  final AnimationController shimmerCtrl;

  const _UploadPhotoStep({
    super.key,
    required this.imageFile,
    required this.selectedPlant,
    required this.onPickImage,
    required this.onBack,
    required this.onAnalyze,
    required this.shimmerCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DiagnosisCubit, DiagnosisState>(
      builder: (context, state) {
        final isAnalyzing = state is DiagnosisLoading;

        return Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              // Selected plant chip
              if (selectedPlant != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surfaceBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.spa_rounded,
                          color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        selectedPlant!.name,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Selected',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 9,
                                fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 14),

              // Upload zone
              GestureDetector(
                onTap: isAnalyzing
                    ? null
                    : () => _showPickerSheet(context),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: imageFile != null
                          ? AppColors.primary
                          : AppColors.surfaceBorder,
                      width: imageFile != null ? 2 : 1.5,
                    ),
                    boxShadow: imageFile != null
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.12),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            )
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: imageFile != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(imageFile!, fit: BoxFit.cover),
                              // Overlay to retap
                              Positioned(
                                bottom: 12,
                                right: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.55),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.edit_outlined,
                                          color: Colors.white, size: 13),
                                      SizedBox(width: 5),
                                      Text('Change',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 11,
                                              fontWeight:
                                                  FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withOpacity(0.10),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                    Icons.add_a_photo_outlined,
                                    color: AppColors.primary,
                                    size: 30),
                              ),
                              const SizedBox(height: 14),
                              const Text(
                                'Tap to add a photo',
                                style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                AppStrings.uploadInstruction,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Source buttons
              Row(
                children: [
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.camera_alt_rounded,
                      label: AppStrings.takePhoto,
                      enabled: !isAnalyzing,
                      onTap: () => onPickImage(ImageSource.camera),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _SourceButton(
                      icon: Icons.photo_library_rounded,
                      label: 'Gallery',
                      enabled: !isAnalyzing,
                      onTap: () => onPickImage(ImageSource.gallery),
                    ),
                  ),
                ],
              ),

              // Analyzing state
              if (isAnalyzing) ...[
                const SizedBox(height: 24),
                _AnalyzingIndicator(shimmerCtrl: shimmerCtrl),
              ],

              const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
            _BottomActionBar(
              leftLabel: AppStrings.back,
              rightLabel: AppStrings.analyzeNow,
              rightIcon: Icons.auto_awesome_rounded,
              onLeft: isAnalyzing ? null : onBack,
              onRight: (imageFile != null && !isAnalyzing) ? onAnalyze : null,
              isLoading: isAnalyzing,
            ),
          ],
        );
      },
    );
  }

  void _showPickerSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.surfaceBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Add Plant Photo',
                  style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              const Text('Choose how you want to add your image',
                  style: TextStyle(
                      color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.camera_alt_rounded,
                      title: 'Camera',
                      subtitle: 'Take a photo now',
                      onTap: () {
                        Navigator.pop(context);
                        onPickImage(ImageSource.camera);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerOption(
                      icon: Icons.photo_library_rounded,
                      title: 'Gallery',
                      subtitle: 'Pick from photos',
                      onTap: () {
                        Navigator.pop(context);
                        onPickImage(ImageSource.gallery);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Source button ─────────────────────────────────────────────────────────────

class _SourceButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _SourceButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                color: enabled ? AppColors.primary : AppColors.textMuted,
                size: 18),
            const SizedBox(width: 8),
            Text(label,
                style: TextStyle(
                    color: enabled
                        ? AppColors.textPrimary
                        : AppColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 13)),
          ],
        ),
      ),
    );
  }
}

// ── Picker option card ────────────────────────────────────────────────────────

class _PickerOption extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _PickerOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.surfaceBorder),
        ),
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 24),
            ),
            const SizedBox(height: 10),
            Text(title,
                style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const SizedBox(height: 3),
            Text(subtitle,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

// ── Analyzing indicator ───────────────────────────────────────────────────────

class _AnalyzingIndicator extends StatelessWidget {
  final AnimationController shimmerCtrl;
  const _AnalyzingIndicator({required this.shimmerCtrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceAlt,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 3,
                  backgroundColor: AppColors.surfaceBorder,
                ),
              ),
              const Icon(Icons.auto_awesome,
                  color: AppColors.primary, size: 22),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            AppStrings.analyzing,
            style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            'Our AI is examining your plant...\nThis takes just a moment.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════
// BOTTOM ACTION BAR (reusable)
// ══════════════════════════════════════════════════════════════

class _BottomActionBar extends StatelessWidget {
  final String leftLabel;
  final String rightLabel;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final bool isLoading;
  final IconData? rightIcon;

  const _BottomActionBar({
    required this.leftLabel,
    required this.rightLabel,
    this.onLeft,
    this.onRight,
    this.isLoading = false,
    this.rightIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        18,
        14,
        18,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          // Back button
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: onLeft,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(leftLabel,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Action button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: onRight,
                style: ElevatedButton.styleFrom(
                  backgroundColor: onRight == null
                      ? AppColors.surfaceBorder
                      : AppColors.primary,
                  foregroundColor: onRight == null
                      ? AppColors.textMuted
                      : Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (rightIcon != null) ...[
                            Icon(rightIcon, size: 16),
                            const SizedBox(width: 6),
                          ],
                          Text(rightLabel,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14)),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
