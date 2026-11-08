import 'dart:html' as html;

/// Opens the link in a new browser tab.
Future<void> openExternalUrl(String url) async {
  final String target = url.trim();
  if (target.isEmpty) return;
  html.window.open(target, '_blank');
}
