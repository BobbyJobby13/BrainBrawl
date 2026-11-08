import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/palette.dart';

/// Bordered panel used for every section of the host console.
class ConsoleCard extends StatelessWidget {
  const ConsoleCard({
    Key? key,
    this.title,
    this.subtitle,
    this.trailing,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  }) : super(key: key);

  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Palette.surface.withOpacity(0.88),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.border),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (title != null)
            LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final Widget heading = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title!,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Palette.textPrimary,
                      ),
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          subtitle!,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12,
                            color: Palette.textFaint,
                          ),
                        ),
                      ),
                  ],
                );

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: heading),
                    if (trailing != null)
                      // Cap the actions at just over half the card so a long
                      // label wraps or truncates instead of overflowing.
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth * 0.56,
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: trailing!,
                        ),
                      ),
                  ],
                );
              },
            ),
          if (title != null) const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// Small uppercase monospace label, the console's section marker.
class MonoLabel extends StatelessWidget {
  const MonoLabel(this.text, {Key? key, this.color = Palette.textFaint, this.size = 10})
      : super(key: key);

  final String text;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: GoogleFonts.spaceMono(
        fontSize: size,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.6,
        color: color,
      ),
    );
  }
}

/// Rounded status/metadata chip.
class Pill extends StatelessWidget {
  const Pill({
    Key? key,
    required this.label,
    this.color = Palette.textSecondary,
    this.icon,
  }) : super(key: key);

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 5),
          ],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.spaceMono(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact bordered action used for host controls.
class MiniAction extends StatelessWidget {
  const MiniAction({
    Key? key,
    required this.label,
    this.onTap,
    this.icon,
    this.color = Palette.textPrimary,
    this.filled = false,
  }) : super(key: key);

  final String label;
  final VoidCallback? onTap;
  final IconData? icon;
  final Color color;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final bool enabled = onTap != null;
    return Material(
      color: filled
          ? color.withOpacity(enabled ? 0.18 : 0.06)
          : Colors.white.withOpacity(enabled ? 0.04 : 0.02),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: color.withOpacity(enabled ? 0.35 : 0.12),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (icon != null) ...<Widget>[
                Icon(icon, size: 14, color: color.withOpacity(enabled ? 1 : 0.4)),
                const SizedBox(width: 6),
              ],
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: color.withOpacity(enabled ? 1 : 0.4),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Icon-only action for rows that are tight on horizontal space.
class MiniIconAction extends StatelessWidget {
  const MiniIconAction({
    Key? key,
    required this.icon,
    this.onTap,
    this.color = Palette.textSecondary,
    this.tooltip,
  }) : super(key: key);

  final IconData icon;
  final VoidCallback? onTap;
  final Color color;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final Widget button = Material(
      color: Colors.white.withOpacity(onTap == null ? 0.02 : 0.04),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withOpacity(onTap == null ? 0.12 : 0.3)),
          ),
          child: Icon(
            icon,
            size: 15,
            color: color.withOpacity(onTap == null ? 0.4 : 1),
          ),
        ),
      ),
    );
    if (tooltip == null) return button;
    return Tooltip(message: tooltip!, child: button);
  }
}

/// Simple single/multi-line text prompt. Returns null when cancelled.
Future<String?> askForText(
  BuildContext context, {
  required String title,
  String initial = '',
  String hint = '',
  String confirmLabel = 'Save',
  int maxLines = 1,
}) async {
  final TextEditingController textController =
      TextEditingController(text: initial);
  final String? result = await showDialog<String>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Palette.textPrimary,
        ),
      ),
      content: TextField(
        controller: textController,
        autofocus: true,
        maxLines: maxLines,
        cursorColor: Palette.pink,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: Palette.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.spaceGrotesk(
            fontSize: 13,
            color: Palette.textFaint,
          ),
          filled: true,
          fillColor: Palette.surface,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Palette.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Palette.pink.withOpacity(0.7)),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Cancel',
            style: GoogleFonts.spaceGrotesk(color: Palette.textSecondary),
          ),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(dialogContext).pop(textController.text.trim()),
          child: Text(
            confirmLabel,
            style: GoogleFonts.spaceGrotesk(
              color: Palette.pink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
  textController.dispose();
  if (result == null || result.trim().isEmpty) return null;
  return result.trim();
}

/// Scrollable help dialog used for the buzzer protocol and the paste format.
Future<void> showHelp(
  BuildContext context, {
  required String title,
  required String body,
}) {
  return showDialog<void>(
    context: context,
    builder: (BuildContext dialogContext) => AlertDialog(
      backgroundColor: Palette.surfaceRaised,
      title: Text(
        title,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Palette.textPrimary,
        ),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          child: Text(
            body,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              height: 1.55,
              color: Palette.textSecondary,
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(),
          child: Text(
            'Got it',
            style: GoogleFonts.spaceGrotesk(
              color: Palette.pink,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    ),
  );
}
