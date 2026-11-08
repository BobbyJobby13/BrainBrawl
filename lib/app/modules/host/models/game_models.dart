import 'package:flutter/material.dart';

import '../../../../theme/palette.dart';

/// A single competitor inside a [Team]. Scores live on the player so a host can
/// award points to one person without touching the rest of the team.
class Player {
  Player({
    required this.id,
    required this.name,
    this.score = 0,
    this.buzzerId,
  });

  final String id;
  String name;
  int score;

  /// Hardware/keyboard buzzer paired with this player, e.g. `K1` or `BOX-3`.
  String? buzzerId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'score': score,
        'buzzerId': buzzerId,
      };

  factory Player.fromJson(Map<String, dynamic> json) => Player(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        score: (json['score'] as num?)?.toInt() ?? 0,
        buzzerId: json['buzzerId']?.toString(),
      );
}

/// A team of players. Team totals are derived, never stored twice, so a score
/// can only ever exist in one place.
class Team {
  Team({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    List<Player>? players,
  }) : players = players ?? <Player>[];

  final String id;
  String name;
  int colorIndex;
  final List<Player> players;

  int get score =>
      players.fold<int>(0, (int total, Player player) => total + player.score);

  Color get accent => Palette.teamAccents[colorIndex % Palette.teamAccents.length];

  Player? playerById(String playerId) {
    for (final Player player in players) {
      if (player.id == playerId) return player;
    }
    return null;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'players': players.map((Player p) => p.toJson()).toList(),
      };

  factory Team.fromJson(Map<String, dynamic> json) => Team(
        id: (json['id'] ?? '').toString(),
        name: (json['name'] ?? '').toString(),
        colorIndex: (json['colorIndex'] as num?)?.toInt() ?? 0,
        players: ((json['players'] as List?) ?? <dynamic>[])
            .whereType<Map>()
            .map((dynamic raw) =>
                Player.fromJson(Map<String, dynamic>.from(raw as Map)))
            .toList(),
      );
}

/// Deltas applied by the quick-correct/quick-wrong buttons.
class GameSettings {
  const GameSettings({
    this.secondsPerQuestion = 20,
    this.correctPoints = 10,
    this.wrongPoints = 5,
    this.hintPenalty = 0,
  });

  final int secondsPerQuestion;
  final int correctPoints;
  final int wrongPoints;

  /// Points deducted from the team total when a hint is revealed. Zero by
  /// default; hosts can price hints per game.
  final int hintPenalty;
}

/// One line in the score history, so the host can audit every point.
class ScoreEvent {
  ScoreEvent({
    required this.playerName,
    required this.teamName,
    required this.delta,
    required this.reason,
    required this.at,
  });

  final String playerName;
  final String teamName;
  final int delta;
  final String reason;
  final DateTime at;
}
