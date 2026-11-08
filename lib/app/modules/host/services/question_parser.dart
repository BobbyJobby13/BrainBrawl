import 'dart:convert';

import '../models/quiz_question.dart';

/// Turns pasted study-guide text (or JSON) into [QuizQuestion]s.
///
/// Accepted line format, in any order, one block per question:
///
/// ```
/// # Naval Science 2 - Chapter 4
/// Q: What does SONAR stand for?
/// A: Sound Navigation and Ranging
/// B: What does RADAR stand for?
/// H: It starts with SOund
/// H: It ends with NAvigation and Ranging
/// P: 15
/// D: 2
/// ```
///
/// `Q:` and `A:` are required, everything else is optional. The `#` heading
/// names the pack and applies to every following question until the next
/// heading. Numbered lists inside a guide are also accepted: a line ending in
/// `?` becomes a question, and the next non-empty line becomes its answer.
List<QuizQuestion> parseQuestionSheet(
  String raw, {
  String fallbackPack = 'Pasted pack',
}) {
  final String text = raw.trim();
  if (text.isEmpty) return const <QuizQuestion>[];

  if (text.startsWith('{') || text.startsWith('[')) {
    return _parseJson(text, fallbackPack);
  }

  final List<QuizQuestion> questions = <QuizQuestion>[];
  final List<String> lines = text.split(RegExp(r'\r?\n'));

  String pack = fallbackPack;
  String? prompt;
  String? answer;
  String bonus = '';
  final List<String> hints = <String>[];
  int points = 10;
  int difficulty = 1;
  int counter = 0;

  void flush() {
    if (prompt == null || prompt!.trim().isEmpty) {
      prompt = null;
      answer = null;
      hints.clear();
      return;
    }
    questions.add(QuizQuestion(
      id: 'paste-${DateTime.now().microsecondsSinceEpoch}-${counter++}',
      prompt: prompt!.trim(),
      answer: (answer ?? '').trim(),
      hints: List<String>.from(hints),
      bonus: bonus,
      pack: pack,
      points: points,
      difficulty: difficulty,
      custom: true,
    ));
    prompt = null;
    answer = null;
    bonus = '';
    hints.clear();
    points = 10;
    difficulty = 1;
  }

  for (final String rawLine in lines) {
    final String line = rawLine.trim();
    if (line.isEmpty) continue;
    if (line.startsWith('//')) continue;

    if (line.startsWith('#')) {
      flush();
      pack = line.replaceFirst(RegExp(r'^#+\s*'), '').trim();
      if (pack.isEmpty) pack = fallbackPack;
      continue;
    }

    final String lower = line.toLowerCase();
    final bool isQuestion =
        lower.startsWith('q:') || lower.startsWith('question:');
    final bool isAnswer = lower.startsWith('a:') || lower.startsWith('answer:');
    final bool isHint = lower.startsWith('h:') || lower.startsWith('hint:');
    final bool isBonus = lower.startsWith('b:') || lower.startsWith('bonus:');
    final bool isPoints = lower.startsWith('p:') || lower.startsWith('points:');
    final bool isDifficulty =
        lower.startsWith('d:') || lower.startsWith('difficulty:');

    if (isQuestion) {
      flush();
      prompt = _afterColon(line);
    } else if (isAnswer) {
      answer = _afterColon(line);
    } else if (isBonus) {
      bonus = _afterColon(line);
    } else if (isHint) {
      hints.add(_afterColon(line));
    } else if (isPoints) {
      points = int.tryParse(_afterColon(line)) ?? points;
    } else if (isDifficulty) {
      difficulty = (int.tryParse(_afterColon(line)) ?? difficulty).clamp(1, 3);
    } else if (line.endsWith('?') &&
        (prompt == null || _numberingPrefix.hasMatch(line))) {
      // Plain "question then answer" pairs from a numbered guide: a numbered
      // line ending in '?' starts a new question, the next line answers it.
      if (prompt != null) flush();
      prompt = _stripNumbering(line);
    } else if (prompt != null && answer == null) {
      answer = _stripNumbering(line);
    }
  }
  flush();

  return questions;
}

final RegExp _numberingPrefix = RegExp(r'^(\d+[.)]|[-*])\s');

String _afterColon(String line) {
  final int index = line.indexOf(':');
  return index == -1 ? '' : line.substring(index + 1).trim();
}

String _stripNumbering(String line) =>
    line.replaceFirst(RegExp(r'^[-*\d.)\s]+'), '').trim();

List<QuizQuestion> _parseJson(String text, String fallbackPack) {
  try {
    final dynamic decoded = jsonDecode(text);
    final dynamic list = decoded is Map && decoded['questions'] is List
        ? decoded['questions']
        : decoded is List
            ? decoded
            : <dynamic>[];
    final String pack = decoded is Map
        ? (decoded['pack'] ?? decoded['name'] ?? fallbackPack).toString()
        : fallbackPack;

    final List<QuizQuestion> questions = <QuizQuestion>[];
    int index = 0;
    for (final dynamic entry in list) {
      if (entry is Map) {
        final QuizQuestion question = QuizQuestion.fromJson(
          Map<String, dynamic>.from(entry),
          fallbackPack: pack,
          index: index++,
        );
        if (question.prompt.isNotEmpty) {
          questions.add(question.copyWith(custom: true));
        }
      }
    }
    return questions;
  } catch (_) {
    return const <QuizQuestion>[];
  }
}
