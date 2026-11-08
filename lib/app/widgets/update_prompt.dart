import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../platform/app_update.dart';
import '../../platform/update_checker.dart';
import '../../theme/palette.dart';
import '../app_version.dart';

/// Offers a newer desktop release and, if accepted, opens its download page.
///
/// Styled like the host console's dialogs so it belongs to the same app.
Future<void> showUpdatePrompt(BuildContext context, AppUpdate update) async {
  final bool? wantsDownload = await showDialog<bool>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Palette.border),
      ),
      title: Text(
        'Update available',
        style: GoogleFonts.spaceGrotesk(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Palette.textPrimary,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Brain Brawl ${update.version} is out. You are running $appVersion.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                height: 1.5,
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your saved teams, players and question bank stay as they are.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                height: 1.5,
                color: Palette.textSecondary,
              ),
            ),
            const SizedBox(height: 14),
            SelectableText(
              update.downloadUrl,
              style: GoogleFonts.spaceMono(
                fontSize: 11.5,
                color: Palette.textFaint,
              ),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(
            'Not now',
            style: GoogleFonts.spaceGrotesk(color: Palette.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: Text(
            'Download',
            style: GoogleFonts.spaceGrotesk(
              color: Palette.pink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );

  if (wantsDownload != true) return;

  final bool opened = await openDownloadPage(update.downloadUrl);
  if (!opened) {
    Get.snackbar(
      'Could not open the browser',
      'Open ${update.downloadUrl} to get the new version.',
      snackPosition: SnackPosition.BOTTOM,
    );
  }
}
