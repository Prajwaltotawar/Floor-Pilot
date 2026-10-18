import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'canvas.dart';
import 'model.dart';
import 'units.dart';

part 'studio_pointer.dart';
part 'studio_data.dart';
part 'studio_commands.dart';
part 'studio_files.dart';
part 'studio_ui.dart';

void main() => runApp(const CadApp());

enum Tool { select, wall, room, pan }

class CadApp extends StatelessWidget {
  const CadApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Floor Pilot',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          brightness: Brightness.dark,
          useMaterial3: true,
          colorScheme:
              ColorScheme.fromSeed(seedColor: kAccent, brightness: Brightness.dark),
          scaffoldBackgroundColor: kBg,
        ),
        home: const Studio(),
      );
}

class Studio extends StatefulWidget {
  const Studio({super.key});

  @override
  State<Studio> createState() => _StudioState();
}

class _StudioState extends State<Studio> {
  Doc doc = Doc();
  final PlanView view = PlanView(0.08, const Offset(60, 120));
  Size canvasSize = Size.zero;
  Tool tool = Tool.select;
  bool snapOn = true;
  bool gridOn = true;
  int? selWall;
  int? selRoom;
  Offset? draftA;
  Offset? draftB;
  Offset? cursor;
  final List<String> undoStack = [];
  final List<String> redoStack = [];
  final Map<int, Offset> pointers = {};
  Timer? saveTimer;
  String gesture = '';
  Offset gFocal = Offset.zero;
  Offset gOrigin = Offset.zero;
  double gScale = 0.08;
  Offset gLast = Offset.zero;

  @override
  void initState() {
    super.initState();
    loadAutosave();
  }

  @override
  void dispose() {
    saveTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => buildScreen();
}
