import '../../domain/entities/diagnosis_history_item.dart';

class DiagnosisHistoryItemModel extends DiagnosisHistoryItem {
  const DiagnosisHistoryItemModel({
    required super.diagnosisId,
    required super.diseaseName,
    required super.imageUrl,
    required super.status,
    required super.diagnosisDate,
    required super.date,
  });

  factory DiagnosisHistoryItemModel.fromJson(Map<String, dynamic> json) {
    return DiagnosisHistoryItemModel(
      diagnosisId: json['diagnosisId']?.toString(),
      diseaseName: json['diseaseName'] as String?,
      imageUrl: json['imageUrl'] as String?,
      status: json['status'] as String?,
      diagnosisDate: json['diagnosisDate']?.toString(),
      date: json['date']?.toString(),
    );
  }
}
