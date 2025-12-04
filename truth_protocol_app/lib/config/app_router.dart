import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/presentation/auth/auth_provider.dart';
import 'package:truth_protocol_app/presentation/auth/login_screen.dart';
import 'package:truth_protocol_app/presentation/dashboard/dashboard_screen.dart';
import 'package:truth_protocol_app/presentation/minting/minting_screen.dart';
import 'package:truth_protocol_app/presentation/history/history_screen.dart';
import 'package:truth_protocol_app/presentation/history/credential_detail_screen.dart';
import 'package:truth_protocol_app/presentation/verifier/verifier_screen.dart';

part 'app_router.g.dart';

@Riverpod(keepAlive: true)
GoRouter appRouter(AppRouterRef ref) {
  final authState = ref.watch(authNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.maybeWhen(
        data: (authState) => authState.maybeWhen(
          authenticated: (_) => true,
          orElse: () => false,
        ),
        orElse: () => false,
      );

      final isLoggingIn = state.uri.path == '/login';

      if (!isLoggedIn && !isLoggingIn) {
        return '/login';
      }

      if (isLoggedIn && isLoggingIn) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/mint',
        builder: (context, state) => const MintingScreen(),
      ),
      GoRoute(
        path: '/history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/credential/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return CredentialDetailScreen(credentialId: id);
        },
      ),
      GoRoute(
        path: '/verify',
        builder: (context, state) => const VerifierScreen(),
      ),
    ],
  );
}
