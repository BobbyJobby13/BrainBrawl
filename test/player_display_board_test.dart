import 'package:brainbrawl/app/modules/host/views/player_display_view.dart';
import 'package:brainbrawl/theme/themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';

/// A full board: choices, revealed hints, a bonus, a buzz and the room code.
Map<String, dynamic> sampleBoard() => <String, dynamic>{
      'at': DateTime.now().millisecondsSinceEpoch,
      'index': 2,
      'total': 28,
      'prompt': 'What does the acronym SONAR stand for?',
      'answer': 'SOund Navigation And Ranging',
      'pack': 'Naval Science 2',
      'points': 10,
      'choices': <String>[
        'SOund Navigation And Ranging',
        'Submerged Object Navigation And Radar',
        'Signal Optimal Naval Array Reporting',
        'Sonar Optical Node And Receiver',
      ],
      'hints': <String>['It begins with sound', 'The last word is ranging'],
      'seconds': 20,
      'remaining': 13,
      'running': true,
      'expired': false,
      'lightning': false,
      'matchRemaining': 420,
      'bonus': 'Team Bravo',
      'buzz': 'Player 3',
      'buzzin': '482913',
      'teams': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': 'Team Alpha',
          'score': 40,
          'accent': 0,
          'players': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Player 1', 'score': 20},
            <String, dynamic>{'name': 'Player 2', 'score': 20},
          ],
        },
        <String, dynamic>{
          'name': 'Team Bravo',
          'score': 25,
          'accent': 1,
          'players': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Player 3', 'score': 15},
            <String, dynamic>{'name': 'Player 4', 'score': 10},
          ],
        },
        <String, dynamic>{
          'name': 'Team Charlie',
          'score': -5,
          'accent': 2,
          'players': <Map<String, dynamic>>[
            <String, dynamic>{'name': 'Player 5', 'score': 0},
            <String, dynamic>{'name': 'Player 6', 'score': -5},
          ],
        },
      ],
    };

Widget boardAt(Size size, Map<String, dynamic> state) => MaterialApp(
      theme: getBlackWhiteTheme(),
      home: Scaffold(
        body: SizedBox(
          width: size.width,
          height: size.height,
          child: PlayerBoard(state: state, width: size.width),
        ),
      ),
    );

void main() {
  // The board must lay out without a font download, and never overflow at a
  // projector's resolution.
  setUpAll(() => GoogleFonts.config.allowRuntimeFetching = false);

  const List<Size> sizes = <Size>[
    Size(1920, 1080),
    Size(1280, 720),
    Size(1024, 768),
  ];

  for (final Size size in sizes) {
    testWidgets(
      'board fits ${size.width.toInt()}x${size.height.toInt()}',
      (WidgetTester tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        await tester.pumpWidget(boardAt(size, sampleBoard()));
        await tester.pump();

        expect(tester.takeException(), isNull);
      },
    );
  }

  testWidgets('board renders a golden for review', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(boardAt(const Size(1920, 1080), sampleBoard()));
    await tester.pump();

    await expectLater(
      find.byType(PlayerBoard),
      matchesGoldenFile('goldens/player_board_1920x1080.png'),
    );
  });
}
