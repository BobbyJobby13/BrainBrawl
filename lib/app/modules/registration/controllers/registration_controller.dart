import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../routes/app_pages.dart';

class RegistrationController extends GetxController {
  static const String _registerUrl =
      'https://hackcbs-backend.onrender.com/register/';
  static const Duration _timeout = Duration(seconds: 20);

  final formKey = GlobalKey<FormState>();

  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController emailCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final TextEditingController confirmCtrl = TextEditingController();

  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble passwordStrength = 0.0.obs;

  @override
  void onClose() {
    usernameCtrl.dispose();
    emailCtrl.dispose();
    passwordCtrl.dispose();
    confirmCtrl.dispose();
    super.onClose();
  }

  void onPasswordChanged(String value) {
    passwordStrength.value = _scorePassword(value);
  }

  double _scorePassword(String value) {
    if (value.isEmpty) {
      return 0;
    }
    int score = 0;
    if (value.length >= 6) score++;
    if (value.length >= 10) score++;
    if (RegExp(r'[a-z]').hasMatch(value) &&
        RegExp(r'[A-Z]').hasMatch(value)) {
      score++;
    }
    if (RegExp(r'[0-9]').hasMatch(value)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(value)) score++;
    return (score / 5).clamp(0.08, 1.0).toDouble();
  }

  String get strengthLabel {
    final double value = passwordStrength.value;
    if (value <= 0) return '';
    if (value < 0.4) return 'Weak — try a few more characters';
    if (value < 0.7) return 'Decent — add a number or symbol';
    if (value < 1) return 'Strong password';
    return 'Excellent password';
  }

  String? validateUsername(String? value) {
    final String name = (value ?? '').trim();
    if (name.isEmpty) return 'Pick a username';
    if (name.length < 3) return 'At least 3 characters';
    if (name.length > 20) return 'Keep it under 20 characters';
    if (!RegExp(r'^[A-Za-z0-9._]+$').hasMatch(name)) {
      return 'Use letters, numbers, dots or underscores';
    }
    return null;
  }

  String? validateEmail(String? value) {
    final String email = (value ?? '').trim();
    if (email.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$').hasMatch(email)) {
      return 'That email does not look right';
    }
    return null;
  }

  String? validatePassword(String? value) {
    final String password = value ?? '';
    if (password.isEmpty) return 'Create a password';
    if (password.length < 6) return 'Use at least 6 characters';
    return null;
  }

  String? validateConfirm(String? value) {
    final String confirm = value ?? '';
    if (confirm.isEmpty) return 'Re-enter your password';
    if (confirm != passwordCtrl.text) return 'Passwords do not match';
    return null;
  }

  Future<void> register() async {
    if (isSubmitting.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = '';

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String username = usernameCtrl.text.trim();
    final String email = emailCtrl.text.trim();

    isSubmitting.value = true;
    String? failure;

    try {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(_registerUrl))
            ..fields.addAll(<String, String>{
              'username': username,
              'email': email,
              'password': passwordCtrl.text,
            });

      final http.StreamedResponse response = await request.send().timeout(_timeout);
      final String body = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        await _rememberUsername(username);
        isSubmitting.value = false;
        // Registration is done — the only step left is logging in, so hand the
        // username over and pre-fill it for them.
        Get.offAllNamed(Routes.LOGIN, arguments: <String, dynamic>{
          'username': username,
          'justRegistered': true,
        });
        return;
      }

      failure = _messageFor(body, response.statusCode);
    } on TimeoutException {
      failure =
          'The server took too long to respond. Check your connection and try again.';
    } catch (_) {
      failure =
          "We couldn't reach Brain Brawl right now. Please try again in a moment.";
    }

    errorMessage.value = failure;
    isSubmitting.value = false;
  }

  Future<void> _rememberUsername(String username) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('username_value', username);
    } catch (_) {
      // Pre-filling the login form is a convenience, never a blocker.
    }
  }

  String _messageFor(String body, int statusCode) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map) {
        final List<String> usernameErrors = _errorsFor(decoded, 'username');
        final List<String> emailErrors = _errorsFor(decoded, 'email');
        final List<String> passwordErrors = _errorsFor(decoded, 'password');

        if (usernameErrors.isNotEmpty && emailErrors.isNotEmpty) {
          return 'That username and email are both already in use. Try another pair.';
        }
        if (usernameErrors.isNotEmpty) {
          return 'That username is already taken — pick another one.';
        }
        if (emailErrors.isNotEmpty) {
          return 'That email is already registered. Try logging in instead.';
        }
        if (passwordErrors.isNotEmpty) {
          return passwordErrors.first;
        }

        final List<String> generalErrors =
            _errorsFor(decoded, 'non_field_errors');
        if (generalErrors.isNotEmpty) return generalErrors.first;
        if (decoded['msg'] is String) return decoded['msg'] as String;
        if (decoded['detail'] is String) return decoded['detail'] as String;
      }
    } catch (_) {
      // Non-JSON body (server error page) — fall through to a generic message.
    }

    if (statusCode >= 500) {
      return 'Brain Brawl is having trouble right now. Please try again shortly.';
    }
    return 'Registration failed. Check your details and try again.';
  }

  List<String> _errorsFor(Map<dynamic, dynamic> decoded, String key) {
    final dynamic raw = decoded[key];
    if (raw is List) {
      return raw.map((dynamic item) => item.toString()).toList();
    }
    if (raw is String && raw.isNotEmpty) {
      return <String>[raw];
    }
    return const <String>[];
  }
}
