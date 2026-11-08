import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/palette.dart';

/// Inline feedback strip shown above a form (server errors, success notices).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    Key? key,
    required this.message,
    this.isError = true,
  }) : super(key: key);

  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final Color color = isError ? Palette.danger : Palette.success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isError
                ? Icons.error_outline_rounded
                : Icons.check_circle_outline_rounded,
            size: 18,
            color: color,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                height: 1.4,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
