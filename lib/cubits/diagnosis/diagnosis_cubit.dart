import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/models.dart';
import '../../core/services/diagnosis_service.dart';

// ══════════════════════════════════════════════════════════════
// STATES
// ══════════════════════════════════════════════════════════════

abstract class DiagnosisState extends Equatable {
  const DiagnosisState();
  @override
  List<Object?> get props => [];
}

/// Wizard is at step 1 (idle / reset)
class DiagnosisInitial extends DiagnosisState {
  const DiagnosisInitial();
}

/// AI analysis is running — show spinner
class DiagnosisLoading extends DiagnosisState {
  const DiagnosisLoading();
}

/// Analysis complete — result ready to show
class DiagnosisSuccess extends DiagnosisState {
  final DiagnosisModel result;
  const DiagnosisSuccess(this.result);

  @override
  List<Object?> get props => [result];
}

/// Analysis failed
class DiagnosisError extends DiagnosisState {
  final String message;
  const DiagnosisError(this.message);

  @override
  List<Object?> get props => [message];
}

// ══════════════════════════════════════════════════════════════
// CUBIT
// ══════════════════════════════════════════════════════════════

/// Manages the 3-step diagnosis wizard:
///   Step 1 → Select Plant  (DiagnosisInitial)
///   Step 2 → Upload Photo  (DiagnosisInitial still, UI handles step)
///   Step 3 → AI Results    (DiagnosisLoading → DiagnosisSuccess)
class DiagnosisCubit extends Cubit<DiagnosisState> {
  final DiagnosisService _service;

  DiagnosisCubit(this._service) : super(const DiagnosisInitial());

  /// Run the AI diagnosis.
  /// In DEMO MODE a plausible mock result is returned instantly.
  /// Swap the demo block for the real API call when your backend is ready.
  Future<void> analyze({
    required File imageFile,
    required PlantModel plant,
  }) async {
    emit(const DiagnosisLoading());

    // ── DEMO MODE ─────────────────────────────────────────────
    await Future.delayed(const Duration(seconds: 2));

    // Pick a realistic fake result based on plant type
    final diseases = _diseaseMap[plant.id] ?? _diseaseMap['tomato']!;
    final disease  = diseases[DateTime.now().second % diseases.length];

    final isHealthy   = disease.name == 'None (Healthy)';
    final status      = isHealthy
        ? DiagnosisStatus.healthy
        : (DateTime.now().millisecond % 2 == 0
            ? DiagnosisStatus.infected
            : DiagnosisStatus.recovering);
    final confidence  = 0.88 + (DateTime.now().millisecond % 12) / 100;
    final code        = 'DX-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

    final mockResult = DiagnosisModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      plantName: plant.name,
      plantImageUrl: plant.imageUrl,
      disease: disease.name,
      confidence: confidence,
      status: status,
      diagnosedAt: DateTime.now(),
      treatment: disease.treatment,
      diagnosisCode: code,
    );

    emit(DiagnosisSuccess(mockResult));
    // ── REAL API ───────────────────────────────────────────────
    // final res = await _service.diagnose(
    //   imageFile: imageFile,
    //   plantId: plant.id,
    //   plantName: plant.name,
    // );
    // if (res.isSuccess) emit(DiagnosisSuccess(res.data!));
    // else emit(DiagnosisError(res.error!));
  }

  /// Reset the wizard back to step 1
  void reset() => emit(const DiagnosisInitial());

  // ── Disease database (demo data per plant) ────────────────────
  static final _diseaseMap = <String, List<_DiseaseInfo>>{
    'apple': [
      _DiseaseInfo('Apple Scab', 'Apply fungicide every 7–10 days. Remove fallen infected leaves. Keep canopy open for air circulation.'),
      _DiseaseInfo('Cedar Apple Rust', 'Apply protective fungicide at bud break. Remove nearby cedars if possible.'),
      _DiseaseInfo('None (Healthy)', 'No treatment needed. Continue regular watering and fertilization schedule.'),
    ],
    'corn': [
      _DiseaseInfo('Common Rust', 'Apply triazole fungicide at first sign. Ensure adequate spacing for air circulation.'),
      _DiseaseInfo('Northern Corn Leaf Blight', 'Apply foliar fungicide. Rotate crops annually. Use resistant varieties next season.'),
      _DiseaseInfo('Gray Leaf Spot', 'Apply strobilurin fungicide. Avoid overhead irrigation to reduce leaf wetness.'),
    ],
    'tomato': [
      _DiseaseInfo('Late Blight', 'Apply copper-based fungicide every 7 days. Remove and destroy affected plant tissue immediately.'),
      _DiseaseInfo('Early Blight', 'Remove lower infected leaves. Apply chlorothalonil fungicide. Mulch around base.'),
      _DiseaseInfo('None (Healthy)', 'Your tomato plant looks great! Continue regular care and monitoring.'),
    ],
    'grape': [
      _DiseaseInfo('Black Rot', 'Apply copper fungicide from bud break. Remove mummified berries. Improve canopy airflow.'),
      _DiseaseInfo('Powdery Mildew', 'Apply sulfur-based fungicide. Prune for better air circulation. Avoid wetting foliage.'),
    ],
    'potato': [
      _DiseaseInfo('Late Blight', 'Apply preventive fungicide before symptoms appear. Hill soil around plants. Destroy infected tissue.'),
      _DiseaseInfo('Early Blight', 'Apply fungicide every 7–10 days. Avoid overhead watering. Ensure proper plant nutrition.'),
    ],
    'strawberry': [
      _DiseaseInfo('Gray Mold (Botrytis)', 'Improve air circulation. Apply fungicide at flowering. Remove infected fruit promptly.'),
      _DiseaseInfo('None (Healthy)', 'Plants are healthy! Maintain consistent watering and watch for runner growth.'),
    ],
    'peach': [
      _DiseaseInfo('Brown Rot', 'Apply fungicide at bloom. Remove mummified fruit. Prune for better air flow.'),
      _DiseaseInfo('Peach Leaf Curl', 'Apply copper fungicide before bud swell in late winter. Remove infected leaves.'),
    ],
    'cherry': [
      _DiseaseInfo('Brown Rot', 'Spray fungicide during flowering and after harvest. Remove infected fruit immediately.'),
      _DiseaseInfo('None (Healthy)', 'Cherry tree looks healthy! Continue regular pruning and pest monitoring.'),
    ],
    'pepper': [
      _DiseaseInfo('Bacterial Spot', 'Apply copper-based spray every 5–7 days. Avoid working with wet plants. Use disease-free seed.'),
      _DiseaseInfo('Phytophthora Blight', 'Improve drainage. Apply mefenoxam fungicide. Rotate crops for 3+ years.'),
    ],
  };
}

class _DiseaseInfo {
  final String name;
  final String treatment;
  const _DiseaseInfo(this.name, this.treatment);
}
