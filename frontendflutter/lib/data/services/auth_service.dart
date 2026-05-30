import 'dart:convert';
import 'dart:async';

import 'package:frontendflutter/core/constants.dart';
import 'package:frontendflutter/data/models/auth_models.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService()
    : _googleSignIn = GoogleSignIn(
        scopes: const ['email', 'profile'],
        serverClientId: AppConstants.googleWebClientId.isEmpty
            ? null
            : AppConstants.googleWebClientId,
      );

  final GoogleSignIn _googleSignIn;

  Future<GoogleUserProfile?> signInWithGoogle() async {
    try {
      return await _signInAndAuthenticateWithGoogle();
    } catch (_) {
      // Un único reintento cubre fallos transitorios del primer login.
      await Future.delayed(const Duration(milliseconds: 500));
      return await _signInAndAuthenticateWithGoogle();
    }
  }

  Future<GoogleUserProfile?> _signInAndAuthenticateWithGoogle() async {
    final account = await _googleSignIn.signIn().timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException('Google Sign-In tardó demasiado en responder.');
      },
    );
    if (account == null) {
      return null;
    }

    final authentication = await account.authentication.timeout(
      const Duration(seconds: 30),
      onTimeout: () {
        throw TimeoutException(
          'No se pudo obtener la autenticación de Google a tiempo.',
        );
      },
    );
    final idToken = authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw Exception('No se pudo obtener el idToken de Google.');
    }

    final response = await http
        .post(
          Uri.parse('${AppConstants.apiBaseUrl}/auth/google'),
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(<String, dynamic>{'id_token': idToken}),
        )
        .timeout(
          const Duration(seconds: 20),
          onTimeout: () {
            throw TimeoutException('El backend tardó demasiado en responder.');
          },
        );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Error autenticando con Google: ${response.statusCode} ${response.body}',
      );
    }

    final profile = GoogleUserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );

    return profile.copyWith(idToken: idToken);
  }

  Future<void> signOut() => _googleSignIn.signOut();
}
