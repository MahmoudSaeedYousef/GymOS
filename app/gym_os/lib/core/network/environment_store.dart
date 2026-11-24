import 'package:flutter_riverpod/legacy.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Predefined environments for GymOS.
enum ServerEnvironment {
  staging(
    label: 'Staging',
    url: 'https://dev-gym.orderly365.top',
  ),
  production(
    label: 'Production',
    url: 'https://gym.orderly365.top',
  ),
  local(
    label: 'Local (Emulator)',
    url: 'http://10.0.2.2:5158',
  ),
  custom(
    label: 'Custom',
    url: '',
  );

  final String label;
  final String url;

  const ServerEnvironment({required this.label, required this.url});

  static ServerEnvironment fromUrl(String url) {
    for (final env in ServerEnvironment.values) {
      if (env != ServerEnvironment.custom && env.url == url) {
        return env;
      }
    }
    return ServerEnvironment.custom;
  }
}

class EnvironmentState {
  final String baseUrl;
  final ServerEnvironment environment;
  final bool isCustom;

  const EnvironmentState({
    required this.baseUrl,
    required this.environment,
    this.isCustom = false,
  });

  EnvironmentState copyWith({
    String? baseUrl,
    ServerEnvironment? environment,
    bool? isCustom,
  }) {
    return EnvironmentState(
      baseUrl: baseUrl ?? this.baseUrl,
      environment: environment ?? this.environment,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

class EnvironmentNotifier extends StateNotifier<EnvironmentState> {
  static const _storageKey = 'api_base_url';
  static const defaultBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://gym.orderly365.top',
  );

  final FlutterSecureStorage _storage;

  EnvironmentNotifier({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage(),
        super(
          EnvironmentState(
            baseUrl: defaultBaseUrl,
            environment: ServerEnvironment.fromUrl(defaultBaseUrl),
            isCustom:
                ServerEnvironment.fromUrl(defaultBaseUrl) ==
                ServerEnvironment.custom,
          ),
        ) {
    _loadSavedEnvironment();
  }

  Future<void> _loadSavedEnvironment() async {
    final savedUrl = await _storage.read(key: _storageKey);
    if (savedUrl != null && savedUrl.isNotEmpty) {
      final env = ServerEnvironment.fromUrl(savedUrl);
      state = EnvironmentState(
        baseUrl: savedUrl,
        environment: env,
        isCustom: env == ServerEnvironment.custom,
      );
    }
  }

  /// Sets the server environment to one of the predefined options or custom URL.
  /// Persists the URL in secure storage.
  Future<void> setEnvironment(ServerEnvironment env, {String? customUrl}) async {
    final newUrl = (env == ServerEnvironment.custom ? customUrl : env.url)?.trim() ?? '';
    if (newUrl.isEmpty) return;

    await _storage.write(key: _storageKey, value: newUrl);

    state = EnvironmentState(
      baseUrl: newUrl,
      environment: env,
      isCustom: env == ServerEnvironment.custom,
    );
  }

  /// Resets back to default environment specified at compile time.
  Future<void> resetToDefault() async {
    await _storage.delete(key: _storageKey);
    state = EnvironmentState(
      baseUrl: defaultBaseUrl,
      environment: ServerEnvironment.fromUrl(defaultBaseUrl),
      isCustom:
          ServerEnvironment.fromUrl(defaultBaseUrl) == ServerEnvironment.custom,
    );
  }
}

final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, EnvironmentState>((ref) {
  return EnvironmentNotifier();
});

final serverBaseUrlProvider = Provider<String>((ref) {
  return ref.watch(environmentProvider).baseUrl;
});
