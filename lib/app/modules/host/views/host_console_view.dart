import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/palette.dart';
import '../../../routes/app_pages.dart';
import '../../../widgets/glow_background.dart';
import '../../../widgets/primary_button.dart';
import '../controllers/host_controller.dart';
import '../models/game_models.dart';
import '../models/quiz_question.dart';
import '../services/buzzer_hub.dart';
import 'console_widgets.dart';
import 'panels/buzzers_panel.dart';
import 'panels/questions_panel.dart';
import 'panels/teams_panel.dart';

/// The host's control room: clock, buzz-ins, scoring, roster and questions.
class HostConsoleView extends GetView<HostController> {
  const HostConsoleView({Key? key}) : super(key: key);

  static final Map<int, int> _digitKeys = <int, int>{
    LogicalKeyboardKey.digit1.keyId: 1,
    LogicalKeyboardKey.digit2.keyId: 2,
    LogicalKeyboardKey.digit3.keyId: 3,
    LogicalKeyboardKey.digit4.keyId: 4,
    LogicalKeyboardKey.digit5.keyId: 5,
    LogicalKeyboardKey.digit6.keyId: 6,
    LogicalKeyboardKey.digit7.keyId: 7,
    LogicalKeyboardKey.digit8.keyId: 8,
    LogicalKeyboardKey.digit9.keyId: 9,
    LogicalKeyboardKey.numpad1.keyId: 1,
    LogicalKeyboardKey.numpad2.keyId: 2,
    LogicalKeyboardKey.numpad3.keyId: 3,
    LogicalKeyboardKey.numpad4.keyId: 4,
    LogicalKeyboardKey.numpad5.keyId: 5,
    LogicalKeyboardKey.numpad6.keyId: 6,
    LogicalKeyboardKey.numpad7.keyId: 7,
    LogicalKeyboardKey.numpad8.keyId: 8,
    LogicalKeyboardKey.numpad9.keyId: 9,
  };

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (controller.tab.value != 0) return KeyEventResult.ignored;

    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.space) {
      controller.toggleTimer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyN) {
      controller.nextQuestion();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyH) {
      controller.revealHint();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyA) {
      controller.toggleAnswer();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.keyB) {
      controller.awardBonus();
      return KeyEventResult.handled;
    }
    final int? buzzerNumber = _digitKeys[key.keyId];
    if (buzzerNumber != null) {
      controller.buzzKey(buzzerNumber);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return GlowBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Focus(
            autofocus: true,
            onKeyEvent: _onKey,
            child: Column(
              children: <Widget>[
                _ConsoleHeader(controller: controller),
                _TabStrip(controller: controller),
                Expanded(
                  child: Obx(() {
                    if (!controller.ready.value) {
                      return const Center(
                        child: CircularProgressIndicator(color: Palette.pink),
                      );
                    }
                    switch (controller.tab.value) {
                      case 1:
                        return TeamsPanel(controller);
                      case 2:
                        return QuestionsPanel(controller);
                      case 3:
                        return BuzzersPanel(controller);
                      default:
                        return _GamePanel(controller);
                    }
                  }),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConsoleHeader extends StatelessWidget {
  const _ConsoleHeader({required this.controller});

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    final bool wide = MediaQuery.of(context).size.width > 620;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 6),
      child: Row(
        children: <Widget>[
          ClipOval(
            child: Image.asset(
              'assets/images/brain_mark.png',
              width: 36,
              height: 36,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'BRAIN BRAWL',
                  style: GoogleFonts.spaceMono(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: Palette.pink,
                  ),
                ),
                Text(
                  'Host console',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (wide) ...<Widget>[
            Obx(
              () => Pill(
                label: controller.buzzers.connected.value
                    ? 'BUZZER LIVE'
                    : 'BUZZER OFFLINE',
                color: controller.buzzers.connected.value
                    ? Palette.success
                    : Palette.textFaint,
                icon: Icons.sensors_rounded,
              ),
            ),
            const SizedBox(width: 10),
          ],
          MiniAction(
            label: 'Exit',
            icon: Icons.close_rounded,
            onTap: () => Get.offAllNamed(Routes.HOME),
          ),
        ],
      ),
    );
  }
}

class _TabStrip extends StatelessWidget {
  const _TabStrip({required this.controller});

  final HostController controller;

  static const List<String> _labels = <String>[
    'Game',
    'Teams',
    'Questions',
    'Buzzers',
  ];
  static const List<IconData> _icons = <IconData>[
    Icons.sports_score_rounded,
    Icons.groups_rounded,
    Icons.quiz_rounded,
    Icons.sensors_rounded,
  ];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 12),
        child: Row(
          children: <Widget>[
            for (int index = 0; index < _labels.length; index++)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TabButton(
                  label: _labels[index],
                  icon: _icons[index],
                  selected: controller.tab.value == index,
                  onTap: () => controller.tab.value = index,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? Palette.pink : Palette.textSecondary;
    return Material(
      color: selected ? Palette.pink.withOpacity(0.14) : Colors.white.withOpacity(0.03),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? Palette.pink.withOpacity(0.5) : Palette.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 7),
              Text(
                label,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GamePanel extends StatelessWidget {
  const _GamePanel(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final bool wide = constraints.maxWidth >= 1020;
        final Widget question = _QuestionCard(controller);
        final List<Widget> controls = <Widget>[
          _ClockCard(controller),
          const SizedBox(height: 14),
          _RoundCard(controller),
          const SizedBox(height: 14),
          _BuzzCard(controller),
          const SizedBox(height: 14),
          _ScoreboardCard(controller),
          const SizedBox(height: 14),
          _HistoryCard(controller),
        ];

        if (wide) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Expanded(flex: 6, child: question),
                const SizedBox(width: 18),
                Expanded(
                  flex: 5,
                  child: Column(children: controls),
                ),
              ],
            ),
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            children: <Widget>[
              _ClockCard(controller),
              const SizedBox(height: 14),
              _RoundCard(controller),
              const SizedBox(height: 14),
              _BuzzCard(controller),
              const SizedBox(height: 14),
              question,
              const SizedBox(height: 14),
              _ScoreboardCard(controller),
              const SizedBox(height: 14),
              _HistoryCard(controller),
            ],
          ),
        );
      },
    );
  }
}

class _ClockCard extends StatelessWidget {
  const _ClockCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool expired = controller.timeExpired.value;
      final bool running = controller.timerRunning.value;
      final Color clockColor = expired
          ? Palette.danger
          : (controller.remaining.value <= 5 ? Palette.danger : Palette.textPrimary);

      return ConsoleCard(
        title: 'Clock',
        subtitle: '${controller.questionSeconds.value}s per question',
        trailing: Pill(
          label: running
              ? 'RUNNING'
              : (expired ? 'TIME UP' : 'PAUSED'),
          color: running
              ? Palette.success
              : (expired ? Palette.danger : Palette.textFaint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  controller.clockLabel,
                  style: GoogleFonts.spaceMono(
                    fontSize: 50,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: clockColor,
                  ),
                ),
                const SizedBox(width: 10),
                const Padding(
                  padding: EdgeInsets.only(bottom: 7),
                  child: MonoLabel('remaining'),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: controller.clockProgress,
                minHeight: 8,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(
                  expired ? Palette.danger : Palette.pink,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                MiniAction(
                  label: '-5s',
                  onTap: () => controller.adjustDuration(-5),
                ),
                MiniAction(
                  label: '+5s',
                  onTap: () => controller.adjustDuration(5),
                ),
                SizedBox(
                  width: 132,
                  child: PrimaryButton(
                    label: running ? 'Pause' : 'Start',
                    height: 40,
                    icon: running
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    onPressed: controller.toggleTimer,
                  ),
                ),
                MiniAction(
                  label: 'Reset',
                  icon: Icons.replay_rounded,
                  onTap: controller.resetTimer,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              'Space starts or pauses. N = next, H = hint, A = answer, B = bonus.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.5,
                color: Palette.textFaint,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _QuestionCard extends StatelessWidget {
  const _QuestionCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final QuizQuestion? question = controller.current.value;
      if (question == null) {
        return ConsoleCard(
          title: 'Question',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'No question selected yet.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Palette.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Open the Questions tab, pick your pack and press Start deck.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  height: 1.5,
                  color: Palette.textSecondary,
                ),
              ),
              const SizedBox(height: 16),
              MiniAction(
                label: 'Load a deck',
                icon: Icons.quiz_rounded,
                color: Palette.pink,
                filled: true,
                onTap: () => controller.tab.value = 2,
              ),
            ],
          ),
        );
      }

      final List<String> remainingHints = question.hints;
      final int revealed = controller.hintsShown.value;

      return ConsoleCard(
        title: 'Question',
        subtitle: controller.deck.isEmpty
            ? question.pack
            : 'Card ${controller.deckIndex.value + 1} of ${controller.deck.length}',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: <Widget>[
                Pill(label: question.pack, color: Palette.violet),
                Pill(label: '${question.points} pts', color: Palette.pink),
                Pill(
                  label: 'Level ${question.difficulty}',
                  color: Palette.cyan,
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              question.prompt,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 21,
                height: 1.45,
                fontWeight: FontWeight.w600,
                color: Palette.textPrimary,
              ),
            ),
            if (question.choices.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final String choice in question.choices)
                    Pill(label: choice, color: Palette.textSecondary),
                ],
              ),
            ],
            if (remainingHints.isNotEmpty) ...<Widget>[
              const SizedBox(height: 20),
              MonoLabel(
                'Hints ${revealed.clamp(0, remainingHints.length)}/${remainingHints.length}',
                color: Palette.cyan,
              ),
              const SizedBox(height: 8),
              for (int index = 0; index < revealed.clamp(0, remainingHints.length); index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Palette.cyan.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Palette.cyan.withOpacity(0.25)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Icon(
                          Icons.lightbulb_outline_rounded,
                          size: 15,
                          color: Palette.cyan,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            remainingHints[index],
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 13,
                              height: 1.45,
                              color: Palette.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (revealed < remainingHints.length)
                MiniAction(
                  label: 'Reveal hint (H) · ${remainingHints.length - revealed} left',
                  icon: Icons.lightbulb_outline_rounded,
                  color: Palette.cyan,
                  onTap: controller.revealHint,
                ),
            ],
            const SizedBox(height: 20),
            MonoLabel(
              'Answer',
              color: controller.answerRevealed.value ? Palette.success : Palette.textFaint,
            ),
            const SizedBox(height: 8),
            if (controller.answerRevealed.value)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: Palette.success.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Palette.success.withOpacity(0.35)),
                ),
                child: Text(
                  question.answer.isEmpty ? 'No answer saved for this question.' : question.answer,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 15,
                    height: 1.45,
                    fontWeight: FontWeight.w600,
                    color: Palette.success,
                  ),
                ),
              )
            else
              MiniAction(
                label: 'Reveal answer (A)',
                icon: Icons.visibility_rounded,
                onTap: controller.toggleAnswer,
              ),
            const SizedBox(height: 20),
            Row(
              children: <Widget>[
                Expanded(
                  child: MiniAction(
                    label: 'Previous',
                    icon: Icons.chevron_left_rounded,
                    onTap: controller.deck.isEmpty ? null : controller.previousQuestion,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MiniAction(
                    label: 'Next question',
                    icon: Icons.chevron_right_rounded,
                    color: Palette.pink,
                    filled: true,
                    onTap: controller.deck.isEmpty ? null : controller.nextQuestion,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

class _RoundCard extends StatelessWidget {
  const _RoundCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bool lightning = controller.lightningRound.value;
      final bool running = controller.matchRunning.value;
      final Color accent = lightning ? Palette.cyan : Palette.violet;

      return ConsoleCard(
        title: 'Match clock',
        subtitle: lightning
            ? 'Lightning round · no bonus questions'
            : 'Main round · every correct answer earns a bonus',
        trailing: Pill(
          label: lightning ? 'LIGHTNING' : (running ? 'RUNNING' : 'PAUSED'),
          color: lightning
              ? Palette.cyan
              : (running ? Palette.success : Palette.textFaint),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: <Widget>[
                Text(
                  controller.matchLabel,
                  style: GoogleFonts.spaceMono(
                    fontSize: 34,
                    height: 1,
                    fontWeight: FontWeight.w700,
                    color: accent,
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: MonoLabel(
                    lightning ? 'bonus off' : 'until lightning',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(99),
              child: LinearProgressIndicator(
                value: controller.matchProgress,
                minHeight: 6,
                backgroundColor: Colors.white.withOpacity(0.08),
                valueColor: AlwaysStoppedAnimation<Color>(accent),
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: <Widget>[
                MiniAction(
                  label: '-1m',
                  onTap: () => controller.adjustMatchMinutes(-1),
                ),
                MiniAction(
                  label: '+1m',
                  onTap: () => controller.adjustMatchMinutes(1),
                ),
                MiniAction(
                  label: running ? 'Pause match' : 'Start match',
                  icon: running
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                  color: Palette.pink,
                  filled: !running && !lightning,
                  onTap: lightning ? null : controller.toggleMatch,
                ),
                MiniAction(
                  label: 'Reset',
                  icon: Icons.replay_rounded,
                  onTap: controller.resetMatch,
                ),
                MiniAction(
                  label: lightning ? 'Back to main round' : 'Lightning now',
                  icon: Icons.bolt_rounded,
                  color: Palette.cyan,
                  onTap: controller.toggleLightning,
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Bonus question value',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      color: Palette.textSecondary,
                    ),
                  ),
                ),
                MiniAction(
                  label: '-5',
                  onTap: () => controller
                      .setBonusPoints(controller.bonusPoints.value - 5),
                ),
                const SizedBox(width: 6),
                Text(
                  '${controller.bonusPoints.value} pts',
                  style: GoogleFonts.spaceMono(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Palette.textPrimary,
                  ),
                ),
                const SizedBox(width: 6),
                MiniAction(
                  label: '+5',
                  onTap: () => controller
                      .setBonusPoints(controller.bonusPoints.value + 5),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Correct +${controller.correctPoints.value}, wrong '
              '-${controller.wrongPoints.value}. Lightning scores the same and '
              'skips the bonus.',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 11.5,
                height: 1.5,
                color: Palette.textFaint,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _BuzzCard extends StatelessWidget {
  const _BuzzCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final BuzzerHit? hit = controller.activeBuzz.value;
      final bool armed = controller.buzzers.armed.value;

      return ConsoleCard(
        title: 'Buzz-ins',
        subtitle: 'First press wins, then the host judges',
        trailing: Pill(
          label: controller.bonusActive
              ? 'BONUS'
              : (hit != null ? 'BUZZED' : (armed ? 'ARMED' : 'LOCKED')),
          color: controller.bonusActive
              ? Palette.cyan
              : (hit != null
                  ? Palette.pink
                  : (armed ? Palette.success : Palette.textFaint)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (controller.bonusActive) ...<Widget>[
              MonoLabel(
                'BONUS · ${controller.bonusTeam?.name ?? 'team'} alone',
                color: Palette.cyan,
              ),
              const SizedBox(height: 8),
              Text(
                controller.bonusPrompt,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 17,
                  height: 1.45,
                  fontWeight: FontWeight.w600,
                  color: Palette.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Worth ${controller.bonusPoints.value} points. A missed bonus '
                'costs nothing.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Palette.textFaint,
                ),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  MiniAction(
                    label: 'Bonus +${controller.bonusPoints.value} (B)',
                    icon: Icons.star_rounded,
                    color: Palette.cyan,
                    filled: true,
                    onTap: controller.awardBonus,
                  ),
                  MiniAction(
                    label: 'No bonus',
                    icon: Icons.skip_next_rounded,
                    onTap: controller.skipBonus,
                  ),
                ],
              ),
            ] else if (hit != null) ...<Widget>[
              Text(
                controller.activeBuzzLabel,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Palette.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              MonoLabel(
                '${hit.deviceId} · ${hit.source}',
                color: Palette.textFaint,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  MiniAction(
                    label: 'Correct +${controller.correctPoints.value}',
                    icon: Icons.check_rounded,
                    color: Palette.success,
                    filled: true,
                    onTap: () => controller.scoreCorrect(),
                  ),
                  MiniAction(
                    label: 'Wrong -${controller.wrongPoints.value}',
                    icon: Icons.close_rounded,
                    color: Palette.danger,
                    filled: true,
                    onTap: () => controller.scoreWrong(),
                  ),
                  MiniAction(
                    label: 'Cancel',
                    icon: Icons.undo_rounded,
                    onTap: controller.clearBuzz,
                  ),
                ],
              ),
            ] else ...<Widget>[
              Text(
                armed ? 'Waiting for a buzz…' : 'Buzzers are locked.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 15,
                  color: Palette.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Keys 1-9, a hardware box, or tap a player below.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  color: Palette.textFaint,
                ),
              ),
              if (!armed) ...<Widget>[
                const SizedBox(height: 12),
                MiniAction(
                  label: 'Arm buzzers',
                  icon: Icons.sensors_rounded,
                  color: Palette.pink,
                  onTap: controller.clearLockouts,
                ),
              ],
            ],
            if (!controller.bonusActive) ...<Widget>[
              const SizedBox(height: 16),
              MonoLabel('Tap to buzz'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: <Widget>[
                  for (final Player player in controller.roster)
                    _PlayerBuzzChip(controller: controller, player: player),
                ],
              ),
            ],
            if (controller.lockedOut.isNotEmpty) ...<Widget>[
              const SizedBox(height: 12),
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      '${controller.lockedOut.length} player(s) locked out this question.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11.5,
                        color: Palette.danger,
                      ),
                    ),
                  ),
                  MiniAction(
                    label: 'Unlock',
                    icon: Icons.lock_open_rounded,
                    onTap: controller.clearLockouts,
                  ),
                ],
              ),
            ],
          ],
        ),
      );
    });
  }
}

class _PlayerBuzzChip extends StatelessWidget {
  const _PlayerBuzzChip({required this.controller, required this.player});

  final HostController controller;
  final Player player;

  @override
  Widget build(BuildContext context) {
    final Team? team = controller.teamForPlayer(player.id);
    final Color accent = team?.accent ?? Palette.pink;
    final bool locked = controller.lockedOut.contains(player.id);
    final String? key = controller.buzzerLabelFor(player);

    return Material(
      color: accent.withOpacity(locked ? 0.04 : 0.12),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: locked ? null : () => controller.manualBuzz(player),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: accent.withOpacity(locked ? 0.18 : 0.45),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (key != null && key.startsWith('K')) ...<Widget>[
                MonoLabel(key, color: accent, size: 9),
                const SizedBox(width: 6),
              ],
              Text(
                player.name,
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: locked ? Palette.textFaint : Palette.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreboardCard extends StatelessWidget {
  const _ScoreboardCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => ConsoleCard(
        title: 'Scoreboard',
        subtitle: '${controller.roster.length} players',
        trailing: MiniAction(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          color: Palette.danger,
          onTap: controller.resetScores,
        ),
        child: controller.teams.isEmpty
            ? Text(
                'No teams yet. Add them on the Teams tab.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 13,
                  color: Palette.textSecondary,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final Team team in controller.teams)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: team.accent,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  team.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Palette.textPrimary,
                                  ),
                                ),
                              ),
                              Text(
                                '${team.score}',
                                style: GoogleFonts.spaceMono(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: team.accent,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          for (final Player player in team.players)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: Text(
                                      player.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 12.5,
                                        color: Palette.textSecondary,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${player.score}',
                                    style: GoogleFonts.spaceMono(
                                      fontSize: 12.5,
                                      color: Palette.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  MiniAction(
                                    label: '+${controller.correctPoints.value}',
                                    color: Palette.success,
                                    onTap: () => controller.awardPoints(
                                      player,
                                      controller.correctPoints.value,
                                      'Manual award',
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  MiniAction(
                                    label: '-${controller.wrongPoints.value}',
                                    color: Palette.danger,
                                    onTap: () => controller.awardPoints(
                                      player,
                                      -controller.wrongPoints.value,
                                      'Manual deduction',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard(this.controller);

  final HostController controller;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.history.isEmpty) {
        return ConsoleCard(
          title: 'Score history',
          child: Text(
            'Points you award will appear here, newest first.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12.5,
              color: Palette.textFaint,
            ),
          ),
        );
      }

      final List<ScoreEvent> events = controller.history.take(6).toList();
      return ConsoleCard(
        title: 'Score history',
        trailing: MonoLabel('${controller.history.length} events'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            for (final ScoreEvent event in events)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        '${event.playerName} · ${event.reason}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: Palette.textSecondary,
                        ),
                      ),
                    ),
                    Text(
                      '${event.delta > 0 ? '+' : ''}${event.delta}',
                      style: GoogleFonts.spaceMono(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: event.delta >= 0
                            ? Palette.success
                            : Palette.danger,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }
}
