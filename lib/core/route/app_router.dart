import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../auth/login_screen.dart';
import '../../auth/signup_screen.dart';
import '../../auth/pending_approval_screen.dart';
import '../../dashboards/super_admin/super_admin_dashboard.dart';
import '../../dashboards/admin/admin_dashboard.dart';
import '../../dashboards/team/team_dashboard.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  @override
  Widget build(BuildContext context) =>
      const Scaffold(body: Center(child: CircularProgressIndicator()));
}

final routerProvider = Provider<GoRouter>((ref) {
  final userState = ref.watch(currentUserProvider);

  return GoRouter(
    initialLocation: '/splash',
    redirect: (context, state) {
      if (userState.isLoading) return '/splash';

      final user = userState.value;
      final isAuthRoute =
          state.uri.path == '/login' || state.uri.path == '/signup';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      if (!user.approved) {
        return state.uri.path == '/pending' ? null : '/pending';
      }

      // Approved user routing logic
      if (isAuthRoute ||
          state.uri.path == '/splash' ||
          state.uri.path == '/pending') {
        if (user.isSuperAdmin) return '/super-admin';
        if (user.isAdmin) return '/admin';
        return '/team';
      }

      return null; // Stay on current route
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/pending',
        name: 'pending',
        builder: (context, state) => const PendingApprovalScreen(),
      ),
      GoRoute(
        path: '/super-admin',
        name: 'super_admin_dashboard',
        builder: (context, state) => const SuperAdminDashboard(),
      ),
      GoRoute(
        path: '/admin',
        name: 'admin_dashboard',
        builder: (context, state) => const AdminDashboard(),
      ),
      GoRoute(
        path: '/team',
        name: 'team_dashboard',
        builder: (context, state) => const TeamDashboard(),
      ),
    ],
  );
});
