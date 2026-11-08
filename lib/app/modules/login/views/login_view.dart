import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_pages.dart';
import '../../../../theme/palette.dart';
import '../../../widgets/app_text_field.dart';
import '../../../widgets/auth_shell.dart';
import '../../../widgets/primary_button.dart';
import '../../../widgets/status_banner.dart';
import '../controllers/login_controller.dart';

class LoginView extends GetView<LoginController> {
  const LoginView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Welcome back',
      title: 'Log in to your arena',
      subtitle:
          'Your username is ready to go — just enter your password and jump '
          'back into the bracket.',
      footer: AuthSwitchLink(
        prompt: 'New to Brain Brawl?',
        action: 'Create an account',
        onTap: () => Get.offAllNamed(Routes.REGISTRATION),
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Obx(
              () => controller.justRegistered.value
                  ? const Padding(
                      padding: EdgeInsets.only(bottom: 18),
                      child: StatusBanner(
                        message:
                            'Account created. Log in below to enter your first match.',
                        isError: false,
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
            Obx(
              () => controller.errorMessage.value.isEmpty
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(bottom: 18),
                      child: StatusBanner(
                        message: controller.errorMessage.value,
                      ),
                    ),
            ),
            AppTextField(
              controller: controller.usernameCtrl,
              label: 'Username',
              hint: 'your username',
              icon: Icons.person_outline_rounded,
              autofillHints: const <String>[AutofillHints.username],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: controller.validateUsername,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: controller.passwordCtrl,
              focusNode: controller.passwordFocus,
              label: 'Password',
              hint: 'your password',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              textInputAction: TextInputAction.done,
              autofillHints: const <String>[AutofillHints.password],
              onSubmitted: (_) => controller.login(),
              validator: controller.validatePassword,
            ),
            const SizedBox(height: 26),
            Obx(
              () => PrimaryButton(
                label: 'Log in',
                isLoading: controller.isSubmitting.value,
                onPressed: controller.login,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 14,
                  color: Palette.textFaint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Use the same username and password you registered with.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      height: 1.4,
                      color: Palette.textFaint,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
