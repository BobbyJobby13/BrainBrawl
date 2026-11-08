import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/palette.dart';

/// Circular brain badge with an optional "BRAIN BRAWL" wordmark.
class BrandMark extends StatelessWidget {
  const BrandMark({
    Key? key,
    this.size = 36,
    this.showWordmark = true,
  }) : super(key: key);

  final double size;
  final bool showWordmark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.13),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Palette.pink.withOpacity(0.30),
                Palette.violet.withOpacity(0.20),
              ],
            ),
            border: Border.all(color: Palette.pink.withOpacity(0.45)),
          ),
          child: Image.asset(
            'assets/images/brain_mark.png',
            fit: BoxFit.contain,
          ),
        ),
        if (showWordmark) ...[
          SizedBox(width: size * 0.34),
          Text(
            'BRAIN BRAWL',
            style: GoogleFonts.spaceMono(
              fontSize: size * 0.34,
              fontWeight: FontWeight.w700,
              letterSpacing: size * 0.055,
              color: Palette.textPrimary,
            ),
          ),
        ],
      ],
    );
  }
}
