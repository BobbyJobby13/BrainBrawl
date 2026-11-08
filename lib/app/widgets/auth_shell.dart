import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../routes/app_pages.dart';
import '../../theme/palette.dart';
import 'brand_mark.dart';
import 'glow_background.dart';

/// Shared responsive frame for the login and registration screens.
///
/// Wide screens get a brand panel beside a floating form card; narrow screens
/// get a compact hero above the same card so nothing ever overflows.
class AuthShell extends StatelessWidget {
  const AuthShell({
    Key? key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
  }) : super(key: key);

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.background,
      body: GlowBackground(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= 1024;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Expanded(flex: 11, child: _BrandPanel()),
                    Expanded(
                      flex: 9,
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 48,
                          vertical: 40,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight: _floor(constraints.maxHeight - 80),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 460),
                              child: _FormCard(
                                eyebrow: eyebrow,
                                title: title,
                                subtitle: subtitle,
                                footer: footer,
                                dense: false,
                                child: child,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 36),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 480),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const _MobileHero(),
                        const SizedBox(height: 26),
                        _FormCard(
                          eyebrow: eyebrow,
                          title: title,
                          subtitle: subtitle,
                          footer: footer,
                          dense: true,
                          child: child,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

double _floor(double value) => value < 0 ? 0 : value;

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.child,
    required this.footer,
    required this.dense,
  });

  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget child;
  final Widget footer;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(dense ? 24 : 34),
      decoration: BoxDecoration(
        color: Palette.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 44,
            offset: const Offset(0, 22),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  eyebrow.toUpperCase(),
                  style: GoogleFonts.spaceMono(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.2,
                    color: Palette.pink,
                  ),
                ),
              ),
              const _CloseButton(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: dense ? 26 : 30,
              fontWeight: FontWeight.w700,
              height: 1.15,
              color: Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            subtitle,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13.5,
              height: 1.55,
              color: Palette.textSecondary,
            ),
          ),
          const SizedBox(height: 26),
          child,
          const SizedBox(height: 20),
          Container(height: 1, color: Palette.border),
          const SizedBox(height: 18),
          footer,
        ],
      ),
    );
  }
}

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Back to home',
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => Get.offAllNamed(Routes.HOME),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Palette.border),
          ),
          child: const Icon(
            Icons.close_rounded,
            size: 16,
            color: Palette.textFaint,
          ),
        ),
      ),
    );
  }
}

class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool compact = constraints.maxHeight < 880;
        final double headlineSize = compact ? 38 : 46;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(56, 40, 40, 40),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: _floor(constraints.maxHeight - 80),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const BrandMark(size: 38),
                SizedBox(height: compact ? 26 : 52),
                Text(
                  'Engage. Challenge.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: headlineSize,
                    fontWeight: FontWeight.w700,
                    height: 1.08,
                    letterSpacing: -1.2,
                    color: Palette.textPrimary,
                  ),
                ),
                ShaderMask(
                  shaderCallback: (Rect bounds) =>
                      Palette.brandGradient.createShader(bounds),
                  blendMode: BlendMode.srcIn,
                  child: Text(
                    'Triumph.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: headlineSize,
                      fontWeight: FontWeight.w700,
                      height: 1.08,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 16 : 22),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Text(
                    'Real-time 1v1 quiz battles between universities. Answer '
                    'fast, stay accurate, and knock out the competition one '
                    'round at a time.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: compact ? 14 : 15,
                      height: 1.6,
                      color: Palette.textSecondary,
                    ),
                  ),
                ),
                SizedBox(height: compact ? 22 : 34),
                const _FeatureRow(
                  icon: Icons.bolt_rounded,
                  title: 'Instant matchmaking',
                  description:
                      'Join a subject and get paired with a rival from another campus.',
                ),
                SizedBox(height: compact ? 14 : 20),
                const _FeatureRow(
                  icon: Icons.timer_outlined,
                  title: 'Speed meets accuracy',
                  description:
                      'Every round is timed — quick fingers only win with right answers.',
                ),
                SizedBox(height: compact ? 14 : 20),
                const _FeatureRow(
                  icon: Icons.emoji_events_outlined,
                  title: 'Knockout leaderboard',
                  description:
                      'Survive each bracket and climb until one campus champion is left.',
                ),
                SizedBox(height: compact ? 22 : 34),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: const [
                    _StatChip(value: '30–45s', label: 'per round'),
                    _StatChip(value: '1v1', label: 'live battles'),
                    _StatChip(value: 'KO', label: 'bracket format'),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MobileHero extends StatelessWidget {
  const _MobileHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const BrandMark(size: 30),
        const SizedBox(height: 22),
        ShaderMask(
          shaderCallback: (Rect bounds) =>
              Palette.brandGradient.createShader(bounds),
          blendMode: BlendMode.srcIn,
          child: Text(
            'Engage. Challenge. Triumph.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.6,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Real-time 1v1 quiz battles between universities.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13.5,
            height: 1.5,
            color: Palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _FeatureRow extends StatelessWidget {
  const _FeatureRow({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Palette.pink.withOpacity(0.12),
            border: Border.all(color: Palette.pink.withOpacity(0.28)),
          ),
          child: Icon(icon, size: 19, color: Palette.pink),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  height: 1.5,
                  color: Palette.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Palette.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: GoogleFonts.spaceMono(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Palette.pink,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: Palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// "Already have an account? Log in" style link shown under the form.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({
    Key? key,
    required this.prompt,
    required this.action,
    required this.onTap,
  }) : super(key: key);

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(
          prompt,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: Palette.textSecondary,
          ),
        ),
        const SizedBox(width: 4),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Text(
              action,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Palette.pink,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
