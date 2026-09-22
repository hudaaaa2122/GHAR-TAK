import 'dart:async';
import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../constants/api_endpoints.dart';
import '../../core/config/app_config.dart';
import '../../core/network/api_client.dart';
import '../../core/network/api_response.dart';
import '../../core/storage/token_storage.dart';
import '../mock/mock_data.dart';
import '../models/models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

class AuthRepository {
  AuthRepository(this._api, this._storage);

  final ApiClient _api;
  final TokenStorage _storage;

  Future<UserModel> loginWithGoogle() async {
    if (AppConfig.useMockData) {
      final user = UserModel(
        id: MockData.demoUser.id,
        name: MockData.demoUser.name,
        email: MockData.demoUser.email ?? 'google.user@ghertak.com',
        phoneNo: MockData.demoUser.phoneNo,
        avatar: MockData.demoUser.avatar,
      );
      // Persist off the critical path — never block navigation (emulator freeze).
      unawaited(() async {
        try {
          await _storage.saveTokens(
            accessToken: 'mock_google_access_token',
            refreshToken: 'mock_google_refresh_token',
          );
          await _storage.saveUserJson(jsonEncode(user.toJson()));
        } catch (_) {}
      }());
      return user;
    }

    if (AppConfig.googleClientId.isEmpty) {
      throw ApiException('Google Sign-In is not configured');
    }

    final googleSignIn = GoogleSignIn(
      scopes: const ['email', 'profile'],
      // Web client ID → id_token audience matches backend GOOGLE_CLIENT_ID.
      serverClientId: AppConfig.googleClientId,
    );

    try {
      await googleSignIn.signOut();
    } catch (_) {}

    final account = await googleSignIn.signIn();
    if (account == null) {
      throw ApiException('Google sign-in cancelled');
    }

    final auth = await account.authentication;
    final idToken = auth.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw ApiException(
        'Could not get Google ID token. Ensure the app SHA-1 is registered '
        'in Google Cloud Console for this OAuth client.',
      );
    }

    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.google,
      body: {'id_token': idToken},
      mapData: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return _persistAuth(res);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    if (AppConfig.useMockData) {
      if (email.trim().isEmpty || password.trim().isEmpty) {
        throw ApiException('Email and password are required');
      }
      final user = MockData.demoUser;
      unawaited(() async {
        try {
          await _storage.saveTokens(
            accessToken: 'mock_access_token',
            refreshToken: 'mock_refresh_token',
          );
          await _storage.saveUserJson(jsonEncode(user.toJson()));
        } catch (_) {}
      }());
      return user;
    }

    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.login,
      body: {
        'email': email,
        'password': password,
        // Mobile app — backend skips reCAPTCHA unless portal == "customer"
        'portal': 'mobile',
      },
      mapData: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return _persistAuth(res);
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phoneNo,
    required String password,
    required String confirmPassword,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      if (password != confirmPassword) {
        throw ApiException('Passwords do not match');
      }
      return {
        'email': email,
        'message': 'Verification code sent (mock: 123456)',
      };
    }

    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.register,
      body: {
        'name': name,
        'email': email,
        'phone_no': phoneNo,
        'password': password,
        'confirm_password': confirmPassword,
      },
      mapData: (raw) =>
          raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{},
    );
    if (!res.success) {
      throw ApiException(res.detail ?? 'Registration failed');
    }
    return res.data ?? res.raw ?? {};
  }

  Future<UserModel> verifyRegistration({
    required String email,
    required String code,
  }) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      if (code.trim() != '123456') {
        throw ApiException('Invalid code. Use 123456 in mock mode.');
      }
      final user = UserModel(
        id: MockData.demoUser.id,
        name: MockData.demoUser.name,
        email: email,
        phoneNo: MockData.demoUser.phoneNo,
        avatar: MockData.demoUser.avatar,
      );
      await _storage.saveTokens(
        accessToken: 'mock_access_token',
        refreshToken: 'mock_refresh_token',
      );
      await _storage.saveUserJson(jsonEncode(user.toJson()));
      return user;
    }

    final res = await _api.post<Map<String, dynamic>>(
      ApiEndpoints.verifyRegistration,
      body: {'email': email, 'verification_code': code},
      mapData: (raw) => Map<String, dynamic>.from(raw as Map),
    );
    return _persistAuth(res);
  }

  Future<void> logout() async {
    if (!AppConfig.useMockData) {
      try {
        await _api.post(ApiEndpoints.logout);
      } catch (_) {}
    }
    await _storage.clear();
  }

  Future<UserModel?> restoreSession() async {
    final token = await _storage.accessToken;
    if (token == null) return null;
    final json = await _storage.userJson;
    if (json != null) {
      try {
        return UserModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
      } catch (_) {}
    }

    if (AppConfig.useMockData) {
      return MockData.demoUser;
    }

    try {
      final res = await _api.get<Map<String, dynamic>>(
        ApiEndpoints.userRead,
        mapData: (raw) => Map<String, dynamic>.from(raw as Map),
      );
      if (res.data != null) {
        final user = UserModel.fromJson(res.data!);
        await _storage.saveUserJson(jsonEncode(user.toJson()));
        return user;
      }
    } catch (_) {
      await _storage.clear();
    }
    return null;
  }

  Future<UserModel> _persistAuth(ApiResponse<Map<String, dynamic>> res) async {
    res.ensureSuccess('Authentication failed');
    final data = res.data ?? {};
    final access = data['access_token']?.toString();
    final refresh = data['refresh_token']?.toString() ?? '';
    if (access == null || access.isEmpty) {
      throw ApiException(res.detail ?? 'No access token returned');
    }
    await _storage.saveTokens(accessToken: access, refreshToken: refresh);
    final userRaw = data['user'];
    final user = userRaw is Map
        ? UserModel.fromJson(Map<String, dynamic>.from(userRaw))
        : UserModel(id: 0, email: data['email']?.toString());
    await _storage.saveUserJson(jsonEncode(user.toJson()));
    return user;
  }

  Future<void> resendVerification(String email) async {
    if (AppConfig.useMockData) {
      await Future<void>.delayed(const Duration(milliseconds: 200));
      return;
    }
    final res = await _api.post(
      ApiEndpoints.resendVerification,
      body: {'email': email},
    );
    res.ensureSuccess('Could not resend code');
  }
}
