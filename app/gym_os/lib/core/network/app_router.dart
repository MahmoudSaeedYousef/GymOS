import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gym_os/features/auth/ui/login_screen.dart';
import 'package:gym_os/features/auth/ui/splash_screen.dart';
import 'package:gym_os/features/home/ui/main_layout.dart';
import 'package:gym_os/features/members/models/member_model.dart';
import 'package:gym_os/features/members/ui/member_profile_screen.dart';
import 'package:gym_os/features/members/ui/members_screen.dart';
import 'package:gym_os/features/payments/ui/payments_history_screen.dart';
import 'package:gym_os/features/plans/ui/plans_management_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/splash',
    // هنا بيحصل الـ Magic: الـ Redirect بيشتغل مع أي تغيير في حالة الـ Auth
    redirect: (context, state) {
      final isAuth = authState.status == AuthStatus.authenticated;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToSplash = state.matchedLocation == '/splash';

      // شاشة السبلاش تدير انتقالها بنفسها بعد الأنيميشن
      if (isGoingToSplash) {
        return null;
      }

      if (authState.status == AuthStatus.initial) {
        return '/splash'; // لسه بيفحص التوكن في الـ Storage
      }

      // لو مش مسجل دخول وبيحاول يروح لأي شاشة غير اللوجين، رجعه للوجين
      if (!isAuth && !isGoingToLogin) {
        return '/login';
      }

      // لو مسجل دخول وبيحاول يروح لشاشة اللوجين، وديه الرئيسية
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
      GoRoute(
        path: '/',
        builder: (context, state) => const MainLayout(),
        routes: [
          GoRoute(
            path: 'member-profile',
            name: 'memberProfile',
            builder: (context, state) {
              final member = state.extra as MemberModel;
              return MemberProfileScreen(member: member);
            },
          ),
          GoRoute(
            path: 'plans',
            name: 'plans',
            builder: (context, state) => const PlansManagementScreen(),
          ),
          GoRoute(
            path: 'members',
            name: 'members',
            builder: (context, state) {
              final filter = state.uri.queryParameters['filter'];
              return MembersScreen(initialFilter: filter);
            },
          ),
          GoRoute(
            path: 'payments',
            name: 'payments',
            builder: (context, state) => const PaymentsHistoryScreen(),
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
    ],
  );
});
