// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/utils/app_router.dart';
import 'core/utils/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'data/datasources/local_datasource.dart';
import 'presentation/providers/app_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  await initializeDateFormatting('fr_FR', null);
  await LocalDataSource().init();
  await NotificationService().init();
  await NotificationService().requestPermission();
  SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(statusBarColor: Colors.transparent));
  runApp(const ProviderScope(child: MonnaieApp()));
}

class MonnaieApp extends ConsumerWidget {
  const MonnaieApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final router   = ref.watch(routerProvider);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationService().checkEveningReminder(
        enabled:        settings.eveningReminder,
        reminderHour:   settings.reminderHour,
        reminderMinute: settings.reminderMinute,
      );
    });

    return MaterialApp.router(
      title:                    'Plume',
      debugShowCheckedModeBanner: false,
      theme:                    AppTheme.light,
      darkTheme:                AppTheme.dark,
      themeMode: settings.isDarkMode ? ThemeMode.dark : ThemeMode.light,
      routerConfig: router,
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
        child: child!,
      ),
    );
  }
}