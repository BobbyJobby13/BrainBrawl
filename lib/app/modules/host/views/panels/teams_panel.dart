import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../theme/palette.dart';
import '../../controllers/host_controller.dart';
import '../../models/game_models.dart';
import '../console_widgets.dart';

/// Team and player management: the roster every point is awarded against.
class TeamsPanel extends StatelessWidget {
  const TeamsPanel(this.controller, {Key? key}) : super(key: key);

  final HostController controller;

  Future<void> _addTeam(BuildContext context) async {
    final String? name = await askForText(
      context,
      title: 'New team',
      hint: 'Team name',
      confirmLabel: 'Add team',
    );
    if (name != null) controller.addTeam(name);
  }

  Future<void> _addPlayer(BuildContext context, Team team) async {
    final String? name = await askForText(
      context,
      title: 'Add player to ${team.name}',
      hint: 'Player name',
      confirmLabel: 'Add player',
    );
    if (name != null) controller.addPlayer(team.id, name);
  }

  Future<void> _renameTeam(BuildContext context, Team team) async {
    final String? name = await askForText(
      context,
      title: 'Rename team',
      initial: team.name,
      hint: 'Team name',
    );
    if (name != null) controller.renameTeam(team.id, name);
  }

  Future<void> _renamePlayer(BuildContext context, Player player) async {
    final String? name = await askForText(
      context,
      title: 'Rename player',
      initial: player.name,
      hint: 'Player name',
    );
    if (name != null) controller.renamePlayer(player.id, name);
  }

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        'Teams & players',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${controller.teams.length} teams · ${controller.roster.length} players · scores are per player',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: Palette.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                MiniAction(
                  label: 'Add team',
                  icon: Icons.add_rounded,
                  color: Palette.pink,
                  filled: true,
                  onTap: () => _addTeam(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (controller.teams.isEmpty)
              ConsoleCard(
                title: 'No teams yet',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Add a team, or drop in a starter roster of two groups of '
                      'four. A group takes as many players as you add — four or '
                      'more is expected.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        height: 1.5,
                        color: Palette.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        MiniAction(
                          label: 'Add team',
                          icon: Icons.add_rounded,
                          color: Palette.pink,
                          filled: true,
                          onTap: () => _addTeam(context),
                        ),
                        MiniAction(
                          label: 'Load starter roster',
                          icon: Icons.groups_rounded,
                          onTap: controller.loadDemoTeams,
                        ),
                      ],
                    ),
                  ],
                ),
              )
            else
              for (final Team team in controller.teams)
                Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: ConsoleCard(
                    title: team.name,
                    subtitle: '${team.players.length} players',
                    trailing: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Pill(label: '${team.score} pts', color: team.accent),
                        MiniAction(
                          label: 'Rename',
                          icon: Icons.edit_rounded,
                          onTap: () => _renameTeam(context, team),
                        ),
                        MiniAction(
                          label: 'Delete',
                          icon: Icons.delete_outline_rounded,
                          color: Palette.danger,
                          onTap: () => controller.removeTeam(team.id),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (team.players.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Text(
                              'No players in this team yet.',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 12.5,
                                color: Palette.textFaint,
                              ),
                            ),
                          ),
                        for (final Player player in team.players)
                          _PlayerRow(
                            controller: controller,
                            player: player,
                            accent: team.accent,
                            onRename: () => _renamePlayer(context, player),
                          ),
                        const SizedBox(height: 10),
                        MiniAction(
                          label: 'Add player',
                          icon: Icons.person_add_alt_1_rounded,
                          color: team.accent,
                          onTap: () => _addPlayer(context, team),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 4),
            ConsoleCard(
              title: 'How a point gets awarded',
              child: Text(
                'Every player keeps their own score, and each team shows the sum. '
                'On the Game tab you award points to whoever buzzed first, or tap '
                '+/- next to any player to adjust them directly. The quick buttons '
                'use the correct and wrong point values from the Buzzers tab.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  height: 1.55,
                  color: Palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow({
    required this.controller,
    required this.player,
    required this.accent,
    required this.onRename,
  });

  final HostController controller;
  final Player player;
  final Color accent;
  final VoidCallback onRename;

  @override
  Widget build(BuildContext context) {
    final String? buzzer = controller.buzzerLabelFor(player);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Palette.border),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                player.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Palette.textPrimary,
                ),
              ),
            ),
            if (buzzer != null) ...<Widget>[
              Pill(label: buzzer, color: Palette.textFaint),
              const SizedBox(width: 8),
            ],
            Text(
              '${player.score}',
              style: GoogleFonts.spaceMono(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: accent,
              ),
            ),
            const SizedBox(width: 8),
            MiniIconAction(
              icon: Icons.edit_rounded,
              onTap: onRename,
              tooltip: 'Rename player',
            ),
            const SizedBox(width: 6),
            MiniIconAction(
              icon: Icons.close_rounded,
              color: Palette.danger,
              onTap: () => controller.removePlayer(player.id),
              tooltip: 'Remove player',
            ),
          ],
        ),
      ),
    );
  }
}
