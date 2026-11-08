import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../platform/live_link.dart';
import '../../../../theme/palette.dart';
import '../../../widgets/glow_background.dart';
import '../../../widgets/key_west_lockup.dart';
import 'console_widgets.dart';

/// The board the players and the audience read off the projector.
///
/// It runs in its own window — a second copy of the app started with
/// `--display` — because Flutter runs one window per process. The host console
/// publishes the game state; this view only ever renders it, so nothing on the
/// projector can change a score.
class PlayerDisplayView extends StatefulWidget {
  const PlayerDisplayView({Key? key}) : super(key: key);

  @override
  State<PlayerDisplayView> createState() => _PlayerDisplayViewState();
}

class _PlayerDisplayViewState extends State<PlayerDisplayView> {
  final LiveLink _link = LiveLink();

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: StreamBuilder<Map<String, dynamic>>(
          stream: _link.watch(),
          builder: (BuildContext context,
              AsyncSnapshot<Map<String, dynamic>> snapshot) {
            final Map<String, dynamic>? state = snapshot.data;
            return LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double edge =
                    (constraints.maxWidth * 0.03).clamp(14.0, 56.0).toDouble();
                final bool stale = state != null &&
                    DateTime.now().millisecondsSinceEpoch -
                            ((state['at'] as num?)?.toInt() ?? 0) >
                        4000;
                return Stack(
                  children: <Widget>[
                    Padding(
                      padding:
                          EdgeInsets.fromLTRB(edge, edge, edge, edge * 0.55),
                      child: state == null
                          ? _Waiting(width: constraints.maxWidth)
                          : PlayerBoard(state: state, width: constraints.maxWidth),
                    ),
                    if (stale)
                      Positioned(
                        top: edge,
                        right: edge,
                        child: const Pill(
                          label: 'WAITING FOR HOST',
                          color: Palette.textFaint,
                          icon: Icons.link_off_rounded,
                        ),
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}

/// Shown until the console publishes its first board.
class _Waiting extends StatelessWidget {
  const _Waiting({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    final double s = (width / 1100).clamp(0.8, 1.7).toDouble();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const KeyWestLockup(logoSize: 64),
          SizedBox(height: 20 * s),
          Text(
            'Brain Brawl',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 40 * s,
              fontWeight: FontWeight.w700,
              color: Palette.textPrimary,
            ),
          ),
          SizedBox(height: 10 * s),
          MonoLabel('Waiting for the host console', color: Palette.cyan, size: 14 * s),
          SizedBox(height: 18 * s),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: 620 * s),
            child: Text(
              'Start a game on the console and this board follows it: the '
              'question, the clock, the scores and the buzz-in code.',
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 16 * s,
                height: 1.5,
                color: Palette.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The board itself, separated from the window plumbing so it can be laid out
/// at a projector's resolution in a test.
class PlayerBoard extends StatelessWidget {
  const PlayerBoard({Key? key, required this.state, required this.width})
      : super(key: key);

  final Map<String, dynamic> state;
  final double width;

  @override
  Widget build(BuildContext context) {
    final double s = (width / 1200).clamp(0.72, 1.9).toDouble();
    final List<dynamic> teams =
        (state['teams'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> choices =
        (state['choices'] as List<dynamic>?) ?? const <dynamic>[];
    final List<dynamic> hints =
        (state['hints'] as List<dynamic>?) ?? const <dynamic>[];

    final String prompt = (state['prompt'] ?? '').toString();
    final String answer = (state['answer'] ?? '').toString();
    final String pack = (state['pack'] ?? '').toString();
    final String bonus = (state['bonus'] ?? '').toString();
    final String buzz = (state['buzz'] ?? '').toString();
    final String code = (state['buzzin'] ?? '').toString();

    final int index = (state['index'] as num?)?.toInt() ?? -1;
    final int total = (state['total'] as num?)?.toInt() ?? 0;
    final int points = (state['points'] as num?)?.toInt() ?? 0;
    final int remaining = (state['remaining'] as num?)?.toInt() ?? 0;
    final int seconds = (state['seconds'] as num?)?.toInt() ?? 0;
    final bool running = state['running'] == true;
    final bool expired = state['expired'] == true;
    final bool lightning = state['lightning'] == true;
    final bool low = remaining <= 5 && running;
    final double fraction =
        seconds <= 0 ? 0 : (remaining / seconds).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const KeyWestLockup(logoSize: 46),
            SizedBox(width: 14 * s),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  MonoLabel('Key West NJROTC', color: Palette.pink, size: 11 * s),
                  Text(
                    'Brain Brawl',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 26 * s,
                      fontWeight: FontWeight.w700,
                      color: Palette.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            if (lightning)
              Padding(
                padding: EdgeInsets.only(right: 8 * s, bottom: 4),
                child: const Pill(
                  label: 'LIGHTNING ROUND',
                  color: Palette.violet,
                  icon: Icons.bolt_rounded,
                ),
              ),
            if (bonus.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(right: 8 * s, bottom: 4),
                child: Pill(
                  label: 'BONUS · ${bonus.toUpperCase()}',
                  color: Palette.success,
                  icon: Icons.star_rounded,
                ),
              ),
            if (code.isNotEmpty)
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16 * s, vertical: 8 * s),
                decoration: BoxDecoration(
                  color: Palette.surface.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Palette.cyan.withOpacity(0.5),
                    width: 1.2,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    MonoLabel('Buzz in at buzzin.live', color: Palette.cyan, size: 9.5 * s),
                    Text(
                      code,
                      style: GoogleFonts.spaceMono(
                        fontSize: 28 * s,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 4 * s,
                        color: Palette.cyan,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        SizedBox(height: 16 * s),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            Pill(
              label: 'QUESTION ${index < 0 ? 1 : index + 1} OF $total',
              color: Palette.textSecondary,
            ),
            if (pack.isNotEmpty) Pill(label: pack.toUpperCase(), color: Palette.violet),
            Pill(label: '$points PTS', color: Palette.cyan),
            if (buzz.isNotEmpty)
              Pill(label: 'BUZZ · ${buzz.toUpperCase()}', color: Palette.pink, icon: Icons.bolt_rounded),
          ],
        ),
        SizedBox(height: 18 * s),
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                children: <Widget>[
                  Text(
                    prompt,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: (34 * s).clamp(22.0, 66.0).toDouble(),
                      height: 1.22,
                      fontWeight: FontWeight.w600,
                      color: Palette.textPrimary,
                    ),
                  ),
                  if (choices.isNotEmpty) ...<Widget>[
                    SizedBox(height: 22 * s),
                    Wrap(
                      spacing: 12 * s,
                      runSpacing: 10 * s,
                      alignment: WrapAlignment.center,
                      children: <Widget>[
                        for (int i = 0; i < choices.length; i++)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 16 * s,
                              vertical: 10 * s,
                            ),
                            decoration: BoxDecoration(
                              color: Palette.surface.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Palette.border),
                            ),
                            child: Text(
                              '${i + 1}. ${choices[i]}',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 20 * s,
                                color: Palette.textPrimary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                  if (hints.isNotEmpty) ...<Widget>[
                    SizedBox(height: 20 * s),
                    for (final dynamic hint in hints)
                      Padding(
                        padding: EdgeInsets.only(bottom: 6 * s),
                        child: Text(
                          'HINT · $hint',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.spaceMono(
                            fontSize: 13 * s,
                            color: Palette.textSecondary,
                          ),
                        ),
                      ),
                  ],
                  if (answer.isNotEmpty) ...<Widget>[
                    SizedBox(height: 20 * s),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 20 * s,
                        vertical: 14 * s,
                      ),
                      decoration: BoxDecoration(
                        color: Palette.cyan.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Palette.cyan.withOpacity(0.45)),
                      ),
                      child: Column(
                        children: <Widget>[
                          MonoLabel('Answer', color: Palette.cyan, size: 11 * s),
                          SizedBox(height: 6 * s),
                          Text(
                            answer,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 24 * s,
                              fontWeight: FontWeight.w700,
                              color: Palette.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        SizedBox(height: 14 * s),
        Row(
          children: <Widget>[
            Text(
              _clock(remaining),
              style: GoogleFonts.spaceMono(
                fontSize: 60 * s,
                height: 1,
                fontWeight: FontWeight.w700,
                color: low ? Palette.danger : Palette.textPrimary,
              ),
            ),
            SizedBox(width: 18 * s),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: fraction,
                  minHeight: 10 * s,
                  backgroundColor: Palette.surfaceRaised,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    low ? Palette.danger : Palette.pink,
                  ),
                ),
              ),
            ),
            SizedBox(width: 16 * s),
            Pill(
              label: running
                  ? 'CLOCK RUNNING'
                  : (expired ? 'TIME' : 'CLOCK PAUSED'),
              color: running ? Palette.success : Palette.textFaint,
              icon: Icons.timer_outlined,
            ),
          ],
        ),
        SizedBox(height: 14 * s),
        if (teams.isNotEmpty)
          Row(
            children: <Widget>[
              for (int i = 0; i < teams.length && i < 6; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == teams.length - 1 ? 0 : 10 * s),
                    child: _TeamTile(team: teams[i], scale: s),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  static String _clock(int seconds) {
    final int safe = seconds < 0 ? 0 : seconds;
    return '${safe ~/ 60}:${(safe % 60).toString().padLeft(2, '0')}';
  }
}

class _TeamTile extends StatelessWidget {
  const _TeamTile({required this.team, required this.scale});

  final dynamic team;
  final double scale;

  @override
  Widget build(BuildContext context) {
    final String name = (team['name'] ?? '').toString();
    final int score = (team['score'] as num?)?.toInt() ?? 0;
    final int accentIndex = (team['accent'] as num?)?.toInt() ?? 0;
    final Color accent =
        Palette.teamAccents[accentIndex % Palette.teamAccents.length];
    final List<dynamic> players =
        (team['players'] as List<dynamic>?) ?? const <dynamic>[];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14 * scale, vertical: 10 * scale),
      decoration: BoxDecoration(
        color: Palette.surface.withOpacity(0.9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: accent.withOpacity(0.45), width: 1.2),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceMono(
                    fontSize: 11 * scale,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1,
                    color: accent,
                  ),
                ),
                if (players.isNotEmpty)
                  Text(
                    players
                        .map((dynamic player) =>
                            '${player['name']} ${player['score']}')
                        .join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 10 * scale,
                      color: Palette.textFaint,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(width: 10 * scale),
          Text(
            '$score',
            style: GoogleFonts.spaceMono(
              fontSize: 30 * scale,
              height: 1,
              fontWeight: FontWeight.w700,
              color: Palette.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
