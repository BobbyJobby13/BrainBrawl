/// Decides whether this process is the projector board or the host console.
///
/// The console shows the board by opening a second copy of the app, and that
/// copy has to work out which window it is. macOS does not always hand
/// command-line arguments to Dart's `main`, and `open -n` does not forward the
/// caller's environment, so the role travels through three channels at once:
/// `--display` in argv, `BRAINBRAWL_ROLE=display` in the environment, and a
/// marker file the console writes immediately before it launches the copy.
/// Any one of them is enough.
class DisplayMode {
  DisplayMode._();

  static const String roleKey = 'BRAINBRAWL_ROLE';
  static const String displayRole = 'display';
  static const String flag = '--display';

  /// A marker older than this is left over from an earlier attempt — honouring
  /// it would turn a window the host opened by hand into a display.
  static const Duration markerFreshness = Duration(seconds: 25);

  static bool isDisplayRequest({
    required List<String> args,
    required Map<String, String> environment,
    Duration? markerAge,
  }) {
    if (environment[roleKey] == displayRole) return true;
    if (args.contains(flag)) return true;
    if (markerAge != null &&
        !markerAge.isNegative &&
        markerAge < markerFreshness) {
      return true;
    }
    return false;
  }
}
