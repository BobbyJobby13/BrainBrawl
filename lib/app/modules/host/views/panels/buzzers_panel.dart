import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../theme/palette.dart';
import '../../controllers/host_controller.dart';
import '../../models/game_models.dart';
import '../console_widgets.dart';

/// Buzzer setup: keyboard pairing, point values, and any hardware receiver the
/// host wants to plug in later.
class BuzzersPanel extends StatefulWidget {
  const BuzzersPanel(this.controller, {Key? key}) : super(key: key);

  final HostController controller;

  @override
  State<BuzzersPanel> createState() => _BuzzersPanelState();
}

class _BuzzersPanelState extends State<BuzzersPanel> {
  late final TextEditingController _url;
  late final TextEditingController _code;

  @override
  void initState() {
    super.initState();
    _url = TextEditingController(text: widget.controller.buzzerUrl.value);
    _code = TextEditingController(text: widget.controller.buzzinCode.value);
  }

  @override
  void dispose() {
    _url.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final controller = widget.controller;
      final List<Player> roster = controller.roster;
      final Set<String> devices = <String>{
        ...controller.deviceToPlayer.keys,
        ...controller.buzzers.seenDevices,
      };

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Buzzers & scoring rules',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: Palette.textPrimary,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              'Keyboard, touch, or a hardware box over WebSocket',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 12.5,
                color: Palette.textFaint,
              ),
            ),
            const SizedBox(height: 16),
            ConsoleCard(
              title: 'buzzin.live room',
              subtitle: 'Players buzz from their phones with this code',
              trailing: Pill(
                label: controller.buzzinCode.value.isEmpty ? 'NO CODE' : 'ROOM SET',
                color: controller.buzzinCode.value.isEmpty
                    ? Palette.textFaint
                    : Palette.success,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _code,
                    cursorColor: Palette.cyan,
                    onChanged: (String value) {
                      widget.controller.setBuzzinCode(value);
                      // Pasting a room link leaves the raw URL in the field, so
                      // swap in the code that was actually kept.
                      final String cleaned =
                          widget.controller.buzzinCode.value;
                      if (cleaned != value && _code.text != cleaned) {
                        _code.value = TextEditingValue(
                          text: cleaned,
                          selection: TextSelection.collapsed(
                            offset: cleaned.length,
                          ),
                        );
                      }
                    },
                    style: GoogleFonts.spaceMono(
                      fontSize: 18,
                      letterSpacing: 4,
                      fontWeight: FontWeight.w700,
                      color: Palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: '482913',
                      hintStyle: GoogleFonts.spaceMono(
                        fontSize: 18,
                        letterSpacing: 4,
                        color: Palette.textFaint,
                      ),
                      prefixIcon: const Icon(
                        Icons.confirmation_number_outlined,
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
                            BorderSide(color: Palette.cyan.withOpacity(0.7)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: <Widget>[
                      MiniAction(
                        label: 'Open host dashboard',
                        icon: Icons.open_in_new_rounded,
                        color: Palette.cyan,
                        filled: true,
                        onTap: widget.controller.openBuzzinHost,
                      ),
                      MiniAction(
                        label: 'Copy code',
                        icon: Icons.copy_rounded,
                        onTap: controller.buzzinCode.value.isEmpty
                            ? null
                            : widget.controller.copyBuzzinCode,
                      ),
                      MiniAction(
                        label: controller.showBuzzinCode.value
                            ? 'Hide game card'
                            : 'Show game card',
                        icon: Icons.visibility_rounded,
                        onTap: widget.controller.toggleShowBuzzinCode,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'The game card puts this code on the projected screen. '
                    'buzzin.live has no API, so this console cannot read its '
                    'buzz order: watch the host dashboard, then press the digit '
                    'for the player who buzzed first.',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      height: 1.5,
                      color: Palette.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'Point values',
              subtitle: 'Used by the quick Correct and Wrong buttons',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: <Widget>[
                      _ValueStepper(
                        label: 'Correct',
                        value: controller.correctPoints.value,
                        color: Palette.success,
                        onChanged: controller.setCorrectPoints,
                      ),
                      _ValueStepper(
                        label: 'Wrong',
                        value: controller.wrongPoints.value,
                        color: Palette.danger,
                        onChanged: controller.setWrongPoints,
                      ),
                      _ValueStepper(
                        label: 'Hint cost',
                        value: controller.hintPenalty.value,
                        color: Palette.cyan,
                        onChanged: controller.setHintPenalty,
                      ),
                      _ValueStepper(
                        label: 'Seconds',
                        value: controller.questionSeconds.value,
                        color: Palette.pink,
                        step: 5,
                        onChanged: controller.setSeconds,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: <Widget>[
                      Checkbox(
                        value: controller.lockoutAfterWrong.value,
                        activeColor: Palette.pink,
                        onChanged: (bool? value) =>
                            controller.setLockout(value ?? false),
                      ),
                      Expanded(
                        child: Text(
                          'Lock a player out of the rest of the question after a wrong answer',
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 12.5,
                            color: Palette.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'Hardware receiver',
              subtitle: 'Any buzzer system that can send a device id',
              trailing: Pill(
                label: controller.buzzers.connected.value
                    ? 'CONNECTED'
                    : 'NOT CONNECTED',
                color: controller.buzzers.connected.value
                    ? Palette.success
                    : Palette.textFaint,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  TextField(
                    controller: _url,
                    cursorColor: Palette.pink,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 14,
                      color: Palette.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'ws://192.168.1.50:8080/buzzers',
                      hintStyle: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        color: Palette.textFaint,
                      ),
                      prefixIcon: const Icon(
                        Icons.link_rounded,
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
                      MiniAction(
                        label: 'Connect',
                        icon: Icons.power_settings_new_rounded,
                        color: Palette.pink,
                        filled: true,
                        onTap: () => controller.connectBuzzers(_url.text),
                      ),
                      MiniAction(
                        label: 'Disconnect',
                        icon: Icons.link_off_rounded,
                        onTap: controller.disconnectBuzzers,
                      ),
                      MiniAction(
                        label: 'Test press',
                        icon: Icons.sensors_rounded,
                        onTap: () => controller.buzzers
                            .press('TEST-1', source: 'hardware'),
                      ),
                      MiniAction(
                        label: 'Protocol',
                        icon: Icons.help_outline_rounded,
                        onTap: () => showHelp(
                          context,
                          title: 'Buzzer protocol',
                          body: 'The console listens on one WebSocket and treats '
                              'every message as a buzz from a device.\n\n'
                              'Accepted messages:\n'
                              '  A1\n'
                              '  {"device":"A1"}\n'
                              '  {"buzzer":"A1"}\n'
                              '  {"id":"A1"}\n\n'
                              'A1 is whatever identifier the box uses; it becomes '
                              'the device id shown here, and you pair each device '
                              'with a player once. Any receiver that can forward its '
                              'button presses as one of those messages works — '
                              'Arduino/ESP32 Wi-Fi boxes, a Raspberry Pi bridge, or '
                              'a small relay service in front of a proprietary hub.',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    controller.buzzers.connectionStatus.value,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11.5,
                      color: controller.buzzers.connected.value
                          ? Palette.success
                          : Palette.textFaint,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'Keyboard pairing',
              subtitle: 'Digit keys follow roster order — no setup needed',
              child: roster.isEmpty
                  ? Text(
                      'Add players on the Teams tab to pair buzzers.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        color: Palette.textFaint,
                      ),
                    )
                  : Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: <Widget>[
                        for (int index = 0; index < roster.length; index++)
                          Pill(
                            label: index < 9
                                ? '${index + 1} · ${roster[index].name}'
                                : roster[index].name,
                            color: Palette.textSecondary,
                            icon: Icons.keyboard_rounded,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'Paired devices',
              subtitle: 'One device per player',
              child: devices.isEmpty
                  ? Text(
                      'No devices seen yet. Press Test press above, or buzz from a '
                      'connected receiver, and the device will appear here.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12.5,
                        height: 1.5,
                        color: Palette.textFaint,
                      ),
                    )
                  : Column(
                      children: <Widget>[
                        for (final String device in devices)
                          _DeviceRow(
                            controller: controller,
                            device: device,
                            roster: roster,
                          ),
                      ],
                    ),
            ),
            const SizedBox(height: 14),
            ConsoleCard(
              title: 'USB and keyboard buzzers',
              child: Text(
                'Most plug-and-play buzzer sets present themselves as a keyboard '
                'and type a letter or digit. Plug one in, press a button and use '
                'the digit keys above — if the set sends digits 1-9 it is already '
                'paired to the roster. Sets that send letters need the receiver '
                'path: forward their key presses as WebSocket messages using the '
                'protocol above.',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12.5,
                  height: 1.55,
                  color: Palette.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    });
  }
}

class _ValueStepper extends StatelessWidget {
  const _ValueStepper({
    required this.label,
    required this.value,
    required this.color,
    required this.onChanged,
    this.step = 1,
  });

  final String label;
  final int value;
  final Color color;
  final int step;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              MonoLabel(label, color: color, size: 9),
              const SizedBox(height: 2),
              Text(
                '$value',
                style: GoogleFonts.spaceMono(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Palette.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _StepButton(
                icon: Icons.remove_rounded,
                onTap: () => onChanged(value - step),
              ),
              const SizedBox(height: 4),
              _StepButton(
                icon: Icons.add_rounded,
                onTap: () => onChanged(value + step),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withOpacity(0.04),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Padding(
          padding: const EdgeInsets.all(3),
          child: Icon(icon, size: 14, color: Palette.textSecondary),
        ),
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow({
    required this.controller,
    required this.device,
    required this.roster,
  });

  final HostController controller;
  final String device;
  final List<Player> roster;

  @override
  Widget build(BuildContext context) {
    final String? assigned = controller.deviceToPlayer[device];
    final bool assignedExists =
        assigned != null && roster.any((Player p) => p.id == assigned);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            child: MonoLabel(device, color: Palette.cyan),
          ),
          Expanded(
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Palette.surfaceRaised,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Palette.border),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: assignedExists ? assigned : null,
                  isExpanded: true,
                  dropdownColor: Palette.surfaceRaised,
                  hint: Text(
                    'Assign to player',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12.5,
                      color: Palette.textFaint,
                    ),
                  ),
                  icon: const Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: Palette.textFaint,
                  ),
                  items: <DropdownMenuItem<String>>[
                    for (final Player player in roster)
                      DropdownMenuItem<String>(
                        value: player.id,
                        child: Text(
                          player.name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 13,
                            color: Palette.textPrimary,
                          ),
                        ),
                      ),
                  ],
                  onChanged: (String? value) {
                    if (value != null) {
                      controller.assignDevice(device, value);
                    }
                  },
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          MiniAction(
            label: 'Forget',
            icon: Icons.link_off_rounded,
            color: Palette.danger,
            onTap: () => controller.unassignDevice(device),
          ),
        ],
      ),
    );
  }
}
