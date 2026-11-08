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
import '../controllers/registration_controller.dart';

class RegistrationView extends GetView<RegistrationController> {
  const RegistrationView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      eyebrow: 'Join the arena',
      title: 'Create your account',
      subtitle:
          'One account for every tournament. Sign up now, then log straight in '
          'and take your first match.',
      footer: AuthSwitchLink(
        prompt: 'Already registered?',
        action: 'Log in instead',
        onTap: () => Get.offAllNamed(Routes.LOGIN),
      ),
      child: Form(
        key: controller.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
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
              hint: 'quizmaster',
              icon: Icons.person_outline_rounded,
              autofillHints: const <String>[AutofillHints.newUsername],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: controller.validateUsername,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: controller.emailCtrl,
              label: 'Email',
              hint: 'you@university.edu',
              icon: Icons.alternate_email_rounded,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const <String>[AutofillHints.email],
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.deny(RegExp(r'\s')),
              ],
              validator: controller.validateEmail,
            ),
            const SizedBox(height: 18),
            AppTextField(
              controller: controller.passwordCtrl,
              label: 'Password',
              hint: 'At least 6 characters',
              icon: Icons.lock_outline_rounded,
              obscure: true,
              autofillHints: const <String>[AutofillHints.newPassword],
              onChanged: controller.onPasswordChanged,
              validator: controller.validatePassword,
            ),
            Obx(() {
              // Always read the observable first: returning early without it
              // makes GetX treat this builder as improperly scoped.
              final double strength = controller.passwordStrength.value;
              if (controller.passwordCtrl.text.isEmpty) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(top: 10, left: 4, right: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: strength,
                        minHeight: 4,
                        backgroundColor: Palette.border,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          _strengthColor(strength),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      controller.strengthLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        color: Palette.textFaint,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 18),
            AppTextField(
              controller: controller.confirmCtrl,
              label: 'Confirm password',
              hint: 'Repeat your password',
              icon: Icons.verified_user_outlined,
              obscure: true,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => controller.register(),
              validator: controller.validateConfirm,
            ),
            const SizedBox(height: 26),
            Obx(
              () => PrimaryButton(
                label: 'Create account',
                isLoading: controller.isSubmitting.value,
                onPressed: controller.register,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_outline_rounded,
                  size: 14,
                  color: Palette.textFaint,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your details are only used for matchmaking and scoring.',
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

  Color _strengthColor(double strength) {
    if (strength < 0.4) return Palette.danger;
    if (strength < 0.7) return Palette.cyan;
    return Palette.success;
  }
}
