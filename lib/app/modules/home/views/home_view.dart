import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../routes/app_pages.dart';
import '../../../../theme/palette.dart';
import '../../../widgets/brand_mark.dart';
import '../../../widgets/glow_background.dart';
import '../../../widgets/key_west_lockup.dart';
import '../../../widgets/primary_button.dart';
import '../../about_us/about_us.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GlowBackground(
        child: SafeArea(
          bottom: false,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool isWide = constraints.maxWidth >= 960;
              final double hPad = isWide ? 56 : 22;

              return SingleChildScrollView(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1240),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 20, hPad, 0),
                          child: _TopBar(isWide: isWide),
                        ),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            hPad,
                            isWide ? 54 : 30,
                            hPad,
                            0,
                          ),
                          child: isWide
                              ? const _WideHero()
                              : const _NarrowHero(),
                        ),
                        SizedBox(height: isWide ? 58 : 34),
                        Padding(
                          padding: EdgeInsets.symmetric(horizontal: hPad),
                          child: _FeatureGrid(isWide: isWide),
                        ),
                        const SizedBox(height: 42),
                        Padding(
                          padding: EdgeInsets.fromLTRB(hPad, 0, hPad, 26),
                          child: const _FooterNote(),
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

class _TopBar extends StatelessWidget {
  const _TopBar({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const BrandMark(size: 34),
        const Spacer(),
        if (isWide) ...[
          _NavLink(
            label: 'Host console',
            onTap: () => Get.toNamed(Routes.HOST),
          ),
          const SizedBox(width: 4),
          _NavLink(
            label: 'About us',
            onTap: () => Get.to(() => AboutView()),
          ),
          const SizedBox(width: 4),
          _NavLink(
            label: 'Log in',
            onTap: () => Get.toNamed(Routes.LOGIN),
          ),
          const SizedBox(width: 14),
          _CtaPill(
            label: 'Create account',
            onTap: () => Get.toNamed(Routes.REGISTRATION),
          ),
        ] else ...[
          // The narrow hero already offers "I already have an account", so the
          // top bar keeps only the host shortcut and leaves room for the mark.
          _NavLink(
            label: 'Host',
            onTap: () => Get.toNamed(Routes.HOST),
          ),
        ],
        _TopRightLockup(isWide: isWide),
      ],
    );
  }
}

/// Key West mark with "Brain Brawl" beneath it, pinned to the top right.
class _TopRightLockup extends StatelessWidget {
  const _TopRightLockup({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Container(
          width: 1,
          height: isWide ? 42 : 34,
          margin: EdgeInsets.symmetric(horizontal: isWide ? 18 : 10),
          color: Palette.border,
        ),
        KeyWestLockup(logoSize: isWide ? 38 : 30),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        foregroundColor: Palette.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        textStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      child: Text(label),
    );
  }
}

class _CtaPill extends StatelessWidget {
  const _CtaPill({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Ink(
        decoration: BoxDecoration(
          gradient: Palette.brandGradient,
          borderRadius: BorderRadius.circular(100),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(100),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WideHero extends StatelessWidget {
  const _WideHero();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _LiveBadge(),
              const SizedBox(height: 22),
              const _Headline(size: 58),
              const SizedBox(height: 20),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Text(
                  'A 1v1 knockout quiz tournament for universities. Get matched '
                  'by subject, race the clock, and out-score your rival to '
                  'advance.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 16,
                    height: 1.65,
                    color: Palette.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 14,
                runSpacing: 12,
                children: [
                  SizedBox(
                    width: 244,
                    child: PrimaryButton(
                      label: 'Create your account',
                      onPressed: () => Get.toNamed(Routes.REGISTRATION),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: GhostButton(
                      label: 'Log in',
                      onPressed: () => Get.toNamed(Routes.LOGIN),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),
              const _TrustRow(),
            ],
          ),
        ),
        const SizedBox(width: 28),
        const Expanded(flex: 5, child: _ArenaVisual()),
      ],
    );
  }
}

class _NarrowHero extends StatelessWidget {
  const _NarrowHero();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Align(alignment: Alignment.centerLeft, child: _LiveBadge()),
        const SizedBox(height: 18),
        const _Headline(size: 36),
        const SizedBox(height: 14),
        Text(
          'A 1v1 knockout quiz tournament for universities. Get matched by '
          'subject, race the clock, and out-score your rival to advance.',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14.5,
            height: 1.6,
            color: Palette.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        PrimaryButton(
          label: 'Create your account',
          onPressed: () => Get.toNamed(Routes.REGISTRATION),
        ),
        const SizedBox(height: 12),
        GhostButton(
          label: 'I already have an account',
          onPressed: () => Get.toNamed(Routes.LOGIN),
        ),
        const SizedBox(height: 22),
        const _TrustRow(),
      ],
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (Rect bounds) =>
          Palette.headlineGradient.createShader(bounds),
      blendMode: BlendMode.srcIn,
      child: Text(
        'Engage. Challenge.\nTriumph.',
        style: GoogleFonts.spaceGrotesk(
          fontSize: size,
          fontWeight: FontWeight.w700,
          height: 1.06,
          letterSpacing: -1.2,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _LiveBadge extends StatelessWidget {
  const _LiveBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Palette.pink.withOpacity(0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Palette.pink.withOpacity(0.32)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Palette.pink,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'LIVE 1V1 · KNOCKOUT FORMAT',
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: Palette.pink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 18,
      runSpacing: 10,
      children: const [
        _TrustItem(
          icon: Icons.check_circle_outline_rounded,
          label: 'Free to join',
        ),
        _TrustItem(icon: Icons.school_outlined, label: 'Any university'),
        _TrustItem(
          icon: Icons.language_rounded,
          label: 'Runs in your browser',
        ),
      ],
    );
  }
}

class _TrustItem extends StatelessWidget {
  const _TrustItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 15, color: Palette.textFaint),
        const SizedBox(width: 7),
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            color: Palette.textSecondary,
          ),
        ),
      ],
    );
  }
}

class _ArenaVisual extends StatelessWidget {
  const _ArenaVisual();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: SizedBox(
          width: 400,
          height: 400,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.border),
                  gradient: RadialGradient(
                    colors: [
                      Palette.violet.withOpacity(0.16),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              Container(
                width: 310,
                height: 310,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Palette.pink.withOpacity(0.22)),
                ),
              ),
              Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      Palette.pink.withOpacity(0.30),
                      Palette.pink.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
              Container(
                width: 168,
                height: 168,
                padding: const EdgeInsets.all(26),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Palette.surface.withOpacity(0.85),
                  border: Border.all(color: Palette.pink.withOpacity(0.35)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/brain_mark.png',
                  fit: BoxFit.contain,
                ),
              ),
              const Positioned(
                top: 22,
                right: 46,
                child: _FloatChip(
                  icon: Icons.timer_outlined,
                  label: '30s rounds',
                ),
              ),
              const Positioned(
                bottom: 34,
                left: 10,
                child: _FloatChip(
                  icon: Icons.sports_esports_outlined,
                  label: '1v1 live',
                ),
              ),
              const Positioned(
                bottom: 92,
                right: 0,
                child: _FloatChip(
                  icon: Icons.emoji_events_outlined,
                  label: 'Knockout',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FloatChip extends StatelessWidget {
  const _FloatChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: Palette.surfaceRaised.withOpacity(0.95),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Palette.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Palette.pink),
          const SizedBox(width: 7),
          Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  const _Feature({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;
}

const List<_Feature> _features = <_Feature>[
  _Feature(
    icon: Icons.bolt_rounded,
    title: 'Live 1v1 matchmaking',
    description:
        'Join a subject and get paired with a rival from another campus in seconds.',
  ),
  _Feature(
    icon: Icons.timer_outlined,
    title: 'Speed meets accuracy',
    description:
        'Every round is timed — quick answers only count when they are right.',
  ),
  _Feature(
    icon: Icons.emoji_events_outlined,
    title: 'Knockout to the crown',
    description:
        'Win your bracket, climb the leaderboard, and finish as your campus champion.',
  ),
];

class _FeatureGrid extends StatelessWidget {
  const _FeatureGrid({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (isWide) {
      return IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (int i = 0; i < _features.length; i++) ...[
              if (i > 0) const SizedBox(width: 18),
              Expanded(child: _FeatureCard(feature: _features[i])),
            ],
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _features.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          _FeatureCard(feature: _features[i]),
        ],
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({required this.feature});

  final _Feature feature;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: Palette.surface.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Palette.pink.withOpacity(0.12),
              border: Border.all(color: Palette.pink.withOpacity(0.28)),
            ),
            child: Icon(feature.icon, size: 20, color: Palette.pink),
          ),
          const SizedBox(height: 16),
          Text(
            feature.title,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Palette.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            feature.description,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              height: 1.55,
              color: Palette.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _FooterNote extends StatelessWidget {
  const _FooterNote();

  @override
  Widget build(BuildContext context) {
    const TextStyle style = TextStyle(
      fontSize: 12,
      color: Palette.textFaint,
      height: 1.5,
    );

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 8,
      children: const [
        Text('© 2026 Brain Brawl', style: style),
        Text('·', style: style),
        Text('Built for campus champions', style: style),
      ],
    );
  }
}
