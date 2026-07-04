import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_55555/core/services/config.dart';
import 'package:flutter_application_55555/features/diagnosis/application/agricultural_record_controller.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/cubit/diagnosis_details_cubit.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/entities/diagnosis_history_item.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_history.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/sync_backend_user.dart';
import 'package:flutter_application_55555/features/diagnosis/domain/usecases/get_diagnosis_details.dart';
import 'diagnosis_details_screen.dart';
// date formatting is done with simple DateTime formatting below (no intl dependency)

void main() {
  runApp(MaterialApp(home: AgriculturalRecordScreen()));
}

class AgriculturalRecordScreen extends StatefulWidget {
  final String? userId; // optional: provide a userId when navigating

  const AgriculturalRecordScreen({super.key, this.userId});

  @override
  State<AgriculturalRecordScreen> createState() =>
      _AgriculturalRecordScreenState();
}

// helper class for status styling (kept at top level for clarity)
class StatusStyle {
  final Color textColor;
  final Color bgColor;
  final IconData icon;

  StatusStyle({
    required this.textColor,
    required this.bgColor,
    required this.icon,
  });
}

class _AgriculturalRecordScreenState extends State<AgriculturalRecordScreen> {
  // Use the port that Kestrel exposes for HTTP. Based on your launch settings
  // the API is available on http://0.0.0.0:5067 so for Android emulator use 10.0.2.2:5067
  final String baseUrl = Config.apiBaseUrl;
  late final AgriculturalRecordController _controller;
  bool _isLoading = true;
  String? _error;
  List<DiagnosisHistoryItem> _items = [];
  // full list used for filtering/searching
  List<DiagnosisHistoryItem> _allItems = [];
  final TextEditingController _searchController = TextEditingController();
  // active status filters (treated, progress, notreated)
  final Set<String> _selectedStatusFilters = {};
  String _selectedTimeRange = 'all'; // all, today, month, year

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _controller = AgriculturalRecordController(
      getDiagnosisHistory: context.read<GetDiagnosisHistory>(),
      syncBackendUser: context.read<SyncBackendUser>(),
    );
    _fetchHistory();
  }

  Future<void> _showCustomTimePicker() async {
    // show modal to pick Day / Month / Year
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (bc) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: SizedBox(
            height: 360,
            child: SingleChildScrollView(
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: const BoxDecoration(
                  color: Color(0xFFF7FEF8),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    const Text(
                      'اختر نوع النطاق',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF044927),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, thickness: 1),
                    const SizedBox(height: 12),
                    ListTile(
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF044927),
                      ),
                      title: const Text('يوم محدد'),
                      subtitle: const Text('اختر يومًا معينًا'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final now = DateTime.now();
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: now,
                          firstDate: DateTime(now.year - 10),
                          lastDate: DateTime(now.year + 1),
                        );
                        if (picked != null) {
                          setState(() {
                            _selectedTimeRange =
                                'day:${picked.toIso8601String().split('T').first}';
                            _applyFilters();
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.date_range,
                        color: Color(0xFF044927),
                      ),
                      title: const Text('شهر محدد'),
                      subtitle: const Text('اختر شهرًا وسنة'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final res = await showModalBottomSheet<Map<String, int>>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (ctx) {
                            int selMonth = DateTime.now().month;
                            int selYear = DateTime.now().year;
                            final months = [
                              'يناير',
                              'فبراير',
                              'مارس',
                              'أبريل',
                              'مايو',
                              'يونيو',
                              'يوليو',
                              'أغسطس',
                              'سبتمبر',
                              'أكتوبر',
                              'نوفمبر',
                              'ديسمبر',
                            ];
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                              ),
                              child: SizedBox(
                                height: 300,
                                child: SingleChildScrollView(
                                  child: StatefulBuilder(
                                    builder: (c2, setStateSb) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'اختر الشهر والسنة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: DropdownButton<int>(
                                                    isExpanded: true,
                                                    value: selMonth,
                                                    items: List.generate(
                                                      12,
                                                      (i) => DropdownMenuItem(
                                                        value: i + 1,
                                                        child: Text(months[i]),
                                                      ),
                                                    ),
                                                    onChanged: (v) =>
                                                        setStateSb(
                                                          () => selMonth = v!,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: DropdownButton<int>(
                                                    isExpanded: true,
                                                    value: selYear,
                                                    items: List.generate(
                                                      11,
                                                      (i) => DropdownMenuItem(
                                                        value:
                                                            DateTime.now()
                                                                .year -
                                                            5 +
                                                            i,
                                                        child: Text(
                                                          '${DateTime.now().year - 5 + i}',
                                                        ),
                                                      ),
                                                    ),
                                                    onChanged: (v) =>
                                                        setStateSb(
                                                          () => selYear = v!,
                                                        ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: const Text('إلغاء'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop({
                                                        'month': selMonth,
                                                        'year': selYear,
                                                      }),
                                                  child: const Text('تطبيق'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                        if (res != null) {
                          setState(() {
                            final y = res['year']!;
                            final m = res['month']!;
                            _selectedTimeRange =
                                'month:${y.toString().padLeft(4, '0')}-${m.toString().padLeft(2, '0')}';
                            _applyFilters();
                          });
                        }
                      },
                    ),
                    ListTile(
                      leading: const Icon(
                        Icons.timeline,
                        color: Color(0xFF044927),
                      ),
                      title: const Text('سنة محددة'),
                      subtitle: const Text('اختر سنة محددة'),
                      onTap: () async {
                        Navigator.of(context).pop();
                        final res = await showModalBottomSheet<int>(
                          context: context,
                          isScrollControlled: true,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.vertical(
                              top: Radius.circular(20),
                            ),
                          ),
                          builder: (ctx) {
                            int selYear = DateTime.now().year;
                            return Padding(
                              padding: EdgeInsets.only(
                                bottom: MediaQuery.of(ctx).viewInsets.bottom,
                              ),
                              child: SizedBox(
                                height: 260,
                                child: SingleChildScrollView(
                                  child: StatefulBuilder(
                                    builder: (c2, setStateSb) {
                                      return Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: const BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.vertical(
                                            top: Radius.circular(20),
                                          ),
                                        ),
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              'اختر السنة',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            DropdownButton<int>(
                                              value: selYear,
                                              isExpanded: true,
                                              items: List.generate(
                                                21,
                                                (i) => DropdownMenuItem(
                                                  value:
                                                      DateTime.now().year -
                                                      10 +
                                                      i,
                                                  child: Text(
                                                    '${DateTime.now().year - 10 + i}',
                                                  ),
                                                ),
                                              ),
                                              onChanged: (v) => setStateSb(
                                                () => selYear = v!,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.of(ctx).pop(),
                                                  child: const Text('إلغاء'),
                                                ),
                                                const SizedBox(width: 8),
                                                ElevatedButton(
                                                  onPressed: () => Navigator.of(
                                                    ctx,
                                                  ).pop(selYear),
                                                  child: const Text('تطبيق'),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                        if (res != null) {
                          setState(() {
                            _selectedTimeRange = 'year:${res.toString()}';
                            _applyFilters();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _syncBackendAndRefresh() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      await _controller.syncBackendAndRefresh();
      await _fetchHistory();
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'فشل مزامنة الحساب: $e';
        });
      }
    }
  }

  Future<void> _fetchHistory() async {
    _searchController.clear();
    _selectedStatusFilters.clear();
    _selectedTimeRange = 'all';
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _controller.fetchHistory(userId: widget.userId);
    if (result.error == null) {
      _allItems = result.items;
      _applyFilters();
    } else {
      _error = result.error;
    }

    setState(() {
      _isLoading = false;
    });
  }

  String _formatDate(String iso) {
    try {
      // parse assuming UTC when timezone missing
      var s = iso;
      if (!s.endsWith('Z') && !s.contains('+') && !s.contains('-')) {
        s = s + 'Z';
      }
      var dt = DateTime.parse(s);
      final origDay = dt.day;
      dt = dt.toLocal();
      if (origDay != dt.day) {
        debugPrint('date shift for "$iso" origDay=$origDay localDay=${dt.day}');
      }
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return iso;
    }
  }

  // unified filtering & sorting routine
  void _applyFilters() {
    final temp = _controller.applyFilters(
      items: _allItems,
      query: _searchController.text,
      selectedStatusFilters: _selectedStatusFilters,
      selectedTimeRange: _selectedTimeRange,
      now: DateTime.now(),
    );

    setState(() {
      _items = temp;
    });
  }

  // helper that maps a raw status value (English/Arabic) to a display label
  String _statusLabel(String? status) {
    final normalized = _normalizeStatus(status);
    switch (normalized) {
      case 'treated':
        return 'تمت المعالجة';
      case 'progress':
        return 'قيد المعالجة';
      case 'notreated':
        return 'غير مُعالَج';
      default:
        return status?.trim() ?? '';
    }
  }

  // generic popup card menu used for all three selectors
  void _showCardMenu({
    required List<Map<String, String>> options,
    required String selected,
    required ValueChanged<String> onSelected,
    String? title,
  }) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: const EdgeInsets.symmetric(
            horizontal: 40,
            vertical: 24,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (title != null)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 16,
                  ),
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ...options.map((opt) {
                final value = opt['value']!;
                final label = opt['label']!;
                final isSelected = value == selected;
                return InkWell(
                  onTap: () {
                    onSelected(value);
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            label,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check, color: Colors.green),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  String _normalizeStatus(String? status) {
    return _controller.normalizeStatus(status);
  }

  int _statusPriority(String? status) {
    return _controller.statusPriority(status);
  }

  // statistics should reflect all items regardless of the current search/filter
  int get _total => _allItems.length;
  int get _treatedCount => _allItems.where((d) {
    final raw = d.status ?? '';
    final s = raw.toLowerCase().trim();
    // Count only actual "Treated" values. Backend uses: Not_Treated | In_Progress | Treated
    // Normalize by removing underscores so we match 'treated' reliably and avoid matching 'not_treated'.
    final normalized = s.replaceAll('_', '');
    if (normalized == 'treated') return true;
    // Arabic fallback: if the status text contains the Arabic word for treated
    if (s.contains('معالج')) return true;
    return false;
  }).length;

  // helper function for getting style based on status
  StatusStyle getStatusStyle(String? status) {
    final s = (status ?? '').toLowerCase().trim();

    // handle not-treated first to avoid false positive due to substring
    if (s.contains('not') && s.contains('treated')) {
      // fall through to default (non-treated)
    } else if (s.contains('معالج') ||
        (s.contains('treated') && !s.contains('not'))) {
      return StatusStyle(
        textColor: const Color(0xFF166534), // أخضر غامق
        bgColor: const Color(0xFFDCFCE7), // أخضر فاتح
        icon: Icons.check_circle,
      );
    }

    if (s.contains('قيد') || s.contains('progress')) {
      return StatusStyle(
        textColor: const Color.fromARGB(255, 131, 102, 23), // برتقالي غامق
        bgColor: const Color.fromARGB(255, 255, 251, 17), // برتقالي فاتح
        icon: Icons.timelapse,
      );
    }

    // غير معالج (default)
    return StatusStyle(
      textColor: const Color(0xFF991B1B), // أحمر غامق
      bgColor: const Color(0xFFFEE2E2), // أحمر فاتح
      icon: Icons.error,
    );
  }

  // Resolve image URL returned by backend. If backend returns a relative
  // path like `/uploads/xxx.jpg`, prepend the `baseUrl` so the emulator can
  // load it (e.g. http://10.0.2.2:5067/uploads/xxx.jpg).
  String? _resolveImageUrl(String? imageUrl) {
    if (imageUrl == null) return null;
    final trimmed = imageUrl.trim();
    if (trimmed.isEmpty) return null;
    // If it already has a scheme/host, return as-is
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    // If it starts with a slash, append directly to baseUrl
    if (trimmed.startsWith('/')) {
      return '$baseUrl$trimmed';
    }
    // Otherwise, join with a slash
    return '$baseUrl/$trimmed';
  }

  @override
  Widget build(BuildContext context) {
    // Display values for stat cards: show loading indicator while fetching
    final displayTotal = _isLoading ? '...' : '$_total';
    final displayTreated = _isLoading ? '...' : '$_treatedCount';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(61),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Color(0x1A000000),
                  blurRadius: 3,
                  offset: Offset(0, 1),
                ),
              ],
              border: Border(
                bottom: BorderSide(color: Color(0x1A000000), width: 0.645),
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconButton(
                        icon: Icon(
                          Icons.arrow_back_ios_new,
                          color: Colors.green,
                          size: 20,
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                    ),
                    const Text(
                      'تشخيص أمراض العنب',
                      style: TextStyle(
                        color: Color(0xFF016630),
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                    const SizedBox(width: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: RefreshIndicator(
            onRefresh: _fetchHistory,
            child: CustomScrollView(
              slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      ResultsHeader(resultsCount: _items.length),
                      const SizedBox(height: 8),
                      const Text(
                        'تتبع جميع التشخيصات والعلاجات السابقة',
                        style: TextStyle(
                          color: Color(0xFF4A5565),
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      Row(children: [Expanded(child: _buildSearchBar())]),
                      const SizedBox(height: 12),
                      FilterBar(
                        selectedStatuses: _selectedStatusFilters,
                        selectedTimeRange: _selectedTimeRange,
                        onStatusToggle: (s) {
                          setState(() {
                            if (_selectedStatusFilters.contains(s))
                              _selectedStatusFilters.remove(s);
                            else
                              _selectedStatusFilters.add(s);
                            _applyFilters();
                          });
                        },
                        onTimeSelected: (t) {
                          setState(() {
                            _selectedTimeRange = t;
                            _applyFilters();
                          });
                        },
                        onCustomTime: _showCustomTimePicker,
                      ),
                      const SizedBox(height: 8),
                      ActiveFiltersRow(
                        selectedStatuses: _selectedStatusFilters,
                        selectedTimeRange: _selectedTimeRange,
                        onRemoveStatus: (s) {
                          setState(() {
                            _selectedStatusFilters.remove(s);
                            _applyFilters();
                          });
                        },
                        onClearTime: () {
                          setState(() {
                            _selectedTimeRange = 'all';
                            _applyFilters();
                          });
                        },
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),

              // content area: loading / error / empty / list
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      children: [
                        // skeletons
                        Column(
                          children: List.generate(3, (_) {
                            return Container(
                              height: 105,
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade300,
                                borderRadius: BorderRadius.circular(14),
                              ),
                            );
                          }),
                        ),
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (_error != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text('خطأ: $_error'),
                        const SizedBox(height: 12),
                        if (_error!.contains(
                          'لم يتم العثور على معرّف مستخدم الخادم',
                        ))
                          ElevatedButton.icon(
                            onPressed: _syncBackendAndRefresh,
                            icon: const Icon(Icons.sync_alt),
                            label: const Text('إعادة مزامنة الحساب'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF00A63E),
                            ),
                          ),
                      ],
                    ),
                  ),
                )
              else if (_items.isEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'لم يتم إجراء أي تشخيص بعد\nابدأ بتشخيص ورقة عنب الآن 🌱',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = _items[index];
                      final resolvedImage = _resolveImageUrl(item.imageUrl);
                      DateTime? parsedDate;
                      try {
                        final ds = item.date ?? item.diagnosisDate;
                        if (ds != null && ds.isNotEmpty)
                          parsedDate = DateTime.parse(ds);
                      } catch (_) {
                        parsedDate = null;
                      }

                      return Column(
                        children: [
                          InkWell(
                            splashColor: Colors.green.withOpacity(0.2),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) {
                                    final getDiagnosisDetails = context
                                        .read<GetDiagnosisDetails>();
                                    final cubit = DiagnosisDetailsCubit(
                                      getDiagnosisDetails,
                                    );
                                    cubit.fetch(
                                      item.diagnosisId!,
                                      imageUrl: resolvedImage,
                                      date: parsedDate,
                                      disease: item.diseaseName,
                                      status: item.status,
                                    );
                                    return DiagnosisDetailsScreen(
                                      cubit: cubit,
                                      diagnosisId: item.diagnosisId!,
                                      imageUrl: resolvedImage,
                                      date: parsedDate,
                                      disease: item.diseaseName,
                                      status: item.status,
                                    );
                                  },
                                ),
                              );
                            },
                            child: _buildDiagnosisCard(
                              status: item.status ?? '',
                              disease: item.diseaseName ?? '',
                              date: _formatDate(
                                item.date ?? item.diagnosisDate ?? '',
                              ),
                              imageUrl: item.imageUrl,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }, childCount: _items.length),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required Color color,
    required Color borderColor,
    required Color iconBg,
    required String value,
    required String label,
    required Color valueColor,
    required Color labelColor,
    bool showProgress = false,
  }) {
    return Expanded(
      child: Container(
        height: 149,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(24),
              ),
              padding: const EdgeInsets.all(8),
              child: Icon(Icons.bar_chart, color: iconBg, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                color: valueColor,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: labelColor, fontSize: 14)),
            if (showProgress) ...[
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: _total > 0 ? (_treatedCount / _total) : 0,
                      backgroundColor: Colors.white.withOpacity(0.6),
                      color: iconBg,
                      minHeight: 6,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_treatedCount}/${_total}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF4A5565),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDailyInsight() {
    final now = DateTime.now();
    int treated = 0, progress = 0, notreated = 0;
    for (var d in _allItems) {
      try {
        final ds = d.date ?? d.diagnosisDate;
        if (ds != null && ds.isNotEmpty) {
          var s = ds;
          if (!s.endsWith('Z') && !s.contains('+') && !s.contains('-')) {
            s = s + 'Z';
          }
          var dt = DateTime.parse(s).toLocal();
          if (dt.year == now.year &&
              dt.month == now.month &&
              dt.day == now.day) {
            final norm = _normalizeStatus(d.status);
            if (norm == 'treated')
              treated++;
            else if (norm == 'progress')
              progress++;
            else if (norm == 'notreated')
              notreated++;
          }
        }
      } catch (_) {}
    }

    if (treated == 0 && progress == 0 && notreated == 0) {
      return const SizedBox.shrink();
    }

    final parts = <String>[];
    if (notreated > 0) parts.add('🔴 حالة غير معالجة: $notreated');
    if (progress > 0) parts.add('🟠 حالة قيد العلاج: $progress');
    if (treated > 0) parts.add('🟢 حالة معالجة: $treated');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Text(
        'اليوم:\n${parts.join('\n')}',
        style: const TextStyle(fontSize: 14),
      ),
    );
  }

  Widget _buildStatusChips() {
    // kept for backward compatibility if ever needed
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildChip('treated', 'تمت المعالجة', Colors.green),
        _buildChip('progress', 'قيد المعالجة', Colors.orange),
        _buildChip('notreated', 'غير مُعالَج', Colors.red),
      ],
    );
  }

  // retain chip builder for manual use
  Widget _buildChip(String key, String label, Color color) {
    final selected = _selectedStatusFilters.contains(key);
    return FilterChip(
      label: Text(label),
      selected: selected,
      backgroundColor: color.withOpacity(0.2),
      selectedColor: color.withOpacity(0.4),
      checkmarkColor: Colors.white,
      onSelected: (on) {
        setState(() {
          if (on)
            _selectedStatusFilters.add(key);
          else
            _selectedStatusFilters.remove(key);
          _applyFilters();
        });
      },
    );
  }

  // old filter dialog/button removed — use FilterBar, ActiveFiltersRow and ResultsHeader widgets below

  Widget _buildSearchBar() {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE6E6E6)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                hintText: 'البحث في السجل...',
                hintStyle: const TextStyle(
                  color: Color(0xFF717182),
                  fontSize: 15.5,
                ),
                border: InputBorder.none,
              ),
              textAlign: TextAlign.right,
              onChanged: (value) {
                _applyFilters();
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Colors.green, size: 22),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosisCard({
    required String status,
    required String disease,
    required String date,
    String? imageUrl,
  }) {
    // compute style once
    final style = getStatusStyle(status);
    final norm = _normalizeStatus(status);
    // choose stripe color per normalized status
    Color? stripeColor;
    double elevation = 0;
    switch (norm) {
      case 'notreated':
        stripeColor = const Color(0xFF991B1B);
        elevation = 4;
        break;
      case 'progress':
        stripeColor = const Color.fromARGB(255, 255, 179, 0); // amber/orange
        elevation = 3;
        break;
      case 'treated':
        stripeColor = const Color(0xFF00C950);
        elevation = 2;
        break;
      default:
        stripeColor = null;
        elevation = 0;
    }

    return Material(
      color: Colors.white,
      elevation: elevation,
      borderRadius: BorderRadius.circular(14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 125),
          child: Row(
            children: [
              if (stripeColor != null) Container(width: 4, color: stripeColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F3F5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: () {
                            final resolved = _resolveImageUrl(imageUrl);
                            if (resolved != null) {
                              return Image.network(
                                resolved,
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        width: 64,
                                        height: 64,
                                        alignment: Alignment.center,
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: const Color(0xFFF3F3F5),
                                    alignment: Alignment.center,
                                    child: Icon(
                                      Icons.broken_image,
                                      color: Colors.grey,
                                      size: 28,
                                    ),
                                  );
                                },
                              );
                            }
                            return Container(
                              alignment: Alignment.center,
                              child: Icon(
                                Icons.grain,
                                color: Colors.grey,
                                size: 40,
                              ),
                            );
                          }(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: style.bgColor,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          style.icon,
                                          size: 14,
                                          color: style.textColor,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _statusLabel(status),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: style.textColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    disease,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: Color(0xFF1E2939),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    color: Colors.grey,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      date,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFF4A5565),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(right: 12),
                        child: Icon(Icons.chevron_left, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- New filter widgets ---

// --- New filter widgets ---

class FilterChipItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const FilterChipItem({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bg = isSelected
        ? (activeColor ?? const Color(0xFF00C950))
        : const Color(0xFFF3F3F5);
    final textColor = isSelected ? Colors.white : const Color(0xFF1E2939);
    return AnimatedScale(
      scale: isSelected ? 1.02 : 1.0,
      duration: const Duration(milliseconds: 180),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ]
                : null,
            border: Border.all(
              color: isSelected
                  ? (activeColor ?? const Color(0xFF00C950))
                  : Colors.transparent,
            ),
          ),
          child: Text(label, style: TextStyle(color: textColor, fontSize: 14)),
        ),
      ),
    );
  }
}

class FilterBar extends StatelessWidget {
  final Set<String> selectedStatuses;
  final String selectedTimeRange;
  final Function(String) onStatusToggle;
  final Function(String) onTimeSelected;
  final VoidCallback onCustomTime;

  const FilterBar({
    Key? key,
    required this.selectedStatuses,
    required this.selectedTimeRange,
    required this.onStatusToggle,
    required this.onTimeSelected,
    required this.onCustomTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final statusOptions = [
      {
        'key': 'treated',
        'label': 'تمت المعالجة',
        'color': const Color(0xFF00C950),
      },
      {
        'key': 'progress',
        'label': 'قيد المعالجة',
        'color': const Color(0xFFFFB300),
      },
      {
        'key': 'notreated',
        'label': 'غير مُعالَج',
        'color': const Color(0xFF991B1B),
      },
    ];

    final timeOptions = [
      {'key': 'today', 'label': 'اليوم'},
      {'key': 'month', 'label': 'هذا الشهر'},
      {'key': 'year', 'label': 'هذه السنة'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // status chips
          ...statusOptions.map((o) {
            final k = o['key']! as String;
            final lbl = o['label']! as String;
            final col = o['color'] as Color;
            final sel = selectedStatuses.contains(k);
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChipItem(
                label: lbl,
                isSelected: sel,
                activeColor: col,
                onTap: () => onStatusToggle(k),
              ),
            );
          }).toList(),

          const SizedBox(width: 12),

          // time chips
          ...timeOptions.map((o) {
            final k = o['key']! as String;
            final lbl = o['label']! as String;
            final sel =
                selectedTimeRange == k || selectedTimeRange.startsWith('$k:');
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChipItem(
                label: lbl,
                isSelected: sel,
                activeColor: const Color(0xFF00C950),
                onTap: () => onTimeSelected(k),
              ),
            );
          }).toList(),

          // custom time
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChipItem(
              label: 'مخصص',
              isSelected:
                  selectedTimeRange.startsWith('day:') ||
                  selectedTimeRange.startsWith('month:') ||
                  selectedTimeRange.startsWith('year:'),
              activeColor: const Color(0xFF00C950),
              onTap: onCustomTime,
            ),
          ),
        ],
      ),
    );
  }
}

class ActiveFiltersRow extends StatelessWidget {
  final Set<String> selectedStatuses;
  final String selectedTimeRange;
  final Function(String) onRemoveStatus;
  final VoidCallback onClearTime;

  const ActiveFiltersRow({
    Key? key,
    required this.selectedStatuses,
    required this.selectedTimeRange,
    required this.onRemoveStatus,
    required this.onClearTime,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];
    final mapLabel = (String key) {
      switch (key) {
        case 'treated':
          return 'تمت المعالجة';
        case 'progress':
          return 'قيد المعالجة';
        case 'notreated':
          return 'غير مُعالَج';
        default:
          return key;
      }
    };

    for (var s in selectedStatuses) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
          child: Chip(
            label: Text('${mapLabel(s)}'),
            backgroundColor: const Color(0xFFF3F3F5),
            onDeleted: () => onRemoveStatus(s),
          ),
        ),
      );
    }

    if (selectedTimeRange != 'all') {
      String lbl;
      if (selectedTimeRange == 'today') {
        lbl = 'هذا اليوم';
      } else if (selectedTimeRange.startsWith('day:')) {
        final v = selectedTimeRange.substring(4);
        try {
          final dt = DateTime.parse(v);
          lbl = 'يوم ${dt.day}/${dt.month}/${dt.year}';
        } catch (_) {
          lbl = v;
        }
      } else if (selectedTimeRange.startsWith('month:')) {
        final v = selectedTimeRange.substring(6);
        final parts = v.split('-');
        if (parts.length == 2) {
          lbl = 'شهر ${parts[1]}/${parts[0]}';
        } else {
          lbl = v;
        }
      } else if (selectedTimeRange.startsWith('year:')) {
        final v = selectedTimeRange.substring(5);
        lbl = 'سنة $v';
      } else if (selectedTimeRange == 'month') {
        lbl = 'هذا الشهر';
      } else if (selectedTimeRange == 'year') {
        lbl = 'هذه السنة';
      } else {
        lbl = selectedTimeRange;
      }

      widgets.add(
        Padding(
          padding: const EdgeInsets.only(right: 8.0, bottom: 6.0),
          child: Chip(
            label: Text('$lbl'),
            backgroundColor: const Color(0xFFF3F3F5),
            onDeleted: onClearTime,
          ),
        ),
      );
    }

    if (widgets.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      width: double.infinity,
      child: Wrap(children: widgets),
    );
  }
}

class ResultsHeader extends StatelessWidget {
  final int resultsCount;

  const ResultsHeader({Key? key, required this.resultsCount}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          'السجل الزراعي (${resultsCount} نتيجة)',
          style: const TextStyle(
            color: Color(0xFF016630),
            fontWeight: FontWeight.bold,
            fontSize: 23,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
