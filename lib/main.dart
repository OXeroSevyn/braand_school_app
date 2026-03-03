import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/theme/app_theme.dart';
import 'core/route/app_router.dart';

import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase (Use AnonKey and URL from your actual setup)
  await Supabase.initialize(
    url: 'https://plwugvycuybkkanakjhv.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsd3VndnljdXlia2thbmFramh2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzI0NzI5NzUsImV4cCI6MjA4ODA0ODk3NX0.zGV8NQWeaNrines7h3SOJY7SaZxC7ygu1OMzwEakgpE',
  );

  // Initialize OneSignal
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  OneSignal.initialize("b49afa59-b504-4822-8bd4-144a7f944ee6");
  OneSignal.Notifications.requestPermission(true);

  runApp(const ProviderScope(child: BraandSchoolApp()));
}

class BraandSchoolApp extends ConsumerWidget {
  const BraandSchoolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Braand School',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
