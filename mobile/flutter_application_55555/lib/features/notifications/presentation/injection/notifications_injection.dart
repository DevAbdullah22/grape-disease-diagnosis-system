import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:flutter_application_55555/core/service_locator.dart';
import 'package:flutter_application_55555/features/notifications/domain/usecases/get_notifications.dart';
import 'package:flutter_application_55555/features/notifications/presentation/cubit/notifications_cubit.dart';
import 'package:flutter_application_55555/features/notifications/presentation/screens/notifications_screen.dart';

Widget buildNotificationsScreen({Key? key}) {
  return BlocProvider<NotificationsCubit>(
    create: (_) {
      final cubit = NotificationsCubit(
        getNotifications: locator<GetNotifications>(),
      );
      cubit.loadNotifications();
      return cubit;
    },
    child: NotificationsScreen(key: key),
  );
}
