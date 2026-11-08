import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brainbrawl/theme/themes.dart';
import 'app/routes/app_pages.dart';
import 'package:sizer/sizer.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // A second copy started with `--display` is the player board for the
  // projector; a plain launch is the host console.
  final bool displayMode = args.contains('--display');
  runApp(Sizer(
    builder : (context, orientation, deviceType) =>
        GetMaterialApp(
      debugShowCheckedModeBanner: false,
      title: displayMode ? "Brain Brawl player display" : "Brain Brawl",
      initialRoute: displayMode ? Routes.DISPLAY : AppPages.INITIAL,
      getPages: AppPages.routes,
      theme: getBlackWhiteTheme(),
      defaultTransition: Transition.fadeIn,
      transitionDuration: const Duration(milliseconds: 320),
    ),
  ));
}
