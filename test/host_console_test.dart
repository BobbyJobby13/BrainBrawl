import 'dart:async';
import 'dart:io';

import 'package:brainbrawl/app/modules/host/controllers/host_controller.dart';
import 'package:brainbrawl/app/modules/host/models/game_models.dart';
import 'package:brainbrawl/app/modules/host/services/buzzer_socket.dart';
import 'package:brainbrawl/app/modules/host/services/question_parser.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('parses Q/A blocks with hints, points and pack headings', () {
    final questions = parseQuestionSheet(
      '# Naval Science 1 - Chapter 2\n'
      'Q: Which side of a ship is port?\n'
      'A: The left side facing forward\n'
      'H: It is opposite starboard\n'
      'H: Shorter word, shorter crossing\n'
      'P: 15\n'
      '\n'
      'Q: What is the front of a ship called?\n'
      'A: The bow',
    );

    expect(questions.length, 2);
    expect(questions.first.pack, 'Naval Science 1 - Chapter 2');
    expect(questions.first.answer, 'The left side facing forward');
    expect(questions.first.hints.length, 2);
    expect(questions.first.points, 15);
    expect(questions[1].points, 10);
    expect(questions[1].pack, 'Naval Science 1 - Chapter 2');
  });

  test('parses a JSON pack', () {
    final questions = parseQuestionSheet(
      '{"pack":"Current knowledge","questions":['
      '{"prompt":"Which carrier class leads?","answer":"Ford class",'
      '"hints":["Named after a president"]}'
      ']}',
    );
    expect(questions.length, 1);
    expect(questions.first.pack, 'Current knowledge');
    expect(questions.first.hints.single, 'Named after a president');
  });

  test('numbered study-guide lines become questions', () {
    final questions = parseQuestionSheet(
      '1. What does SONAR stand for?\n'
      'Sound Navigation and Ranging\n'
      '2. What does RADAR stand for?\n'
      'Radio Detection and Ranging',
    );
    expect(questions.length, 2);
    expect(questions.first.answer, 'Sound Navigation and Ranging');
    expect(questions[1].answer, 'Radio Detection and Ranging');
  });

  testWidgets('awarding points updates player and team totals', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();

    controller.awardPoints(controller.roster.first, 10, 'Test award');

    expect(controller.teams.first.score, 10);
    expect(controller.history.length, 1);
    expect(controller.history.first.delta, 10);
  });

  testWidgets('a group holds four or more players, each with a buzzer key',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();

    // The starter roster is two groups of four, not two of two.
    expect(controller.teams.first.players.length, 4);
    expect(controller.teams.last.players.length, 4);

    // Nothing caps a group at four: a fifth player is accepted.
    final Player? fifth =
        controller.addPlayer(controller.teams.first.id, 'Fifth player');
    expect(fifth, isNotNull);
    expect(controller.teams.first.players.length, 5);
    expect(controller.roster.length, 9);

    // Every roster player still gets a keyboard key, in roster order.
    for (int i = 0; i < controller.roster.length; i++) {
      expect(controller.deviceToPlayer['K${i + 1}'], controller.roster[i].id);
    }
  });

  testWidgets('first buzz wins and a wrong answer locks that player out',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.buzzers.arm();

    controller.buzzers.press('K2', source: 'keyboard');
    expect(controller.activePlayer?.name, 'Player 2');

    controller.scoreWrong();
    expect(controller.lockedOut, contains('player-demo-2'));
    expect(controller.teams.first.players[1].score, -5);
    expect(controller.activeBuzz.value, isNull);

    // The locked-out player's next press is discarded…
    controller.buzzers.press('K2', source: 'keyboard');
    expect(controller.activeBuzz.value, isNull);

    // …but another player can still buzz in.
    controller.buzzers.press('K1', source: 'keyboard');
    expect(controller.activePlayer?.name, 'Player 1');
  });

  testWidgets('hardware messages resolve to a paired player', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.assignDevice('BOX-3', controller.roster[2].id);
    controller.buzzers.arm();

    controller.buzzers.press('BOX-3', source: 'hardware');

    expect(controller.activePlayer?.name, 'Player 3');
    expect(controller.buzzesFrom('BOX-3'), 'Player 3');
  });

  // Runs on the Dart VM, so it exercises the dart:io transport that the macOS
  // and Windows builds use — against a real WebSocket server, not a mock.
  test('a hardware box press over a real socket reaches the console', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HttpServer server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final List<WebSocket> clients = <WebSocket>[];
    server.listen((HttpRequest request) async {
      clients.add(await WebSocketTransformer.upgrade(request));
    });

    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.assignDevice('A1', controller.roster[1].id);
    await controller.connectBuzzers('ws://127.0.0.1:${server.port}/buzzers');

    final DateTime upgradeDeadline =
        DateTime.now().add(const Duration(seconds: 5));
    while (clients.isEmpty && DateTime.now().isBefore(upgradeDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    expect(clients, isNotEmpty, reason: 'receiver never accepted the socket');

    controller.buzzers.arm();
    clients.first.add('A1');

    final DateTime pressDeadline =
        DateTime.now().add(const Duration(seconds: 5));
    while (controller.activePlayer == null &&
        DateTime.now().isBefore(pressDeadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }

    expect(controller.activePlayer?.name, 'Player 2');

    controller.buzzers.disconnect();
    await server.close(force: true);
  });

  test('a plain http address is rejected with a useful hint', () async {
    final Completer<String?> error = Completer<String?>();
    BuzzerSocket(
      url: 'http://192.168.1.50:8080',
      onMessage: (_) {},
      onError: (String? message) {
        if (!error.isCompleted) error.complete(message);
      },
    );
    expect(await error.future, contains('ws://'));
  });

  testWidgets('the clock counts down and stops at zero', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.setSeconds(5);

    controller.startTimer();
    expect(controller.timerRunning.value, isTrue);
    expect(controller.remaining.value, 5);

    await tester.pump(const Duration(seconds: 5));
    expect(controller.remaining.value, 0);
    expect(controller.timerRunning.value, isFalse);
    expect(controller.timeExpired.value, isTrue);
    controller.onClose();
  });

  test('a B: line becomes the bonus question', () {
    final questions = parseQuestionSheet(
      'Q: What is the capital of Florida?\n'
      'A: Tallahassee\n'
      'B: What is the capital of Hawaii?',
    );
    expect(questions.single.bonus, 'What is the capital of Hawaii?');
    expect(questions.single.answer, 'Tallahassee');
  });

  testWidgets('a correct answer pays 10 then offers that team a bonus',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.setBonusPoints(15);
    controller.buzzers.arm();

    controller.buzzers.press('K2', source: 'keyboard');
    controller.scoreCorrect();

    expect(controller.teams.first.score, 10);
    expect(controller.bonusActive, isTrue);
    expect(controller.bonusTeamId.value, controller.teams.first.id);

    controller.awardBonus();
    expect(controller.teams.first.score, 25);
    expect(controller.bonusActive, isFalse);
    controller.onClose();
  });

  testWidgets('a missed bonus costs nothing', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.buzzers.arm();

    controller.buzzers.press('K1', source: 'keyboard');
    controller.scoreCorrect();
    controller.skipBonus();

    expect(controller.teams.first.score, 10);
    expect(controller.bonusActive, isFalse);
    controller.onClose();
  });

  testWidgets('a wrong answer costs 5 and never opens a bonus', (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.buzzers.arm();

    controller.buzzers.press('K1', source: 'keyboard');
    controller.scoreWrong();

    expect(controller.teams.first.score, -5);
    expect(controller.bonusActive, isFalse);
    controller.onClose();
  });

  testWidgets('the lightning round scores 10 and -5 with no bonus',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.toggleLightning();
    expect(controller.lightningRound.value, isTrue);

    controller.buzzers.arm();
    controller.buzzers.press('K1', source: 'keyboard');
    controller.scoreCorrect();
    expect(controller.teams.first.score, 10);
    expect(controller.bonusActive, isFalse);

    controller.buzzers.arm();
    controller.buzzers.press('K2', source: 'keyboard');
    controller.scoreWrong();
    expect(controller.teams.first.score, 5);
    expect(controller.bonusActive, isFalse);
    controller.onClose();
  });

  testWidgets('the match clock turns the game into a lightning round',
      (tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final HostController controller = HostController();
    controller.loadDemoTeams();
    controller.setMatchSeconds(2);
    controller.startMatch();
    expect(controller.matchRunning.value, isTrue);
    expect(controller.lightningRound.value, isFalse);

    await tester.pump(const Duration(seconds: 2));

    expect(controller.matchRemaining.value, 0);
    expect(controller.matchRunning.value, isFalse);
    expect(controller.lightningRound.value, isTrue);
    controller.onClose();
  });
}
