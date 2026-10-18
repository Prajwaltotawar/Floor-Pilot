part of 'main.dart';

extension StudioCommands on _StudioState {
  void addFromDraft(Offset a, Offset b) {
    if (tool == Tool.wall) {
      if ((b - a).distance < 10) return;
      pushUndo();
      setState(() {
        doc.walls.add(Wall(doc.newId(), a, b, 230));
        clearSelection();
      });
      scheduleSave();
    } else if (tool == Tool.room) {
      if ((b.dx - a.dx).abs() < 10 || (b.dy - a.dy).abs() < 10) return;
      pushUndo();
      final room = Room(doc.newId(), a, b, 'ROOM ${doc.rooms.length + 1}');
      setState(() {
        doc.rooms.add(room);
        selRoom = room.id;
        selWall = null;
      });
      scheduleSave();
    }
  }

  Future<List<String>?> askFields(
      String title, List<String> labels, List<String> initial) {
    final ctrls = [for (final v in initial) TextEditingController(text: v)];
    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < labels.length; i++)
              TextField(
                controller: ctrls[i],
                autofocus: i == 0,
                decoration: InputDecoration(labelText: labels[i]),
              ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(ctx, [for (final c in ctrls) c.text]),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<bool> confirm(String msg) async {
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    return r == true;
  }

  /// Draws a wall of exact length and angle (0 = right, 90 = up), chained
  /// from the last wall end.
  Future<void> typedWall() async {
    if (tool != Tool.wall) setTool(Tool.wall);
    final start = draftA ??
        snap(view.toWorld(
            Offset(canvasSize.width / 2, canvasSize.height / 2)));
    final r = await askFields(
        'Wall from start point',
        ['Length (e.g. 3m, 3000mm, 10ft)', 'Angle (0 = right, 90 = up)'],
        ['3m', '0']);
    if (r == null) return;
    try {
      final len = parseLength(r[0], doc.unit);
      final angle = double.parse(r[1].trim()) * pi / 180;
      if (len <= 0) {
        throw const FormatException('Length must be more than 0');
      }
      final end = start + Offset(cos(angle), -sin(angle)) * len;
      pushUndo();
      setState(() {
        doc.walls.add(Wall(doc.newId(), start, end, 230));
        draftA = end;
        draftB = null;
      });
      scheduleSave();
    } on FormatException catch (e) {
      toast(e.message);
    }
  }

  Future<void> editSelected() async {
    Wall? wall;
    for (final w in doc.walls) {
      if (w.id == selWall) wall = w;
    }
    Room? room;
    for (final r in doc.rooms) {
      if (r.id == selRoom) room = r;
    }
    if (wall != null) {
      final w = wall;
      final r = await askFields(
          'Wall',
          ['Length', 'Thickness (mm)'],
          [inputText(w.length, doc.unit), w.thickness.round().toString()]);
      if (r == null) return;
      try {
        final len = parseLength(r[0], doc.unit);
        final th = double.parse(r[1].trim());
        if (len <= 0) {
          throw const FormatException('Length must be more than 0');
        }
        if (th <= 0) {
          throw const FormatException('Thickness must be more than 0');
        }
        final d = w.b - w.a;
        final l = d.distance;
        final u = l == 0 ? const Offset(1, 0) : d / l;
        pushUndo();
        setState(() {
          w.b = w.a + u * len;
          w.thickness = th;
        });
        scheduleSave();
      } on FormatException catch (e) {
        toast(e.message);
      }
    } else if (room != null) {
      final rm = room;
      final r = await askFields(
          'Room',
          ['Name', 'Width', 'Height'],
          [
            rm.name,
            inputText(rm.width, doc.unit),
            inputText(rm.height, doc.unit),
          ]);
      if (r == null) return;
      try {
        final name = r[0].trim().isEmpty ? rm.name : r[0].trim().toUpperCase();
        final wv = parseLength(r[1], doc.unit);
        final hv = parseLength(r[2], doc.unit);
        if (wv <= 0 || hv <= 0) {
          throw const FormatException('Width and height must be more than 0');
        }
        final sx = rm.b.dx >= rm.a.dx ? 1.0 : -1.0;
        final sy = rm.b.dy >= rm.a.dy ? 1.0 : -1.0;
        pushUndo();
        setState(() {
          rm.name = name;
          rm.b = Offset(rm.a.dx + sx * wv, rm.a.dy + sy * hv);
        });
        scheduleSave();
      } on FormatException catch (e) {
        toast(e.message);
      }
    } else {
      toast('Select a wall or room first');
    }
  }

  void deleteSelected() {
    if (selWall == null && selRoom == null) {
      toast('Select a wall or room first');
      return;
    }
    pushUndo();
    setState(() {
      doc.walls.removeWhere((w) => w.id == selWall);
      doc.rooms.removeWhere((r) => r.id == selRoom);
      clearSelection();
    });
    scheduleSave();
  }
}
