import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/quiz_question.dart';
import 'question_parser.dart';

/// Everything the console can ask, from bundled packs plus whatever the host
/// imports at runtime.
///
/// Imported packs are stored in SharedPreferences as plain JSON, so a host can
/// build a bank from study guides once and keep it between sessions.
class QuestionBank {
  static const String _customKey = 'bb_host_custom_questions_v1';

  static const List<String> _bundledPacks = <String>[
    'assets/questions/naval_science_sample.json',
    'assets/questions/current_knowledge_sample.json',
  ];

  final RxList<QuizQuestion> questions = <QuizQuestion>[].obs;
  final RxList<String> packs = <String>[].obs;
  final RxBool isLoading = true.obs;
  final RxString error = ''.obs;

  /// Loads bundled packs and any previously imported questions.
  Future<void> load() async {
    isLoading.value = true;
    final List<QuizQuestion> loaded = <QuizQuestion>[];

    for (final String asset in _bundledPacks) {
      try {
        final String raw = await rootBundle.loadString(asset);
        loaded.addAll(_decodePack(raw));
      } catch (_) {
        // A missing pack must not take the console down.
        error.value = 'A bundled question pack could not be read.';
      }
    }

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? stored = prefs.getString(_customKey);
      if (stored != null && stored.isNotEmpty) {
        final dynamic decoded = jsonDecode(stored);
        if (decoded is List) {
          for (final dynamic entry in decoded) {
            if (entry is Map) {
              loaded.add(QuizQuestion.fromJson(
                Map<String, dynamic>.from(entry),
                index: loaded.length,
              ));
            }
          }
        }
      }
    } catch (_) {
      error.value = 'Saved questions could not be restored.';
    }

    questions.assignAll(loaded);
    _rebuildPacks();
    isLoading.value = false;
  }

  List<QuizQuestion> _decodePack(String raw) {
    final dynamic decoded = jsonDecode(raw);
    final List<QuizQuestion> result = <QuizQuestion>[];
    if (decoded is Map && decoded['questions'] is List) {
      final String pack =
          (decoded['pack'] ?? decoded['name'] ?? 'Pack').toString();
      int index = 0;
      for (final dynamic entry in decoded['questions'] as List) {
        if (entry is Map) {
          result.add(QuizQuestion.fromJson(
            Map<String, dynamic>.from(entry),
            fallbackPack: pack,
            index: index++,
          ));
        }
      }
    } else if (decoded is List) {
      int index = 0;
      for (final dynamic entry in decoded) {
        if (entry is Map) {
          result.add(QuizQuestion.fromJson(
            Map<String, dynamic>.from(entry),
            index: index++,
          ));
        }
      }
    }
    return result.where((QuizQuestion q) => q.prompt.isNotEmpty).toList();
  }

  /// Questions matching an optional pack and free-text search.
  List<QuizQuestion> filter({String? pack, String query = ''}) {
    final String needle = query.trim().toLowerCase();
    return questions.where((QuizQuestion question) {
      final bool packOk = pack == null || pack.isEmpty || question.pack == pack;
      final bool textOk = needle.isEmpty ||
          question.prompt.toLowerCase().contains(needle) ||
          question.answer.toLowerCase().contains(needle) ||
          question.pack.toLowerCase().contains(needle);
      return packOk && textOk;
    }).toList();
  }

  /// Imports JSON or pasted study-guide text. Returns how many were accepted.
  Future<int> import(String text, {String? packName}) async {
    final List<QuizQuestion> parsed = parseQuestionSheet(
      text,
      fallbackPack: (packName == null || packName.trim().isEmpty)
          ? 'Pasted pack'
          : packName.trim(),
    );
    if (parsed.isEmpty) return 0;

    final List<QuizQuestion> merged = <QuizQuestion>[
      ...questions,
      ...parsed.map((QuizQuestion q) => q.copyWith(custom: true)),
    ];
    questions.assignAll(merged);
    _rebuildPacks();
    await _persistCustom();
    return parsed.length;
  }

  Future<void> deletePack(String pack) async {
    questions.removeWhere(
      (QuizQuestion q) => q.custom && q.pack == pack,
    );
    _rebuildPacks();
    await _persistCustom();
  }

  bool packIsCustom(String pack) =>
      questions.any((QuizQuestion q) => q.pack == pack && q.custom);

  String exportJson() {
    final List<Map<String, dynamic>> payload = questions
        .map((QuizQuestion q) => q.toJson())
        .toList(growable: false);
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Future<void> _persistCustom() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final List<Map<String, dynamic>> custom = questions
          .where((QuizQuestion q) => q.custom)
          .map((QuizQuestion q) => q.toJson())
          .toList();
      await prefs.setString(_customKey, jsonEncode(custom));
    } catch (_) {
      // Persistence is a convenience; failing it must not block a game.
    }
  }

  void _rebuildPacks() {
    final List<String> names = questions
        .map((QuizQuestion q) => q.pack)
        .where((String p) => p.trim().isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    packs.assignAll(names);
  }
}
