part of 'main.dart';

extension StudioData on _StudioState {
  Future<void> loadAutosave() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('autosave');
    if (saved != null) {
      try {
        final d = Doc.decode(saved);
        if (mounted) {
          setState(() {
            doc = d;
          });
        }
      } catch (e) {
        toast('Saved drawing could not be read. Starting blank.');
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => fitView());
  }

  void toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
          SnackBar(content: Text(msg), duration: const Duration(seconds: 2)));
  }

  void pushUndo() {
    undoStack.add(doc.encode());
    if (undoStack.length > 100) undoStack.removeAt(0);
    redoStack.clear();
  }

  void clearSelection() {
    selWall = null;
    selRoom = null;
  }

  void scheduleSave() {
    saveTimer?.cancel();
    saveTimer = Timer(const Duration(milliseconds: 500), () async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('autosave', doc.encode());
    });
  }

  void undo() {
    if (undoStack.isEmpty) return;
    redoStack.add(doc.encode());
    final prev = undoStack.removeLast();
    setState(() {
      doc = Doc.decode(prev);
      clearSelection();
    });
    scheduleSave();
  }

  void redo() {
    if (redoStack.isEmpty) return;
    undoStack.add(doc.encode());
    final next = redoStack.removeLast();
    setState(() {
      doc = Doc.decode(next);
      clearSelection();
    });
    scheduleSave();
  }

  void fitView() {
    if (!mounted || canvasSize == Size.zero) return;
    final pts = <Offset>[];
    for (final w in doc.walls) {
      pts.add(w.a);
      pts.add(w.b);
    }
    for (final r in doc.rooms) {
      pts.add(r.a);
      pts.add(r.b);
    }
    if (pts.isEmpty) {
      setState(() {
        view.scale = 0.08;
        view.origin = const Offset(60, 120);
      });
      return;
    }
    var minX = pts.first.dx;
    var maxX = minX;
    var minY = pts.first.dy;
    var maxY = minY;
    for (final p in pts) {
      minX = min(minX, p.dx);
      maxX = max(maxX, p.dx);
      minY = min(minY, p.dy);
      maxY = max(maxY, p.dy);
    }
    final bw = max(maxX - minX, 1000.0);
    final bh = max(maxY - minY, 1000.0);
    final s = min((canvasSize.width - 80) / bw, (canvasSize.height - 200) / bh)
        .clamp(0.005, 1.0)
        .toDouble();
    setState(() {
      view.scale = s;
      view.origin = Offset(
        canvasSize.width / 2 - (minX + maxX) / 2 * s,
        canvasSize.height / 2 - (minY + maxY) / 2 * s,
      );
    });
  }
}
