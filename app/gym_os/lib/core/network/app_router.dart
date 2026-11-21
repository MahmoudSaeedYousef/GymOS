import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/features/auth/ui/login_screen.dart';
import 'package:gym_os/features/auth/ui/splash_screen.dart';
import 'package:gym_os/features/home/ui/dashboard_screen.dart';
import 'package:gym_os/features/home/ui/main_layout.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/ui/member_profile_screen.dart';
import 'package:gym_os/features/members/ui/members_screen.dart';
import 'package:gym_os/features/payments/ui/payments_history_screen.dart';
import 'package:gym_os/features/plans/ui/plans_management_screen.dart';
import 'package:gym_os/features/settings/ui/settings_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    // Redirect logic reacts to authentication state changes
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      if (isGoingToSplash) {
        return null;
      }

      if (authState.status == AuthStatus.initial) {
        return '/splash';
      }

      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }

      if (isAuth && isGoingToLogin) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      StatefulShellRoute(
        builder: (context, state, navigationShell) => navigationShell,
        navigatorContainerBuilder: (context, navigationShell, children) {
          return MainLayout(
            navigationShell: navigationShell,
            children: children,
          );
        },
        branches: [
          // Branch 0: Dashboard
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          // Branch 1: Members
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/members',
                name: 'members',
                builder: (context, state) {
                  final filter = state.uri.queryParameters['filter'];
                  return MembersScreen(initialFilter: filter);
                },
              ),
            ],
          ),
          // Branch 2: Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                name: 'settings',
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
      // Standalone modal / pushed full screens
      GoRoute(
        path: '/member-profile',
        name: 'memberProfile',
        builder: (context, state) {
          final member = state.extra as MemberModel;
          return MemberProfileScreen(member: member);
        },
      ),
      GoRoute(
        path: '/plans',
        name: 'plans',
        builder: (context, state) => const PlansManagementScreen(),
      ),
      GoRoute(
        path: '/payments',
        name: 'payments',
        builder: (context, state) => const PaymentsHistoryScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});
