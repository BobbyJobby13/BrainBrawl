import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../theme/palette.dart';
import '../../controllers/host_controller.dart';
import '../../models/quiz_question.dart';
import '../console_widgets.dart';

/// The question bank: filter, inspect, import from a study guide, start a deck.
class QuestionsPanel extends StatefulWidget {
  const QuestionsPanel(this.controller, {Key? key}) : super(key: key);

  final HostController controller;

  @override
  State<QuestionsPanel> createState() => _QuestionsPanelState();
}

class _QuestionsPanelState extends State<QuestionsPanel> {
  final TextEditingController _search = TextEditingController();
  String _pack = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<QuizQuestion> get _filtered => widget.controller.bank.filter(
        pack: _pack,
        query: _search.text,
      );

  void _startDeck() {
    widget.controller.buildDeck(
      pack: _pack.isEmpty ? null : _pack,
      query: _search.text,
    );
    widget.controller.tab.value = 0;
    Get.snackbar(
      'Deck ready',
      '${widget.controller.deck.length} questions loaded.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Palette.surfaceRaised,
      colorText: Palette.textPrimary,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    );
  }

  void _open(QuizQuestion question) {
    widget.controller.buildDeck(
      pack: _pack.isEmpty ? null : _pack,
      query: _search.text,
    );
    final int index = widget.controller.deck
        .indexWhere((QuizQuestion item) => item.id == question.id);
    widget.controller.loadQuestion(
      question,
      index < 0 ? null : index,
    );
    widget.controller.tab.value = 0;
  }

  Future<void> _paste() async {
    final String? text = await askForText(
      context,
      title: 'Paste study guide or JSON',
      hint: 'Q: What does SONAR stand for?\nA: Sound Navigation and Ranging\nH: It starts with the word sound\nP: 10',
      confirmLabel: 'Import',
      maxLines: 12,
    );
    if (text == null) return;

    final int count = await widget.controller.bank.import(text);
    if (!mounted) return;
    setState(() {});
    Get.snackbar(
      count == 0 ? 'Nothing imported' : 'Imported $count questions',
      count == 0
          ? 'Use Q: and A: lines per question, or paste a JSON pack.'
          : 'They are in the bank and saved on this device.',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Palette.surfaceRaised,
      colorText: Palette.textPrimary,
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 3),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final bank = widget.controller.bank;
      final List<QuizQuestion> questions = _filtered;
      final bool customPack = _pack.isNotEmpty && bank.packIsCustom(_pack);

      return SingleChildScrollView(
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
                        'Question bank',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: Palette.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${bank.questions.length} questions · ${bank.packs.length} packs',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12.5,
                          color: Palette.textFaint,
                        ),
                      ),
                    ],
                  ),
                ),
                MiniAction(
                  label: 'Start deck',
                  icon: Icons.play_arrow_rounded,
                  color: Palette.pink,
                  filled: true,
                  onTap: questions.isEmpty ? null : _startDeck,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ConsoleCard(
              title: 'Find questions',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    cursorColor: Palette.pink,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search the bank',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Palette.textFaint,
                      ),
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        size: 18,
                        color: Palette.textFaint,
                      ),
                      filled: true,
                      fillColor: Palette.surfaceRaised,
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Palette.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            BorderSide(color: Palette.pink.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      _packChip('All questions', ''),
                      for (final String pack in bank.packs)
                        _packChip(pack, pack),
                    ],
                  ),
                  if (customPack) ...<Widget>[
                    const SizedBox(height: 12),
                    MiniAction(
                      label: 'Delete "$_pack"',
                      icon: Icons.delete_outline_rounded,
                      color: Palette.danger,
                      onTap: () async {
                        await bank.deletePack(_pack);
                        if (!mounted) return;
                        setState(() => _pack = '');
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'Add your own',
              subtitle: 'Paste a study guide or a JSON pack',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'One block per question: Q: then A:, with optional H: lines for '
                    'hints and P: for points. Paste as many as you like at once — '
                    'imported questions are saved on this device and can be deleted '
                    'by pack.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      height: 1.55,
                      color: Palette.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      MiniAction(
                        label: 'Paste questions',
                        icon: Icons.content_paste_rounded,
                        color: Palette.pink,
                        filled: true,
                        onTap: _paste,
                      ),
                      MiniAction(
                        label: 'Format help',
                        icon: Icons.help_outline_rounded,
                        onTap: () => showHelp(
                          context,
                          title: 'Paste format',
                          body: 'Each question is a small block of lines:\n\n'
                              'Q: What does SONAR stand for?\n'
                              'A: Sound Navigation and Ranging\n'
                              'B: What does RADAR stand for?\n'
                              'H: The first two letters come from sound\n'
                              'H: It uses reflected sound underwater\n'
                              'P: 10\n'
                              'D: 1\n\n'
                              'Q: and A: are required. B: adds the bonus question the '
                              'team gets after a correct answer. H: may be repeated for extra '
                              'hints, P: sets the point value, D: sets difficulty '
                              'from 1 to 3. A line starting with # names the pack '
                              'for everything below it, for example '
                              '"# Naval Science 2 - Chapter 4".\n\n'
                              'Numbered study-guide lists also work: a line ending '
                              'in "?" becomes the question and the next line becomes '
                              'the answer. JSON packs are accepted too — paste '
                              '{"pack": "...", "questions": [...]}.',
                        ),
                      ),
                      MiniAction(
                        label: 'Reload sample packs',
                        icon: Icons.refresh_rounded,
                        onTap: () => bank.load(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            if (bank.isLoading.value)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: Center(
                  child: CircularProgressIndicator(color: Palette.pink),
                ),
              )
            else if (questions.isEmpty)
              ConsoleCard(
                title: 'Nothing here',
                child: Text(
                  'No questions match this filter. Clear the search, pick another '
                  'pack, or paste your own questions above.',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 13,
                    height: 1.5,
                    color: Palette.textSecondary,
                  ),
                ),
              )
            else
              ConsoleCard(
                title: '${questions.length} questions',
                child: Column(
                  children: <Widget>[
                    for (final QuizQuestion question in questions)
                      _QuestionRow(
                        question: question,
                        onTap: () => _open(question),
                      ),
                  ],
                ),
              ),
          ],
        ),
      );
    });
  }

  Widget _packChip(String label, String value) {
    final bool selected = _pack == value;
    return GestureDetector(
      onTap: () => setState(() => _pack = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected
              ? Palette.pink.withOpacity(0.16)
              : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? Palette.pink.withOpacity(0.55) : Palette.border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: selected ? Palette.pink : Palette.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuestionRow extends StatelessWidget {
  const _QuestionRow({required this.question, required this.onTap});

  final QuizQuestion question;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 6),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.02),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Palette.border),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      question.prompt,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13.5,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                        color: Palette.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${question.pack} · ${question.points} pts · '
                      '${question.hints.length} hint${question.hints.length == 1 ? '' : 's'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: Palette.textFaint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              const Icon(
                Icons.play_circle_outline_rounded,
                size: 20,
                color: Palette.textFaint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
