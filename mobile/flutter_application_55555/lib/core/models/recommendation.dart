class TreatmentStep {
  final int? stepOrder;
  final String? pesticideName;
  final String? chemicalGroup;
  final String? pesticideImageUrl;
  final String? dosageInstructions;
  final String? mixQuantityAndType;
  final String? safetyInfo;
  final String? importantNotes;
  // step-level interval removed; use plan-level doseIntervalDays if needed
  final int? intervalDays;

  TreatmentStep({
    this.stepOrder,
    this.pesticideName,
    this.chemicalGroup,
    this.pesticideImageUrl,
    this.dosageInstructions,
    this.mixQuantityAndType,
    this.safetyInfo,
    this.importantNotes,
    this.intervalDays,
  });

  factory TreatmentStep.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TreatmentStep();

    String? pickString(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) return json[k].toString();
      }
      return null;
    }

    int? pickInt(List<String> keys) {
      for (final k in keys) {
        if (json.containsKey(k) && json[k] != null) {
          final v = json[k];
          if (v is int) return v;
          final parsed = int.tryParse(v.toString());
          if (parsed != null) return parsed;
        }
      }
      return null;
    }

    return TreatmentStep(
      stepOrder: pickInt(['StepOrder', 'stepOrder', 'order', 'step']),
      pesticideName: pickString([
        'PesticideName',
        'pesticideName',
        'pesticide_name',
        'Pesticide',
      ]),
      chemicalGroup: pickString(['ChemicalGroup', 'chemicalGroup', 'chemical']),
      pesticideImageUrl: pickString([
        'PesticideImageUrl',
        'pesticideImageUrl',
        'pesticide_image',
        'imageUrl',
        'image',
      ]),
      dosageInstructions: pickString([
        'DosageInstructions',
        'dosageInstructions',
        'dosage_instructions',
        'instructions',
      ]),
      mixQuantityAndType: pickString([
        'MixQuantityAndType',
        'mixQuantityAndType',
        'mix_quantity_and_type',
        'MixInfo',
      ]),
      safetyInfo: pickString([
        'SafetyInfo',
        'safetyInfo',
        'safety',
        'precautions',
      ]),
      importantNotes: pickString(['ImportantNotes', 'importantNotes', 'notes']),
      // remain for backwards compatibility; may be ignored by UI
      intervalDays: pickInt(['IntervalDays', 'interval_days', 'interval']),
    );
  }
}

class TreatmentExecution {
  final int? doseNumber;
  final DateTime? executedAt;
  final DateTime? nextDoseAt;

  TreatmentExecution({this.doseNumber, this.executedAt, this.nextDoseAt});

  factory TreatmentExecution.fromJson(Map<String, dynamic>? json) {
    if (json == null) return TreatmentExecution();

    int? _int(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      return int.tryParse(v.toString());
    }

    DateTime? _dt(dynamic v) {
      if (v == null) return null;
      if (v is DateTime) return v;
      try {
        return DateTime.tryParse(v.toString());
      } catch (_) {
        return null;
      }
    }

    return TreatmentExecution(
      doseNumber: _int(json['DoseNumber'] ?? json['doseNumber']),
      executedAt: _dt(json['ExecutedAt'] ?? json['executedAt']),
      nextDoseAt: _dt(json['NextDoseAt'] ?? json['nextDoseAt']),
    );
  }
}

class Recommendation {
  final String? diagnosisId;
  final String? diseaseId;
  final String? diseaseName;
  final String? pesticideName;
  final String? pesticideImageUrl;
  final String? importantNotes;
  final String? dosageInstructions;
  final String? safetyInfo;
  final String? mixQuantityAndType;
  final int? totalDoses;
  final int? doseIntervalDays;

  // New: plan metadata + step list
  final String? planName;
  final String? planDescription;
  final List<TreatmentStep>? steps; // steps no longer contain interval

  // Executions returned together with plan (used to compute status)
  final List<TreatmentExecution>? executions;

  Recommendation({
    this.diagnosisId,
    this.diseaseId,
    this.diseaseName,
    this.pesticideName,
    this.pesticideImageUrl,
    this.importantNotes,
    this.dosageInstructions,
    this.safetyInfo,
    this.mixQuantityAndType,
    this.totalDoses,
    this.doseIntervalDays,
    this.planName,
    this.planDescription,
    this.steps,
    this.executions,
  });

  static T? _get<T>(Map<String, dynamic>? json, List<String> keys) {
    if (json == null) return null;

    T? tryConvert(dynamic v) {
      if (v == null) return null;
      if (v is T) return v;
      try {
        if (T == String) return v.toString() as T;
        if (T == int) return int.tryParse(v.toString()) as T?;
      } catch (_) {}
      return null;
    }

    // 1) Try direct top-level keys (exact names provided)
    for (final k in keys) {
      if (json.containsKey(k) && json[k] != null) {
        final res = tryConvert(json[k]);
        if (res != null) return res;
      }
    }

    // 2) Recursively search nested maps/lists for matching key names (case-insensitive)
    T? recurse(dynamic node) {
      if (node == null) return null;
      if (node is Map<String, dynamic>) {
        for (final entry in node.entries) {
          final keyName = entry.key;
          for (final target in keys) {
            if (keyName.toLowerCase() == target.toLowerCase()) {
              final converted = tryConvert(entry.value);
              if (converted != null) return converted;
            }
          }
          final r = recurse(entry.value);
          if (r != null) return r;
        }
      } else if (node is List) {
        for (final item in node) {
          final r = recurse(item);
          if (r != null) return r;
        }
      }
      return null;
    }

    return recurse(json);
  }

  factory Recommendation.fromJson(Map<String, dynamic>? json) {
    // parse steps if present
    List<TreatmentStep>? parseSteps(Map<String, dynamic>? root) {
      if (root == null) return null;
      dynamic raw =
          root['steps'] ??
          root['Steps'] ??
          root['planSteps'] ??
          root['treatmentSteps'];
      if (raw == null) {
        // try nested objects (e.g. treatmentPlan.steps)
        for (final k in ['treatmentPlan', 'plan', 'treatment_plan']) {
          if (root.containsKey(k) &&
              root[k] is Map &&
              (root[k] as Map).containsKey('steps')) {
            raw = (root[k] as Map)['steps'];
            break;
          }
        }
      }

      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) return TreatmentStep.fromJson(e);
          try {
            return TreatmentStep.fromJson(Map<String, dynamic>.from(e as Map));
          } catch (_) {
            return TreatmentStep.fromJson(null);
          }
        }).toList();
      }
      return null;
    }

    // parse executions if present
    List<TreatmentExecution>? parseExecutions(Map<String, dynamic>? root) {
      if (root == null) return null;
      dynamic raw =
          root['executions'] ??
          root['Executions'] ??
          root['treatmentExecutions'];
      if (raw is List) {
        return raw.map((e) {
          if (e is Map<String, dynamic>) return TreatmentExecution.fromJson(e);
          try {
            return TreatmentExecution.fromJson(
              Map<String, dynamic>.from(e as Map),
            );
          } catch (_) {
            return TreatmentExecution.fromJson(null);
          }
        }).toList();
      }
      // also try nested container treatmentPlan.executions
      for (final k in ['treatmentPlan', 'plan', 'treatment_plan']) {
        if (root.containsKey(k) &&
            root[k] is Map &&
            (root[k] as Map).containsKey('executions')) {
          final r = (root[k] as Map)['executions'];
          if (r is List) {
            return r
                .map(
                  (e) => TreatmentExecution.fromJson(e as Map<String, dynamic>),
                )
                .toList();
          }
        }
      }
      return null;
    }

    return Recommendation(
      diagnosisId: _get<String>(json, [
        'DiagnosisId',
        'diagnosisId',
        'diagnosis_id',
      ]),
      diseaseId: _get<String>(json, ['DiseaseId', 'diseaseId', 'disease_id']),
      diseaseName: _get<String>(json, [
        'DiseaseName',
        'diseaseName',
        'disease_name',
      ]),
      pesticideName: _get<String>(json, [
        'PesticideName',
        'pesticideName',
        'pesticide_name',
        'Pesticide',
      ]),
      pesticideImageUrl: _get<String>(json, [
        'PesticideImageUrl',
        'pesticideImageUrl',
        'pesticide_image',
        'imageUrl',
        'image',
      ]),
      importantNotes: _get<String>(json, [
        'ImportantNotes',
        'importantNotes',
        'notes',
      ]),
      dosageInstructions: _get<String>(json, [
        'DosageInstructions',
        'dosageInstructions',
        'dosage_instructions',
        'instructions',
      ]),
      safetyInfo: _get<String>(json, [
        'SafetyInfo',
        'safetyInfo',
        'safety',
        'precautions',
      ]),
      mixQuantityAndType: _get<String>(json, [
        'MixQuantityAndType',
        'mixQuantityAndType',
        'mix_quantity_and_type',
        'MixInfo',
      ]),
      totalDoses: _get<int>(json, [
        'TotalDoses',
        'totalDoses',
        'total_doses',
        'TotalDose',
        'TotalDoseCount',
      ]),
      doseIntervalDays: _get<int>(json, [
        'DoseIntervalDays',
        'doseIntervalDays',
        'dose_interval_days',
        'IntervalDays',
      ]),
      planName: _get<String>(json, ['PlanName', 'planName', 'plan_name']),
      planDescription: _get<String>(json, [
        'Description',
        'description',
        'planDescription',
        'plan_description',
      ]),
      steps: parseSteps(json),
      executions: parseExecutions(json),
    );
  }
}
