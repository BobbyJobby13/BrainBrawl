import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:brainbrawl/theme/themes.dart';
import 'app/routes/app_pages.dart';
import 'platform/live_link.dart';
import 'package:sizer/sizer.dart';

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  // A second copy started by the console is the player board for the
  // projector; a plain launch is the host console.
  final bool displayMode = LiveLink.isDisplayInstance(args);
  if (displayMode) LiveLink.startDisplayHeartbeat();
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
