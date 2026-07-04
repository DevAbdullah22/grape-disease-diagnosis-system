import 'dart:async';
import 'dart:io';

import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_history_item.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_history.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/sync_backend_user.dart';

class AgriculturalRecordFetchResult {
  final List<DiagnosisHistoryItem> items;
  final String? error;

  const AgriculturalRecordFetchResult({
    required this.items,
    required this.error,
  });
}

class AgriculturalRecordController {
  final GetDiagnosisHistory getDiagnosisHistory;
  final SyncBackendUser syncBackendUser;

  AgriculturalRecordController({
    required this.getDiagnosisHistory,
    required this.syncBackendUser,
  });

  Future<void> syncBackendAndRefresh() async {
    await syncBackendUser.call();
  }

  Future<AgriculturalRecordFetchResult> fetchHistory({String? userId}) async {
    try {
      final items = await getDiagnosisHistory.call(userId: userId?.trim());
      return AgriculturalRecordFetchResult(items: items, error: null);
    } on TimeoutException catch (_) {
      return const AgriculturalRecordFetchResult(
        items: <DiagnosisHistoryItem>[],
        error: 'انتهى وقت الاتصال أثناء تحميل السجل.',
      );
    } on SocketException catch (_) {
      return const AgriculturalRecordFetchResult(
        items: <DiagnosisHistoryItem>[],
        error: 'تعذر الوصول إلى الخادم.',
      );
    } catch (e) {
      return AgriculturalRecordFetchResult(
        items: const <DiagnosisHistoryItem>[],
        error: e.toString(),
      );
    }
  }

  List<DiagnosisHistoryItem> applyFilters({
    required List<DiagnosisHistoryItem> items,
    required String query,
    required Set<String> selectedStatusFilters,
    required String selectedTimeRange,
    required DateTime now,
  }) {
    final normalizedQuery = query.toLowerCase().trim();
    final temp = items.where((d) {
      final disease = (d.diseaseName ?? '').toLowerCase();
      final rawDate = d.date ?? d.diagnosisDate ?? '';
      final date = rawDate.toLowerCase();
      final matchesSearch =
          normalizedQuery.isEmpty ||
          disease.contains(normalizedQuery) ||
          date.contains(normalizedQuery);
      final norm = normalizeStatus(d.status);
      final matchesStatus =
          selectedStatusFilters.isEmpty ||
          selectedStatusFilters.contains(norm);

      var matchesTime = true;
      if (selectedTimeRange != 'all' && rawDate.isNotEmpty) {
        try {
          var s = rawDate;
          if (!s.endsWith('Z') && !s.contains('+') && !s.contains('-')) {
            s = s + 'Z';
          }
          final dt = DateTime.parse(s).toLocal();
          if (selectedTimeRange == 'today') {
            matchesTime =
                dt.year == now.year &&
                dt.month == now.month &&
                dt.day == now.day;
          } else if (selectedTimeRange == 'month') {
            matchesTime = dt.year == now.year && dt.month == now.month;
          } else if (selectedTimeRange == 'year') {
            matchesTime = dt.year == now.year;
          } else if (selectedTimeRange.startsWith('day:')) {
            final value = selectedTimeRange.substring(4);
            try {
              var selected = value;
              if (!selected.endsWith('Z') &&
                  !selected.contains('+') &&
                  !selected.contains('-')) {
                selected = selected + 'Z';
              }
              final selectedDate = DateTime.parse(selected).toLocal();
              matchesTime =
                  dt.year == selectedDate.year &&
                  dt.month == selectedDate.month &&
                  dt.day == selectedDate.day;
            } catch (_) {
              matchesTime = true;
            }
          } else if (selectedTimeRange.startsWith('month:')) {
            final value = selectedTimeRange.substring(6);
            final parts = value.split('-');
            if (parts.length == 2) {
              final y = int.tryParse(parts[0]);
              final m = int.tryParse(parts[1]);
              if (y != null && m != null) {
                matchesTime = dt.year == y && dt.month == m;
              }
            }
          } else if (selectedTimeRange.startsWith('year:')) {
            final value = selectedTimeRange.substring(5);
            final y = int.tryParse(value);
            if (y != null) matchesTime = dt.year == y;
          }
        } catch (_) {
          matchesTime = true;
        }
      }

      return matchesSearch && matchesStatus && matchesTime;
    }).toList();

    temp.sort(
      (a, b) => statusPriority(a.status).compareTo(statusPriority(b.status)),
    );

    return temp;
  }

  String normalizeStatus(String? status) {
    final s = (status ?? '').toLowerCase();
    if (s.contains('not') && s.contains('treated')) return 'notreated';
    if (s.contains('معالج') || (s.contains('treated') && !s.contains('not'))) {
      return 'treated';
    }
    if (s.contains('قيد') || s.contains('progress')) return 'progress';
    return 'other';
  }

  int statusPriority(String? status) {
    switch (normalizeStatus(status)) {
      case 'notreated':
        return 0;
      case 'progress':
        return 1;
      case 'treated':
        return 2;
      default:
        return 3;
    }
  }
}
