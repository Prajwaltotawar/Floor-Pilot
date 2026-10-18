part of 'main.dart';

extension StudioPointer on _StudioState {
  void pDown(PointerDownEvent e) {
    pointers[e.pointer] = e.localPosition;
  }

  void pMove(PointerMoveEvent e) {
    pointers[e.pointer] = e.localPosition;
    setState(() {
      cursor = view.toWorld(e.localPosition);
    });
  }

  void pUp(PointerEvent e) {
    pointers.remove(e.pointer);
  }

  void setTool(Tool t) {
    setState(() {
      tool = t;
      draftA = null;
      draftB = null;
    });
  }

  Offset snap(Offset w) {
    if (!snapOn) return w;
    const g = 50.0;
    return Offset(
        (w.dx / g).roundToDouble() * g, (w.dy / g).roundToDouble() * g);
  }

  Wall? hitWall(Offset w) {
    final tol = 12 / view.scale;
    Wall? best;
    var bestD = double.infinity;
    for (final wall in doc.walls) {
      final d = distToSegment(w, wall.a, wall.b) - wall.thickness / 2;
      if (d <= tol && d < bestD) {
        bestD = d;
        best = wall;
      }
    }
    return best;
  }

  Room? hitRoom(Offset w) {
    final tol = 8 / view.scale;
    for (final r in doc.rooms.reversed) {
      if (Rect.fromPoints(r.a, r.b).inflate(tol).contains(w)) return r;
    }
    return null;
  }

  void moveSelected(Offset d) {
    for (final w in doc.walls) {
      if (w.id == selWall) {
        w.a += d;
        w.b += d;
      }
    }
    for (final r in doc.rooms) {
      if (r.id == selRoom) {
        r.a += d;
        r.b += d;
      }
    }
  }

  void scaleStart(ScaleStartDetails d) {
    gFocal = d.localFocalPoint;
    gScale = view.scale;
    gOrigin = view.origin;
    gesture = '';
    if (pointers.length >= 2) {
      gesture = 'zoom';
      return;
    }
    final w = view.toWorld(d.localFocalPoint);
    if (tool == Tool.pan) {
      gesture = 'pan';
    } else if (tool == Tool.wall || tool == Tool.room) {
      final s = snap(w);
      setState(() {
        draftA = s;
        draftB = s;
      });
      gesture = 'draw';
    } else {
      final wall = hitWall(w);
      final room = wall == null ? hitRoom(w) : null;
      if (wall != null || room != null) {
        pushUndo();
        setState(() {
          selWall = wall?.id;
          selRoom = room?.id;
        });
        gLast = w;
        gesture = 'move';
      } else {
        gesture = 'pan';
      }
    }
  }

  void scaleUpdate(ScaleUpdateDetails d) {
    if (pointers.length >= 2 && gesture != 'zoom') {
      gesture = 'zoom';
      gFocal = d.localFocalPoint;
      gScale = view.scale;
      gOrigin = view.origin;
      setState(() {
        draftA = null;
        draftB = null;
      });
      return;
    }
    final fp = d.localFocalPoint;
    if (gesture == 'zoom') {
      final ns = (gScale * d.scale).clamp(0.005, 2.0).toDouble();
      final wf = (gFocal - gOrigin) / gScale;
      setState(() {
        view.scale = ns;
        view.origin = fp - wf * ns;
      });
    } else if (gesture == 'pan') {
      setState(() {
        view.origin = gOrigin + (fp - gFocal);
      });
    } else if (gesture == 'draw') {
      final s = snap(view.toWorld(fp));
      setState(() {
        draftB = s;
      });
    } else if (gesture == 'move') {
      final cur = view.toWorld(fp);
      final delta = cur - gLast;
      gLast = cur;
      setState(() {
        moveSelected(delta);
        cursor = cur;
      });
    }
  }

  void scaleEnd(ScaleEndDetails d) {
    if (gesture == 'draw') {
      final a = draftA;
      final b = draftB;
      setState(() {
        draftA = null;
        draftB = null;
      });
      if (a != null && b != null) addFromDraft(a, b);
    } else if (gesture == 'move') {
      scheduleSave();
    }
    gesture = '';
  }

  void tapAt(Offset p) {
    if (tool != Tool.select) return;
    final w = view.toWorld(p);
    final wall = hitWall(w);
    final room = wall == null ? hitRoom(w) : null;
    setState(() {
      selWall = wall?.id;
      selRoom = room?.id;
    });
  }
}
