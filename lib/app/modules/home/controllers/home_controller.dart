import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../app_version.dart';
import '../../../../platform/app_update.dart';
import '../../../../platform/update_checker.dart';
import '../../../widgets/update_prompt.dart';

class HomeController extends GetxController {
  //TODO: Implement HomeController

  final count = 0.obs;

  /// The landing page can be rebuilt or revisited after logging out; the check
  /// runs at most once per app launch so we never hammer the GitHub API.
  static bool _checkedForUpdate = false;

  @override
  void onInit() {
    super.onInit();
  }

  @override
  void onReady() {
    super.onReady();
    _offerUpdateIfAvailable();
  }

  @override
  void onClose() {
    super.onClose();
  }

  void increment() => count.value++;

  Future<void> _offerUpdateIfAvailable() async {
    if (_checkedForUpdate) return;
    _checkedForUpdate = true;

    final AppUpdate? update = await checkForAppUpdate(appVersion);
    if (update == null) return;

    final BuildContext? context = Get.context;
    if (context == null) return;
    await showUpdatePrompt(context, update);
  }
}
