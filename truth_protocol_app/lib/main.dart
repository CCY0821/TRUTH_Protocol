import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:truth_protocol_app/config/app_router.dart';
import 'package:truth_protocol_app/config/theme.dart';

void main() {
  runApp(
    const ProviderScope(
      child: TruthProtocolApp(),
    ),
  );
}

class TruthProtocolApp extends ConsumerWidget {
  const TruthProtocolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      title: 'TRUTH Protocol',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
