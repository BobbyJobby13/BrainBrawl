import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../theme/palette.dart';

/// Labelled input used across the auth screens.
///
/// Password fields get their own visibility toggle, and every state of the
/// border is themed so focus, errors and disabled fields read clearly.
class AppTextField extends StatefulWidget {
  const AppTextField({
    Key? key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon,
    this.keyboardType,
    this.textInputAction = TextInputAction.next,
    this.obscure = false,
    this.validator,
    this.autofillHints,
    this.onSubmitted,
    this.onChanged,
    this.enabled = true,
    this.inputFormatters,
    this.focusNode,
  }) : super(key: key);

  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData? icon;
  final TextInputType? keyboardType;
  final TextInputAction textInputAction;
  final bool obscure;
  final String? Function(String?)? validator;
  final Iterable<String>? autofillHints;
  final void Function(String)? onSubmitted;
  final void Function(String)? onChanged;
  final bool enabled;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscure = false;

  @override
  void initState() {
    super.initState();
    _obscure = widget.obscure;
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            widget.label.toUpperCase(),
            style: GoogleFonts.spaceMono(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.8,
              color: Palette.textFaint,
            ),
          ),
        ),
        TextFormField(
          controller: widget.controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          obscureText: _obscure,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          autofillHints: widget.autofillHints,
          inputFormatters: widget.inputFormatters,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          validator: widget.validator,
          cursorColor: Palette.pink,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: Palette.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              color: Palette.textFaint,
            ),
            filled: true,
            fillColor: Palette.surfaceRaised,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
            prefixIcon: widget.icon == null
                ? null
                : Icon(widget.icon, size: 19, color: Palette.textFaint),
            suffixIcon: widget.obscure
                ? IconButton(
                    onPressed: () => setState(() => _obscure = !_obscure),
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(
                      _obscure
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      size: 19,
                      color: Palette.textFaint,
                    ),
                  )
                : null,
            border: _border(Palette.border),
            enabledBorder: _border(Palette.border),
            focusedBorder: _border(Palette.pink.withOpacity(0.75), 1.4),
            disabledBorder: _border(Palette.border),
            errorBorder: _border(Palette.danger.withOpacity(0.6)),
            focusedErrorBorder: _border(Palette.danger, 1.4),
            errorStyle: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              color: Palette.danger,
            ),
          ),
        ),
      ],
    );
  }
}
