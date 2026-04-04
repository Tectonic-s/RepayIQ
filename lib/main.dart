import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/providers/theme_provider.dart';
import 'core/router/app_router.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'firebase_options.dart';

// Queue of pending notification routes before router is ready
final _pendingNotificationRoutes = <String>[];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Store notification tap route — router will consume it after init
  NotificationService.onNotificationTap = (route) {
    _pendingNotificationRoutes.add(route);
  };

  await NotificationService.init();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  runApp(const ProviderScope(child: RepayIQApp()));
}

class RepayIQApp extends ConsumerWidget {
  const RepayIQApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeProvider);

    // Consume pending notification routes once router is ready
    if (_pendingNotificationRoutes.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final route = _pendingNotificationRoutes.removeAt(0);
        NotificationService.onNotificationTap = (r) => router.go(r);
        router.go(route);
      });
    } else {
      NotificationService.onNotificationTap = (route) => router.go(route);
    }

    return MaterialApp.router(
      title: 'RepayIQ',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
    );
  }
}
