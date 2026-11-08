import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/palette.dart';

/// The team lockup that sits in the top-right corner: the Key West mark with
/// "Brain Brawl" beneath it.
///
/// The official artwork is not in the repository, so this looks for
/// `assets/images/keywest_logo.png` and falls back to a KW monogram until that
/// file is added. `assets/images/` is already bundled as a directory in
/// pubspec.yaml, so dropping the PNG in is enough — no code change, no pubspec
/// edit, and no build failure while it is missing.
class KeyWestLockup extends StatelessWidget {
  const KeyWestLockup({Key? key, this.logoSize = 36, this.showWordmark = true})
      : super(key: key);

  /// Path the official logo should be saved to.
  static const String logoAsset = 'assets/images/keywest_logo.png';

  final double logoSize;
  final bool showWordmark;

  static bool? _logoExists;

  static Future<bool> _resolveLogo() async {
    if (_logoExists != null) return _logoExists!;
    try {
      await rootBundle.load(logoAsset);
      _logoExists = true;
    } catch (_) {
      _logoExists = false;
    }
    return _logoExists!;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _resolveLogo(),
      builder: (BuildContext context, AsyncSnapshot<bool> snapshot) {
        final bool hasLogo = snapshot.data == true;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            SizedBox(
              height: logoSize,
              child: hasLogo
                  ? Image.asset(
                      logoAsset,
                      height: logoSize,
                      fit: BoxFit.contain,
                      // A corrupt or unsupported file must not take the header
                      // down with it.
                      errorBuilder: (_, __, ___) => _Monogram(size: logoSize),
                    )
                  : _Monogram(size: logoSize),
            ),
            if (showWordmark) ...<Widget>[
              const SizedBox(height: 4),
              Text(
                'Brain Brawl',
                textAlign: TextAlign.center,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: logoSize >= 34 ? 10 : 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.1,
                  height: 1.1,
                  color: Palette.textSecondary,
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}

/// Placeholder used until the official Key West file is in place.
class _Monogram extends StatelessWidget {
  const _Monogram({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Palette.surfaceRaised,
        border: Border.all(color: Palette.pink.withOpacity(0.45)),
      ),
      child: Text(
        'KW',
        style: GoogleFonts.spaceMono(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: Palette.pink,
        ),
      ),
    );
  }
}
