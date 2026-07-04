import '../../domain/entities/diagnosis_details.dart';

/// This model is responsible for transforming arbitrary JSON payloads from the
/// backend into the strongly-typed [DiagnosisDetails] entity.  It encapsulates
/// all of the normalization logic that previously lived inside
/// [DiagnosisDetailsController].
class DiagnosisDetailsModel extends DiagnosisDetails {
  DiagnosisDetailsModel({
    String? treatmentName,
    String? dosageInstructions,
    String? diseaseName,
    String? status,
    String? description,
    String? diseaseId,
    List<String>? referenceImages,
    double? confidence,
    String? imageUrl,
  }) : super(
          treatmentName: treatmentName,
          dosageInstructions: dosageInstructions,
          diseaseName: diseaseName,
          status: status,
          description: description,
          diseaseId: diseaseId,
          referenceImages: referenceImages,
          confidence: confidence,
          imageUrl: imageUrl,
        );

  static dynamic _findValueRecursive(dynamic node, List<String> candidateKeys) {
    final lowerKeys = candidateKeys.map((e) => e.toLowerCase()).toSet();

    dynamic walk(dynamic current) {
      if (current is Map) {
        for (final entry in current.entries) {
          final key = entry.key.toString().toLowerCase();
          if (lowerKeys.contains(key) && entry.value != null) {
            return entry.value;
          }
        }
        for (final entry in current.entries) {
          final nested = walk(entry.value);
          if (nested != null) return nested;
        }
      } else if (current is List) {
        for (final item in current) {
          final nested = walk(item);
          if (nested != null) return nested;
        }
      }
      return null;
    }

    return walk(node);
  }

  static double? _asDouble(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    final text = raw.toString().replaceAll('%', '').replaceAll(',', '.').trim();
    return double.tryParse(text);
  }

  static double? _normalizeConfidence(dynamic raw) {
    final value = _asDouble(raw);
    if (value == null) return null;
    var normalized = value;
    if (normalized > 1.0) normalized = normalized / 100.0;
    if (normalized < 0) normalized = 0;
    if (normalized > 1) normalized = 1;
    return normalized;
  }

  static String? _asNonEmptyString(dynamic raw) {
    if (raw == null) return null;
    final value = raw.toString().trim();
    return value.isEmpty ? null : value;
  }

  /// Normalizes an image URL by prepending the baseUrl when the provided path
  /// appears to be relative.  This mirrors the logic previously duplicated in
  /// several widgets and centralizes it for reuse in the data layer.
  static String _normalizeImageUrl(String imageUrl, String baseUrl) {
    try {
      if (!imageUrl.startsWith('http') &&
          !imageUrl.startsWith('file://') &&
          !imageUrl.startsWith('content://')) {
        return Uri.parse(baseUrl).resolve(imageUrl).toString();
      }
    } catch (_) {}
    return imageUrl;
  }

  factory DiagnosisDetailsModel.fromJson(
    Map<String, dynamic> json, {
    String? imageUrl,
    required String baseUrl,
  }) {
    // the normalization happens via _findValueRecursive on arbitrary JSON
    final treatmentName = _asNonEmptyString(
      _findValueRecursive(json, ['pesticideName', 'PesticideName']),
    );

    final dosageInstructions = _asNonEmptyString(
      _findValueRecursive(json, ['dosageInstructions', 'DosageInstructions']),
    );

    final diseaseName = _asNonEmptyString(
      _findValueRecursive(json, ['diseaseName', 'DiseaseName']),
    );

    final status = _asNonEmptyString(
      _findValueRecursive(json, [
        'status',
        'Status',
        'diagnosisStatus',
        'DiagnosisStatus',
      ]),
    );

    final description = _asNonEmptyString(
      _findValueRecursive(json, [
        'diseaseDescription',
        'DiseaseDescription',
        'description',
      ]),
    );

    final diseaseId = _asNonEmptyString(
      _findValueRecursive(json, [
        'diseaseId',
        'DiseaseId',
        'diseaseID',
        'DiseaseID',
        'disease_id',
        'Disease_Id',
      ]),
    );

    // reference images may be in many different formats
    List<String>? referenceImages;
    final dynamic refRaw = _findValueRecursive(json, [
      'referenceImages',
      'referenceImageUrls',
      'referenceimages',
      'exampleImages',
      'referencePhotos',
      'images',
      'Images',
      'example_images',
    ]);
    if (refRaw is List) {
      referenceImages = refRaw
          .map((e) => e == null ? null : e.toString().trim())
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toList();
      if (referenceImages.isEmpty) referenceImages = null;
    } else if (refRaw is String) {
      final parts = refRaw
          .split(RegExp(r'[;,\|]'))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
      referenceImages = parts.isEmpty ? null : parts;
    }

    final confidence = _normalizeConfidence(
      _findValueRecursive(json, ['confidence', 'Confidence', 'confidenceScore']),
    );

    // resolve image URL: prefer provided imageUrl param first, otherwise look
    // inside JSON under common keys and normalize path.
    String? resolvedImage;
    if (imageUrl != null && imageUrl.trim().isNotEmpty) {
      resolvedImage = _normalizeImageUrl(imageUrl, baseUrl);
    } else {
      final rawImg = _findValueRecursive(json, [
        'imageUrl',
        'image',
        'picture',
      ]);
      if (rawImg != null) {
        resolvedImage = _normalizeImageUrl(rawImg.toString(), baseUrl);
      }
    }

    return DiagnosisDetailsModel(
      treatmentName: treatmentName,
      dosageInstructions: dosageInstructions,
      diseaseName: diseaseName,
      status: status,
      description: description,
      diseaseId: diseaseId,
      referenceImages: referenceImages,
      confidence: confidence,
      imageUrl: resolvedImage,
    );
  }
}
