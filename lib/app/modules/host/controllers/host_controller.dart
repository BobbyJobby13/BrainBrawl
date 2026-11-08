import 'dart:async';
import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../platform/live_link.dart';
import '../../../../platform/url_opener.dart';
import '../models/game_models.dart';
import '../models/quiz_question.dart';
import '../services/buzzer_hub.dart';
import '../services/question_bank.dart';

/// All live game state for the host console.
///
/// One controller owns the clock, the teams, the scores, the buzz queue and the
/// question deck, so every panel on the console reads and writes the same state
/// and there is a single place where a point can be awarded.
class HostController extends GetxController {
  static const String _storageKey = 'bb_host_game_v1';
  static const int _historyLimit = 60;

  final QuestionBank bank = QuestionBank();
  final BuzzerHub buzzers = BuzzerHub();

  // Match state
  final RxList<Team> teams = <Team>[].obs;
  final RxList<ScoreEvent> history = <ScoreEvent>[].obs;
  final RxList<QuizQuestion> deck = <QuizQuestion>[].obs;
  final RxInt deckIndex = (-1).obs;
  final Rxn<QuizQuestion> current = Rxn<QuizQuestion>();

  // Clock
  final RxInt questionSeconds = 20.obs;
  final RxInt remaining = 0.obs;
  final RxBool timerRunning = false.obs;
  final RxBool timeExpired = false.obs;

  // Question reveal
  final RxBool answerRevealed = false.obs;
  final RxInt hintsShown = 0.obs;

  // Scoring rules
  final RxInt correctPoints = 10.obs;
  final RxInt wrongPoints = 5.obs;
  final RxInt bonusPoints = 10.obs;
  final RxInt hintPenalty = 0.obs;
  final RxBool lockoutAfterWrong = true.obs;

  // Bonus round. A correct answer in the main round opens a follow-up question
  // for that same team; a wrong answer never does.
  final RxnString bonusTeamId = RxnString();
  final RxnString bonusPlayerId = RxnString();

  // Match clock. When it runs out the game becomes a lightning round.
  final RxInt matchSeconds = 600.obs;
  final RxInt matchRemaining = 600.obs;
  final RxBool matchRunning = false.obs;
  final RxBool lightningRound = false.obs;

  // Buzzers
  final Rxn<BuzzerHit> activeBuzz = Rxn<BuzzerHit>();
  final RxList<String> lockedOut = <String>[].obs;
  final RxMap<String, String> deviceToPlayer = <String, String>{}.obs;
  final RxString buzzerUrl = ''.obs;

  // buzzin.live room. The service is a hosted buzzer room with no API, so the
  // console carries the code, opens its host dashboard, and can put the code on
  // the projected card for the players to read.
  final RxString buzzinCode = ''.obs;
  final RxBool showBuzzinCode = false.obs;

  final RxInt tab = 0.obs;
  final RxBool ready = false.obs;

  Timer? _ticker;
  Timer? _matchTicker;

  /// Publishes the board to the player display window; see [liveState].
  final LiveLink _live = LiveLink();
  Timer? _liveTimer;

  /// Wiring lives in the constructor so the buzz queue works even when the
  /// controller is exercised outside a GetX route (tests, previews).
  HostController() {
    buzzers.onBuzz = _handleBuzz;
  }

  @override
  void onInit() {
    super.onInit();
    _readTabParameter();
    _boot();
  }

  /// Lets the host link straight to a tab: `/#/host?tab=questions`.
  void _readTabParameter() {
    final String? requested = Get.parameters['tab'];
    if (requested == null) return;
    const List<String> names = <String>['game', 'teams', 'questions', 'buzzers'];
    final int index = names.indexOf(requested.toLowerCase());
    if (index != -1) tab.value = index;
  }

  @override
  void onClose() {
    _ticker?.cancel();
    _matchTicker?.cancel();
    _liveTimer?.cancel();
    buzzers.dispose();
    super.onClose();
  }

  Future<void> _boot() async {
    try {
      await _restore();
      await bank.load().timeout(const Duration(seconds: 10));
      buildDeck(autoLoad: false);
      if (deck.isNotEmpty) {
        loadQuestion(deck.first, 0);
      }
    } catch (_) {
      // The console must open even if a pack or the saved state is unreadable.
    } finally {
      ready.value = true;
      _startLivePublishing();
    }
  }

  // ---------------------------------------------------------------------------
  // Roster helpers
  // ---------------------------------------------------------------------------

  List<Player> get roster => <Player>[
        for (final Team team in teams) ...team.players,
      ];

  Team? teamById(String teamId) {
    for (final Team team in teams) {
      if (team.id == teamId) return team;
    }
    return null;
  }

  Team? teamForPlayer(String playerId) {
    for (final Team team in teams) {
      if (team.playerById(playerId) != null) return team;
    }
    return null;
  }

  Player? playerById(String playerId) {
    for (final Team team in teams) {
      final Player? player = team.playerById(playerId);
      if (player != null) return player;
    }
    return null;
  }

  String? buzzerLabelFor(Player player) {
    for (final MapEntry<String, String> entry in deviceToPlayer.entries) {
      if (entry.value == player.id) return entry.key;
    }
    return null;
  }

  Player? get activePlayer {
    final BuzzerHit? hit = activeBuzz.value;
    if (hit == null) return null;
    final String? playerId = deviceToPlayer[hit.deviceId];
    return playerId == null ? null : playerById(playerId);
  }

  /// Who a given device is paired with, as a display name.
  String? buzzesFrom(String deviceId) {
    final String? playerId = deviceToPlayer[deviceId];
    return playerId == null ? null : playerById(playerId)?.name;
  }

  String get activeBuzzLabel {
    final BuzzerHit? hit = activeBuzz.value;
    if (hit == null) return '';
    return activePlayer?.name ?? 'Unassigned buzzer ${hit.deviceId}';
  }

  BuzzerHub get buzzHub => buzzers;

  // ---------------------------------------------------------------------------
  // Team and player management
  // ---------------------------------------------------------------------------

  Team? addTeam(String name) {
    final String trimmed = name.trim();
    if (trimmed.isEmpty) return null;
    final Team team = Team(
      id: 'team-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed,
      colorIndex: teams.length,
    );
    teams.add(team);
    _syncKeyboardPairing();
    _persist();
    return team;
  }

  void renameTeam(String teamId, String name) {
    final Team? team = teamById(teamId);
    if (team == null || name.trim().isEmpty) return;
    team.name = name.trim();
    teams.refresh();
    _persist();
  }

  void removeTeam(String teamId) {
    teams.removeWhere((Team team) => team.id == teamId);
    _syncKeyboardPairing();
    _persist();
  }

  Player? addPlayer(String teamId, String name) {
    final Team? team = teamById(teamId);
    if (team == null) return null;
    final String trimmed = name.trim();
    final Player player = Player(
      id: 'player-${DateTime.now().microsecondsSinceEpoch}',
      name: trimmed.isEmpty ? 'Player ${roster.length + 1}' : trimmed,
    );
    team.players.add(player);
    teams.refresh();
    _syncKeyboardPairing();
    _persist();
    return player;
  }

  void renamePlayer(String playerId, String name) {
    final Player? player = playerById(playerId);
    if (player == null || name.trim().isEmpty) return;
    player.name = name.trim();
    teams.refresh();
    _persist();
  }

  void removePlayer(String playerId) {
    for (final Team team in teams) {
      team.players.removeWhere((Player player) => player.id == playerId);
    }
    teams.refresh();
    _syncKeyboardPairing();
    _persist();
  }

  /// Gives the console a usable roster on first launch.
  ///
  /// Four players per group, because that is the smallest line-up a group needs
  /// to be playable; teams hold as many players as the host adds.
  void loadDemoTeams() {
    if (teams.isNotEmpty) return;
    teams.assignAll(<Team>[
      Team(id: 'team-demo-1', name: 'Team A', colorIndex: 0, players: <Player>[
        Player(id: 'player-demo-1', name: 'Player 1'),
        Player(id: 'player-demo-2', name: 'Player 2'),
        Player(id: 'player-demo-3', name: 'Player 3'),
        Player(id: 'player-demo-4', name: 'Player 4'),
      ]),
      Team(id: 'team-demo-2', name: 'Team B', colorIndex: 1, players: <Player>[
        Player(id: 'player-demo-5', name: 'Player 5'),
        Player(id: 'player-demo-6', name: 'Player 6'),
        Player(id: 'player-demo-7', name: 'Player 7'),
        Player(id: 'player-demo-8', name: 'Player 8'),
      ]),
    ]);
    _syncKeyboardPairing();
    _persist();
  }

  void resetScores() {
    for (final Team team in teams) {
      for (final Player player in team.players) {
        player.score = 0;
      }
    }
    teams.refresh();
    history.clear();
    _clearBonus();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // Scoring
  // ---------------------------------------------------------------------------

  void awardPoints(Player player, int delta, String reason) {
    final Team? team = teamForPlayer(player.id);
    if (team == null) return;
    player.score += delta;
    teams.refresh();
    history.insert(
      0,
      ScoreEvent(
        playerName: player.name,
        teamName: team.name,
        delta: delta,
        reason: reason,
        at: DateTime.now(),
      ),
    );
    if (history.length > _historyLimit) {
      history.removeRange(_historyLimit, history.length);
    }
    _persist();
  }

  /// A correct answer banks the points for that team, then hands the same team
  /// a bonus question — unless the lightning round is on, which has none.
  void scoreCorrect([int? points]) {
    final Player? player = activePlayer;
    if (player == null) return;
    final Team? team = teamForPlayer(player.id);
    awardPoints(player, points ?? correctPoints.value, 'Correct answer');
    answerRevealed.value = true;
    activeBuzz.value = null;
    buzzers.reset();
    buzzers.disarm();
    if (team == null || lightningRound.value) {
      _clearBonus();
      return;
    }
    bonusTeamId.value = team.id;
    bonusPlayerId.value = player.id;
  }

  /// A wrong answer takes points off the team and ends its turn: no bonus.
  void scoreWrong([int? points]) {
    final Player? player = activePlayer;
    if (player == null) return;
    awardPoints(player, -(points ?? wrongPoints.value), 'Wrong answer');
    lockedOut.add(player.id);
    activeBuzz.value = null;
    _clearBonus();
    buzzers.reset();
    buzzers.arm();
  }

  void clearBuzz() {
    activeBuzz.value = null;
    buzzers.reset();
    buzzers.arm();
  }

  /// Host decides who actually buzzed (touch play, or a broken box).
  void overrideBuzz(Player player) {
    activeBuzz.value = BuzzerHit(
      deviceId: player.buzzerId ?? 'manual-${player.id}',
      source: 'manual',
      at: DateTime.now(),
    );
    deviceToPlayer.putIfAbsent(
      activeBuzz.value!.deviceId,
      () => player.id,
    );
    buzzers.disarm();
  }

  void manualBuzz(Player player) {
    if (lockedOut.contains(player.id)) return;
    String deviceId = player.buzzerId ?? '';
    if (deviceId.isEmpty) {
      for (final MapEntry<String, String> entry in deviceToPlayer.entries) {
        if (entry.value == player.id) {
          deviceId = entry.key;
          break;
        }
      }
    }
    if (deviceId.isEmpty) deviceId = 'click-${player.id}';
    deviceToPlayer[deviceId] = player.id;
    if (!buzzers.armed.value) buzzers.arm();
    buzzers.press(deviceId, source: 'manual');
  }

  /// Digit keys 1-9 buzz as the player in that roster position.
  void buzzKey(int number) {
    if (number < 1 || number > 9) return;
    buzzers.press('K$number', source: 'keyboard');
  }

  void clearLockouts() {
    lockedOut.clear();
    buzzers.reset();
    buzzers.arm();
  }

  // ---------------------------------------------------------------------------
  // Bonus question
  // ---------------------------------------------------------------------------

  bool get bonusActive => bonusTeamId.value != null;

  Team? get bonusTeam {
    final String? id = bonusTeamId.value;
    return id == null ? null : teamById(id);
  }

  /// The bonus text saved with the current question, or a prompt the host can
  /// read out when the pack has none.
  String get bonusPrompt {
    final String saved = (current.value?.bonus ?? '').trim();
    if (saved.isNotEmpty) return saved;
    return 'Bonus question for ${bonusTeam?.name ?? 'the team'}';
  }

  void awardBonus() {
    final Player? player = playerById(bonusPlayerId.value ?? '');
    if (player != null) {
      awardPoints(player, bonusPoints.value, 'Bonus question');
    }
    _clearBonus();
    buzzers.disarm();
  }

  /// The team missed the bonus: nothing is added and nothing comes off.
  void skipBonus() {
    _clearBonus();
    buzzers.disarm();
  }

  void _clearBonus() {
    bonusTeamId.value = null;
    bonusPlayerId.value = null;
  }

  void _handleBuzz(BuzzerHit hit) {
    final String? playerId = deviceToPlayer[hit.deviceId];
    if (playerId != null && lockedOut.contains(playerId)) {
      buzzers.reset();
      buzzers.arm();
      return;
    }
    activeBuzz.value = hit;
    buzzers.disarm();
  }

  // ---------------------------------------------------------------------------
  // Clock
  // ---------------------------------------------------------------------------

  String get clockLabel {
    final int seconds = remaining.value;
    final int minutes = seconds ~/ 60;
    final int rest = seconds % 60;
    return '$minutes:${rest.toString().padLeft(2, '0')}';
  }

  double get clockProgress {
    if (questionSeconds.value <= 0) return 0;
    return (remaining.value / questionSeconds.value).clamp(0, 1);
  }

  void toggleTimer() {
    if (timerRunning.value) {
      pauseTimer();
    } else {
      startTimer();
    }
  }

  void startTimer() {
    _ticker?.cancel();
    if (remaining.value <= 0) {
      remaining.value = questionSeconds.value;
    }
    timerRunning.value = true;
    timeExpired.value = false;
    buzzers.arm();
    _ticker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (remaining.value > 1) {
        remaining.value -= 1;
        return;
      }
      remaining.value = 0;
      timer.cancel();
      timerRunning.value = false;
      timeExpired.value = true;
      buzzers.disarm();
    });
  }

  void pauseTimer() {
    _ticker?.cancel();
    timerRunning.value = false;
  }

  void resetTimer() {
    _ticker?.cancel();
    timerRunning.value = false;
    timeExpired.value = false;
    remaining.value = questionSeconds.value;
    buzzers.reset();
    buzzers.arm();
  }

  void adjustDuration(int delta) {
    questionSeconds.value = (questionSeconds.value + delta).clamp(5, 600).toInt();
    if (!timerRunning.value) remaining.value = questionSeconds.value;
    _persist();
  }

  // ---------------------------------------------------------------------------
  // Match clock and the lightning round
  // ---------------------------------------------------------------------------

  String get matchLabel {
    final int seconds = matchRemaining.value;
    return '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  double get matchProgress {
    if (matchSeconds.value <= 0) return 0;
    return (matchRemaining.value / matchSeconds.value).clamp(0, 1);
  }

  void toggleMatch() => matchRunning.value ? pauseMatch() : startMatch();

  void startMatch() {
    _matchTicker?.cancel();
    if (lightningRound.value) return;
    if (matchRemaining.value <= 0) matchRemaining.value = matchSeconds.value;
    matchRunning.value = true;
    _matchTicker = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (matchRemaining.value > 1) {
        matchRemaining.value -= 1;
        return;
      }
      matchRemaining.value = 0;
      timer.cancel();
      matchRunning.value = false;
      _enterLightning();
    });
  }

  void pauseMatch() {
    _matchTicker?.cancel();
    matchRunning.value = false;
  }

  void resetMatch() {
    _matchTicker?.cancel();
    matchRunning.value = false;
    matchRemaining.value = matchSeconds.value;
    lightningRound.value = false;
    _persist();
  }

  void _enterLightning() {
    if (lightningRound.value) return;
    lightningRound.value = true;
    _clearBonus();
    _persist();
  }

  /// Hosts can jump into the lightning round (or back out of it) by hand.
  void toggleLightning() {
    _matchTicker?.cancel();
    matchRunning.value = false;
    if (lightningRound.value) {
      lightningRound.value = false;
      matchRemaining.value = matchSeconds.value;
      _persist();
      return;
    }
    matchRemaining.value = 0;
    _enterLightning();
  }

  void setMatchSeconds(int value) {
    matchSeconds.value = value.clamp(1, 3600).toInt();
    if (!matchRunning.value && !lightningRound.value) {
      matchRemaining.value = matchSeconds.value;
    }
    _persist();
  }

  void adjustMatchMinutes(int delta) =>
      setMatchSeconds(matchSeconds.value + delta * 60);

  void setBonusPoints(int value) {
    bonusPoints.value = value.clamp(0, 500).toInt();
    _persist();
  }

  // ---------------------------------------------------------------------------
  // Questions
  // ---------------------------------------------------------------------------

  void buildDeck({
    String? pack,
    String query = '',
    bool shuffle = false,
    bool autoLoad = true,
  }) {
    final List<QuizQuestion> list =
        bank.filter(pack: pack, query: query);
    if (shuffle) list.shuffle();
    deck.assignAll(list);
    deckIndex.value = -1;
    if (autoLoad && deck.isNotEmpty) {
      loadQuestion(deck.first, 0);
    }
  }

  void loadQuestion(QuizQuestion question, [int? index]) {
    _ticker?.cancel();
    timerRunning.value = false;
    timeExpired.value = false;
    _clearBonus();
    current.value = question;
    if (index != null) deckIndex.value = index;
    hintsShown.value = 0;
    answerRevealed.value = false;
    remaining.value = questionSeconds.value;
    activeBuzz.value = null;
    lockedOut.clear();
    buzzers.reset();
    buzzers.arm();
  }

  void nextQuestion() {
    if (deck.isEmpty) return;
    final int next = (deckIndex.value + 1).clamp(0, deck.length - 1).toInt();
    loadQuestion(deck[next], next);
  }

  void previousQuestion() {
    if (deck.isEmpty) return;
    final int previous = (deckIndex.value - 1).clamp(0, deck.length - 1).toInt();
    loadQuestion(deck[previous], previous);
  }

  void revealHint() {
    final QuizQuestion? question = current.value;
    if (question == null || hintsShown.value >= question.hints.length) return;
    hintsShown.value += 1;
    if (hintPenalty.value > 0) {
      final Player? player = activePlayer;
      if (player != null) {
        awardPoints(player, -hintPenalty.value, 'Hint revealed');
      }
    }
  }

  void toggleAnswer() => answerRevealed.value = !answerRevealed.value;

  // ---------------------------------------------------------------------------
  // Buzzers
  // ---------------------------------------------------------------------------

  Future<void> connectBuzzers(String url) async {
    buzzerUrl.value = url.trim();
    _persist();
    await buzzers.connect(buzzerUrl.value);
  }

  void disconnectBuzzers() => buzzers.disconnect();

  void assignDevice(String deviceId, String playerId) {
    deviceToPlayer[deviceId] = playerId;
    _persist();
  }

  void unassignDevice(String deviceId) {
    deviceToPlayer.remove(deviceId);
    _persist();
  }

  /// buzzin.live hands out a short game code, but the host usually pastes the
  /// whole room link out of a chat, so keep the trailing digits and drop the URL.
  static String cleanBuzzinCode(String value) {
    final String text = value.trim();
    final RegExpMatch? trailing = RegExp(r'([0-9]{4,12})\s*$').firstMatch(text);
    if (trailing != null) return trailing.group(1)!;
    final String stripped = text.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '');
    return stripped.length <= 12 ? stripped : stripped.substring(0, 12);
  }

  void setBuzzinCode(String value) {
    final String cleaned = cleanBuzzinCode(value);
    if (buzzinCode.value == cleaned) return;
    buzzinCode.value = cleaned;
    _persist();
  }

  void setShowBuzzinCode(bool value) {
    if (showBuzzinCode.value == value) return;
    showBuzzinCode.value = value;
    _persist();
  }

  void toggleShowBuzzinCode() => setShowBuzzinCode(!showBuzzinCode.value);

  Future<void> copyBuzzinCode() async {
    if (buzzinCode.value.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: buzzinCode.value));
  }

  /// Opens buzzin.live's own host dashboard in the system browser, so the buzz
  /// order is read there while this console keeps the score.
  Future<void> openBuzzinHost() => openExternalUrl('https://buzzin.live/host');

  bool get buzzinReady => buzzinCode.value.isNotEmpty;

  // ---------------------------------------------------------------------------
  // Player display
  // ---------------------------------------------------------------------------

  bool get canOpenPlayerDisplay => _live.canOpenDisplay;

  /// Starts a second copy of the app in `--display` mode, for the projector.
  /// Returns an error message, or null when the window launched.
  Future<String?> openPlayerDisplay() => _live.openDisplay();

  /// Four times a second is enough for the countdown and the scores, and the
  /// link skips the write whenever nothing changed.
  void _startLivePublishing() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(
      const Duration(milliseconds: 250),
      (Timer _) => _live.publish(liveState()),
    );
  }

  /// Everything the projector needs, in one flat map. The display renders this
  /// and never writes anything back, so a stray click on the board cannot
  /// change a score.
  Map<String, dynamic> liveState() {
    final QuizQuestion? question = current.value;
    final Team? bonus = bonusTeam;
    final Player? buzzed = activePlayer;
    return <String, dynamic>{
      'at': DateTime.now().millisecondsSinceEpoch,
      'index': deckIndex.value,
      'total': deck.length,
      'prompt': question?.prompt ?? '',
      'answer': answerRevealed.value ? (question?.answer ?? '') : '',
      'pack': question?.pack ?? '',
      'points': question?.points ?? correctPoints.value,
      'choices': question?.choices ?? const <String>[],
      'hints': (question?.hints ?? const <String>[])
          .take(hintsShown.value)
          .toList(),
      'seconds': questionSeconds.value,
      'remaining': remaining.value,
      'running': timerRunning.value,
      'expired': timeExpired.value,
      'lightning': lightningRound.value,
      'matchRemaining': matchRemaining.value,
      'bonus': bonus?.name ?? '',
      'buzz': buzzed?.name ?? '',
      'buzzin': showBuzzinCode.value ? buzzinCode.value : '',
      'teams': teams
          .map((Team team) => <String, dynamic>{
                'name': team.name,
                'score': team.score,
                'accent': team.colorIndex,
                'players': team.players
                    .map((Player player) => <String, dynamic>{
                          'name': player.name,
                          'score': player.score,
                        })
                    .toList(),
              })
          .toList(),
    };
  }

  /// Keys 1-9 follow roster order so a keyboard (or a USB buzzer box that types
  /// digits) works with no setup at all.
  void _syncKeyboardPairing() {
    deviceToPlayer.removeWhere(
      (String device, String playerId) =>
          device.startsWith('K') &&
          RegExp(r'^K[1-9]$').hasMatch(device),
    );
    final List<Player> players = roster;
    for (int i = 0; i < players.length && i < 9; i++) {
      deviceToPlayer['K${i + 1}'] = players[i].id;
    }
  }

  // ---------------------------------------------------------------------------
  // Persistence
  // ---------------------------------------------------------------------------

  Future<void> _persist() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(<String, dynamic>{
          'teams': teams.map((Team team) => team.toJson()).toList(),
          'seconds': questionSeconds.value,
          'correct': correctPoints.value,
          'wrong': wrongPoints.value,
          'bonus': bonusPoints.value,
          'matchSeconds': matchSeconds.value,
          'hintPenalty': hintPenalty.value,
          'lockout': lockoutAfterWrong.value,
          'buzzerUrl': buzzerUrl.value,
          'devices': deviceToPlayer,
          'buzzinCode': buzzinCode.value,
          'showBuzzinCode': showBuzzinCode.value,
        }),
      );
    } catch (_) {
      // A failed save must never interrupt a live game.
    }
  }

  Future<void> _restore() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw != null && raw.isNotEmpty) {
        final dynamic decoded = jsonDecode(raw);
        if (decoded is Map) {
          final dynamic storedTeams = decoded['teams'];
          if (storedTeams is List) {
            teams.assignAll(
              storedTeams
                  .whereType<Map>()
                  .map((dynamic entry) => Team.fromJson(
                        Map<String, dynamic>.from(entry as Map),
                      ))
                  .where((Team team) => team.id.isNotEmpty),
            );
          }
          questionSeconds.value =
              ((decoded['seconds'] as num?)?.toInt() ?? 20).clamp(5, 600).toInt();
          correctPoints.value =
              ((decoded['correct'] as num?)?.toInt() ?? 10).clamp(1, 1000).toInt();
          wrongPoints.value =
              ((decoded['wrong'] as num?)?.toInt() ?? 5).clamp(0, 1000).toInt();
          bonusPoints.value =
              ((decoded['bonus'] as num?)?.toInt() ?? 10).clamp(0, 500).toInt();
          matchSeconds.value =
              ((decoded['matchSeconds'] as num?)?.toInt() ?? 600)
                  .clamp(1, 3600)
                  .toInt();
          matchRemaining.value = matchSeconds.value;
          hintPenalty.value =
              ((decoded['hintPenalty'] as num?)?.toInt() ?? 0).clamp(0, 100).toInt();
          lockoutAfterWrong.value = decoded['lockout'] != false;
          buzzerUrl.value = (decoded['buzzerUrl'] ?? '').toString();
          buzzinCode.value =
              cleanBuzzinCode((decoded['buzzinCode'] ?? '').toString());
          showBuzzinCode.value = decoded['showBuzzinCode'] == true;
          final dynamic devices = decoded['devices'];
          if (devices is Map) {
            deviceToPlayer.assignAll(
              devices.map<String, String>(
                (dynamic key, dynamic value) =>
                    MapEntry<String, String>(key.toString(), value.toString()),
              ),
            );
          }
        }
      }
    } catch (_) {
      // Corrupt saved state falls back to defaults rather than crashing.
    }

    if (teams.isEmpty) loadDemoTeams();
    _syncKeyboardPairing();
    remaining.value = questionSeconds.value;
  }

  void setCorrectPoints(int value) {
    correctPoints.value = value.clamp(0, 1000).toInt();
    _persist();
  }

  void setWrongPoints(int value) {
    wrongPoints.value = value.clamp(0, 1000).toInt();
    _persist();
  }

  void setHintPenalty(int value) {
    hintPenalty.value = value.clamp(0, 100).toInt();
    _persist();
  }

  void setLockout(bool value) {
    lockoutAfterWrong.value = value;
    _persist();
  }

  void setSeconds(int value) {
    questionSeconds.value = value.clamp(5, 600).toInt();
    if (!timerRunning.value) remaining.value = questionSeconds.value;
    _persist();
  }
}
