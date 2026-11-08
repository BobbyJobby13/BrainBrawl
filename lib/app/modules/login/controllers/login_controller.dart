import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../app_data.dart';
import '../../../routes/app_pages.dart';

class LoginController extends GetxController {
  static const String _loginUrl =
      'https://hackcbs-backend.onrender.com/login/';
  static const Duration _timeout = Duration(seconds: 20);

  final formKey = GlobalKey<FormState>();

  final TextEditingController usernameCtrl = TextEditingController();
  final TextEditingController passwordCtrl = TextEditingController();
  final FocusNode passwordFocus = FocusNode();

  final RxBool isSubmitting = false.obs;
  final RxString errorMessage = ''.obs;
  final RxBool justRegistered = false.obs;

  @override
  void onInit() {
    super.onInit();

    final dynamic args = Get.arguments;
    if (args is Map) {
      final dynamic name = args['username'];
      if (name is String && name.isNotEmpty) {
        usernameCtrl.text = name;
      }
      justRegistered.value = args['justRegistered'] == true;
    }

    _restoreUsername();
  }

  @override
  void onClose() {
    usernameCtrl.dispose();
    passwordCtrl.dispose();
    passwordFocus.dispose();
    super.onClose();
  }

  Future<void> _restoreUsername() async {
    if (usernameCtrl.text.isEmpty) {
      try {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        final String? saved = prefs.getString('username_value');
        if (saved != null && saved.isNotEmpty && usernameCtrl.text.isEmpty) {
          usernameCtrl.text = saved;
        }
      } catch (_) {
        // Pre-filling is optional; ignore storage failures.
      }
    }
    _focusPasswordSoon();
  }

  void _focusPasswordSoon() {
    if (usernameCtrl.text.isEmpty) return;
    Future<void>.delayed(const Duration(milliseconds: 400), () {
      if (!isClosed) {
        passwordFocus.requestFocus();
      }
    });
  }

  String? validateUsername(String? value) {
    if ((value ?? '').trim().isEmpty) return 'Enter your username';
    return null;
  }

  String? validatePassword(String? value) {
    if ((value ?? '').isEmpty) return 'Enter your password';
    return null;
  }

  Future<void> login() async {
    if (isSubmitting.value) return;
    FocusManager.instance.primaryFocus?.unfocus();
    errorMessage.value = '';

    if (!(formKey.currentState?.validate() ?? false)) {
      return;
    }

    final String name = usernameCtrl.text.trim();
    isSubmitting.value = true;
    String? failure;

    try {
      final http.MultipartRequest request =
          http.MultipartRequest('POST', Uri.parse(_loginUrl))
            ..fields.addAll(<String, String>{
              'username': name,
              'password': passwordCtrl.text,
            });

      final http.StreamedResponse response = await request.send().timeout(_timeout);
      final String body = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final dynamic decoded = jsonDecode(body);
        final dynamic token = decoded is Map ? decoded['access_token'] : null;

        if (token is String && token.isNotEmpty) {
          accessToken = token;
          username = name;
          player.value = name;

          final SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('username_value', name);
          final dynamic id = decoded['user_id'];
          if (id is int) {
            userId = id;
            await prefs.setInt('userId', id);
          }

          isSubmitting.value = false;
          Get.offAllNamed(Routes.COMPETITION);
          return;
        }

        failure = 'We could not complete your login. Please try again.';
      } else if (response.statusCode == 400 || response.statusCode == 401) {
        failure = 'Invalid username or password.';
      } else if (response.statusCode >= 500) {
        failure =
            'Brain Brawl is having trouble right now. Please try again shortly.';
      } else {
        failure = 'Login failed (${response.statusCode}). Please try again.';
      }
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
}
