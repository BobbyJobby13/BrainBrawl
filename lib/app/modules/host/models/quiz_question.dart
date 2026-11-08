/// A single question the host can put on screen.
///
/// The shape is deliberately forgiving: question packs written by hand, pasted
/// from a study guide, or exported by a spreadsheet all land here.
class QuizQuestion {
  QuizQuestion({
    required this.id,
    required this.prompt,
    required this.answer,
    this.hints = const <String>[],
    this.choices = const <String>[],
    this.bonus = '',
    this.pack = 'Custom',
    this.points = 10,
    this.difficulty = 1,
    this.custom = false,
  });

  final String id;
  final String prompt;
  final String answer;
  final List<String> hints;
  final List<String> choices;

  /// Follow-up question the team answers after a correct answer. Empty when the
  /// pack has no bonus for this question.
  final String bonus;

  /// Where the question came from, e.g. `Naval Science 2` or `Current knowledge`.
  final String pack;
  final int points;

  /// 1 = easy ... 3 = hard. Shown as a difficulty chip.
  final int difficulty;

  /// True for questions imported at runtime (persisted in SharedPreferences).
  final bool custom;

  factory QuizQuestion.fromJson(
    Map<String, dynamic> json, {
    String fallbackPack = 'Custom',
    int index = 0,
  }) {
    final String prompt = (json['prompt'] ??
            json['question'] ??
            json['question_text'] ??
            json['q'] ??
            json['text'] ??
            '')
        .toString()
        .trim();
    final String answer =
        (json['answer'] ?? json['correct_ans'] ?? json['ans'] ?? json['a'] ?? '')
            .toString()
            .trim();
    final String pack =
        (json['pack'] ?? json['category'] ?? json['book'] ?? json['source'] ?? fallbackPack)
            .toString()
            .trim();

    return QuizQuestion(
      id: (json['id'] ?? json['question_id'] ?? '$pack-$index').toString(),
      prompt: prompt,
      answer: answer,
      hints: _stringList(json['hints'] ?? json['hint']),
      choices: _choices(json),
      bonus: (json['bonus'] ??
              json['bonus_question'] ??
              json['follow_up'] ??
              '')
          .toString()
          .trim(),
      pack: pack.isEmpty ? fallbackPack : pack,
      points: (json['points'] as num?)?.toInt() ??
          (json['value'] as num?)?.toInt() ??
          10,
      difficulty: (json['difficulty'] as num?)?.toInt() ?? 1,
      custom: json['custom'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'prompt': prompt,
        'answer': answer,
        'hints': hints,
        'choices': choices,
        'bonus': bonus,
        'pack': pack,
        'points': points,
        'difficulty': difficulty,
      };

  /// Copy used when the bank hands a deck to the game state.
  QuizQuestion copyWith({bool? custom}) => QuizQuestion(
        id: id,
        prompt: prompt,
        answer: answer,
        hints: hints,
        choices: choices,
        bonus: bonus,
        pack: pack,
        points: points,
        difficulty: difficulty,
        custom: custom ?? this.custom,
      );

  static List<String> _stringList(dynamic value) {
    if (value is List) {
      return value
          .map((dynamic e) => e.toString().trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    if (value is String && value.trim().isNotEmpty) {
      return value
          .split('|')
          .map((String s) => s.trim())
          .where((String s) => s.isNotEmpty)
          .toList();
    }
    return const <String>[];
  }

  static List<String> _choices(Map<String, dynamic> json) {
    final dynamic raw = json['choices'] ?? json['options'];
    if (raw is List) {
      return _stringList(raw);
    }
    final List<String> found = <String>[];
    for (int i = 1; i <= 6; i++) {
      final dynamic choice = json['choice$i'];
      if (choice != null && choice.toString().trim().isNotEmpty) {
        found.add(choice.toString().trim());
      }
    }
    return found;
  }
}
