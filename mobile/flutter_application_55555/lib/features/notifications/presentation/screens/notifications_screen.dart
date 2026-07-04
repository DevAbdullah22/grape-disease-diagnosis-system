import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_application_55555/core/contracts/app_runtime_contract.dart';
import 'package:flutter_application_55555/features/diagnosis/presentation/screens/treatment_recommendations_screen.dart';
import 'package:flutter_application_55555/features/library/presentation/screen/library_item_details_screen.dart';
import 'package:flutter_application_55555/features/notifications/domain/entities/app_notification.dart';
import 'package:flutter_application_55555/features/notifications/presentation/cubit/notifications_cubit.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();

  static const Color primaryGreen = Color(0xFF016630);
  static const Color softBg = Color(0xFFF3FFF7);
  static const Color cardBg = Colors.white;

  static const Color tagRed = Color(0xFFFFE5E5);
  static const Color tagRedText = Color(0xFFFF3B30);

  static const Color tagYellow = Color(0xFFFFF7E0);
  static const Color tagYellowText = Color(0xFFFFA800);

  static const Color tagBlue = Color(0xFFE5F0FF);
  static const Color tagBlueText = Color(0xFF0066FF);

  static const Color tagGreen = Color(0xFFE6FFF2);
  static const Color tagGreenText = Color(0xFF00C950);

  static const Color tagPurple = Color(0xFFF3E8FF);
  static const Color tagPurpleText = Color(0xFFB620E0);

  static const Color borderGray = Color(0xFFE0E0E0);
  static const Color textGray = Color(0xFF4A5565);
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with SingleTickerProviderStateMixin {
  late final NotificationsCubit _cubit;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<NotificationsCubit>();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      _cubit.onTabChanged(_tabController.index);
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: NotificationsScreen.softBg,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0.5,
          centerTitle: true,
          title: const Text(
            'التنبيهات الزراعية',
            style: TextStyle(
              color: NotificationsScreen.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: SafeArea(
          top: false,
          child: BlocConsumer<NotificationsCubit, NotificationsState>(
            listenWhen: (previous, current) =>
                previous.uiActionVersion != current.uiActionVersion,
            listener: _onUiAction,
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(12),
                child: _buildBody(state),
              );
            },
          ),
        ),
      ),
    );
  }

  void _onUiAction(BuildContext context, NotificationsState state) {
    final action = state.uiAction;
    if (action == null) return;

    if (action is NotificationsShowDeleteSuccessSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('تم حذف الإشعار'),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'تراجع',
            onPressed: () {
              _cubit.undoDelete(
                removed: action.removed,
                originalIndex: action.originalIndex,
              );
            },
          ),
        ),
      );
      return;
    }

    if (action is NotificationsShowDeleteErrorSnackBar) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(action.message)),
      );
      return;
    }

    if (action is NotificationsShowDetailsSheet) {
      if (!mounted) return;
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom,
            ),
            child: _buildDetailsSheet(action.notification, action.relatedId),
          );
        },
      );
      return;
    }

    if (action is NotificationsNavigateToLibraryItem) {
      Navigator.of(context).pop();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => LibraryItemDetailsScreen(id: action.relatedId),
        ),
      );
      return;
    }

    if (action is NotificationsNavigateToDiagnosisDetails) {
      Navigator.of(context).pop();
      final details = _cubit.extractDiagnosisDetails(action.notification);
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TreatmentRecommendationsScreen.withProvider(
            diseaseName: details.diseaseName.isNotEmpty
                ? details.diseaseName
                : action.notification.title,
            diagnosisId: action.relatedId,
            confidence: details.confidence,
            description: details.description,
            diseaseImageUrl: details.diseaseImageUrl,
            diagnosisImagePath: null,
          ),
        ),
      );
    }
  }

  Widget _buildBody(NotificationsState state) {
    if (state.loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return Center(child: Text(state.error!));
    }
    if (state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('لا توجد إشعارات'),
            const SizedBox(height: 8),
            if (state.backendIdForDebug != null)
              Text(
                '${AppRuntimeContract.backendUserIdKey}: ${state.backendIdForDebug!}',
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            if (state.debugInfo != null) ...[
              const SizedBox(height: 6),
              Text(
                state.debugInfo!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ],
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () async {
                await _cubit.syncUserAndReload();
              },
              child: const Text('مزامنة المستخدم مع الخادم وإعادة تحميل'),
            ),
          ],
        ),
      );
    }

    final displayed = _cubit.getDisplayedNotifications();
    final int unreadCount = _cubit.getUnreadCount(displayed);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: NotificationsScreen.tagGreen.withOpacity(0.6),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'التنبيهات الزراعية',
                      style: TextStyle(
                        color: NotificationsScreen.primaryGreen,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (unreadCount == 0)
                      const Text(
                        'لا يوجد تنبيهات حالياً 🌿',
                        style: TextStyle(color: Colors.black54),
                      )
                    else
                      Text(
                        'لديك $unreadCount إشعار${unreadCount == 1 ? '' : 'ات'} جديدة',
                        style: const TextStyle(color: Colors.black54),
                      ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: unreadCount == 0
                    ? null
                    : () {
                        _cubit.markAllRead();
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: NotificationsScreen.tagGreen,
                  foregroundColor: NotificationsScreen.primaryGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                icon: const Icon(Icons.done, size: 18),
                label: const Text('قراءة الكل'),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _tabController,
            labelColor: NotificationsScreen.primaryGreen,
            unselectedLabelColor: Colors.black54,
            indicatorColor: NotificationsScreen.primaryGreen,
            tabs: const [
              Tab(text: 'الكل'),
              Tab(text: 'تذكيرات'),
              Tab(text: 'طقس'),
              Tab(text: 'مقالات'),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _cubit.loadNotifications,
            child: ListView.separated(
              itemCount: displayed.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final n = displayed[index];
                final style = _cubit.styleForType(n.type);
                final message = _cubit.buildMessageForList(n);

                return Dismissible(
                  key: ValueKey(n.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  onDismissed: (_) async {
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    await _cubit.deleteNotification(n);
                  },
                  child: _NotificationCard(
                    title: n.title,
                    titleTag: n.type,
                    timeLabel: _cubit.timeLabelFromRaw((n as dynamic).raw),
                    message: message,
                    tagColor: style['tagColor'] as Color,
                    tagTextColor: style['tagTextColor'] as Color,
                    borderColor: style['borderColor'] as Color,
                    trailingIcon: style['trailingIcon'] as IconData?,
                    trailingIconColor: style['trailingIconColor'] as Color?,
                    showDot: (style['showDot'] as bool) && !(n.read),
                    isRead: n.read,
                    onDetails: () => _cubit.openDetails(n),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailsSheet(AppNotification n, String relatedId) {
    return DraggableScrollableSheet(
      initialChildSize: 0.45,
      minChildSize: 0.25,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, sc) {
        final farm = _cubit.extractFarmFromRaw((n as dynamic).raw);
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            controller: sc,
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  Text(
                    n.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.black54,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _cubit.timeLabelFromRaw((n as dynamic).raw),
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(width: 12),
                      if (farm.isNotEmpty) ...[
                        const Icon(
                          Icons.agriculture,
                          size: 16,
                          color: Colors.black54,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          farm,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 14),
                  StatefulBuilder(
                    builder: (ctx, setState) {
                      var expanded = false;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            expanded
                                ? n.body
                                : (n.body.length > 400
                                      ? n.body.substring(0, 400) + '...'
                                      : n.body),
                            style: const TextStyle(
                              height: 1.6,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                          if (n.body.length > 400)
                            TextButton(
                              onPressed: () =>
                                  setState(() => expanded = !expanded),
                              child: Text(expanded ? 'عرض أقل' : 'عرض المزيد'),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 18),
                  if (!_cubit.isWeatherType(n.type)) ...[
                    if (_cubit.isArticleType(n.type) && relatedId.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _cubit.openLibraryItemDetails(
                              n: n,
                              relatedId: relatedId,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NotificationsScreen.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'فتح تفاصيل المقال',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      )
                    else if (relatedId.isNotEmpty)
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _cubit.openDiagnosisDetails(
                              n: n,
                              relatedId: relatedId,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: NotificationsScreen.primaryGreen,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            'فتح تفاصيل التشخيص',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('إغلاق'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String titleTag;
  final String timeLabel;
  final String message;
  final Color tagColor;
  final Color tagTextColor;
  final Color borderColor;
  final IconData? trailingIcon;
  final Color? trailingIconColor;
  final bool showDot;
  final bool isRead;
  final VoidCallback onDetails;

  const _NotificationCard({
    required this.title,
    required this.titleTag,
    required this.timeLabel,
    required this.message,
    required this.tagColor,
    required this.tagTextColor,
    required this.borderColor,
    required this.trailingIcon,
    required this.trailingIconColor,
    required this.showDot,
    required this.isRead,
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isRead
        ? Colors.white
        : NotificationsScreen.tagGreen.withOpacity(0.25);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [tagColor.withOpacity(0.35), Colors.white],
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            decoration: BoxDecoration(
              color: borderColor,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (trailingIcon != null)
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: tagColor,
                          child: Icon(
                            trailingIcon,
                            color: trailingIconColor,
                            size: 18,
                          ),
                        ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          titleTag,
                          style: TextStyle(
                            color: tagTextColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      if (showDot)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: tagTextColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isRead ? Colors.grey : Colors.black,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      if (timeLabel.isNotEmpty)
                        Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: Colors.black54,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              timeLabel,
                              style: const TextStyle(
                                color: Colors.black54,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    message,
                    maxLines: 6,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isRead
                          ? NotificationsScreen.textGray.withOpacity(0.6)
                          : NotificationsScreen.textGray,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: onDetails,
                      style: TextButton.styleFrom(
                        backgroundColor: NotificationsScreen.primaryGreen
                            .withOpacity(0.12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 8,
                        ),
                      ),
                      icon: Icon(
                        Icons.arrow_back_ios_new,
                        color: NotificationsScreen.primaryGreen,
                        size: 18,
                      ),
                      label: Text(
                        'التفاصيل',
                        style: TextStyle(
                          color: NotificationsScreen.primaryGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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
}
