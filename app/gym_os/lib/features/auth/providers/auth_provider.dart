import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:gym_os/features/auth/services/auth_service.dart';

// حالات المصادقة
enum AuthStatus { initial, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String? token;

  AuthState({required this.status, this.token});
}

class AuthNotifier extends StateNotifier<AuthState> {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final AuthService _authService;
  static const _tokenKey = 'jwt_token';

  AuthNotifier(this._authService)
    : super(AuthState(status: AuthStatus.initial)) {
    _checkAuthStatus();
  }
  // فحص التوكن عند فتح التطبيق
  Future<void> _checkAuthStatus() async {
    final token = await _storage.read(key: _tokenKey);
    if (token != null && token.isNotEmpty) {
      // (مستقبلاً هنا ممكن نضيف كود يتأكد إن التوكن لسه صالح ومش Expired)
      state = AuthState(status: AuthStatus.authenticated, token: token);
    } else {
      state = AuthState(status: AuthStatus.unauthenticated);
    }
  }

  // تعديل دالة تسجيل الدخول
  Future<void> login(String phone, String password) async {
    try {
      // 1. نكلم الباك إند ونجيب التوكن
      final token = await _authService.login(phone, password);

      // 2. نحفظه بأمان في الجهاز
      await _storage.write(key: _tokenKey, value: token);

      // 3. نحدث حالة التطبيق (وبالتالي الـ Router هينقلنا للشاشة الرئيسية فوراً)
      state = AuthState(status: AuthStatus.authenticated, token: token);
    } catch (e) {
      // هنا بنرفع الخطأ للـ UI عشان نظهر رسالة للمستخدم
      rethrow;
    }
  }

  // تسجيل الخروج
  Future<void> logout() async {
    await _storage.delete(key: _tokenKey);
    state = AuthState(status: AuthStatus.unauthenticated);
  }
}

// الـ Provider اللي هنقرأ منه في الـ UI والـ Router
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(authServiceProvider);
  return AuthNotifier(authService);
});
