import 'package:flutter/material.dart';
import 'model.dart';
import 'units.dart';

const kBg = Color(0xFF111820);
const kPanel = Color(0xFF141F2E);
const kAccent = Color(0xFF2F9BFF);
const kAmber = Color(0xFFFFC107);
const kWall = Color(0xFFE3EAF2);
const kRoom = Color(0xFF2F9BFF);
const kDim = Color(0xFF69F0AE);
const kGrid = Color(0xFF1B2735);
const kGridMajor = Color(0xFF243448);

/// Maps world coordinates (mm, Y down) to screen pixels.
class PlanView {
  double scale; // screen pixels per mm
  Offset origin; // screen position of world (0, 0)

  PlanView(this.scale, this.origin);

  Offset toScreen(Offset w) =>
      Offset(w.dx * scale + origin.dx, w.dy * scale + origin.dy);

  Offset toWorld(Offset s) =>
      Offset((s.dx - origin.dx) / scale, (s.dy - origin.dy) / scale);
}

class PlanPainter extends CustomPainter {
  final Doc doc;
  final PlanView view;
  final int? selWall;
  final int? selRoom;
  final Offset? draftA;
  final Offset? draftB;
  final bool draftIsRoom;
  final bool gridOn;

  PlanPainter({
    required this.doc,
    required this.view,
    this.selWall,
    this.selRoom,
    this.draftA,
    this.draftB,
    this.draftIsRoom = false,
    this.gridOn = true,
  });

  @override
  void paint(Canvas c, Size size) {
    c.drawRect(Offset.zero & size, Paint()..color = kBg);
    if (gridOn) _grid(c, size);
    for (final r in doc.rooms) {
      _room(c, r);
    }
    for (final w in doc.walls) {
      _wall(c, w);
    }
    final a = draftA;
    final b = draftB;
    if (a != null && b != null && (b - a).distance > 1) {
      _draft(c, a, b);
    }
    _axes(c);
  }

  void _grid(Canvas c, Size size) {
    var step = 100.0;
    while (step * view.scale < 18) {
      step *= 10;
    }
    final tl = view.toWorld(Offset.zero);
    final br = view.toWorld(Offset(size.width, size.height));
    final minor = Paint()
      ..color = kGrid
      ..strokeWidth = 1;
    final major = Paint()
      ..color = kGridMajor
      ..strokeWidth = 1;
    final ix0 = (tl.dx / step).floor();
    final ix1 = (br.dx / step).ceil();
    for (var i = ix0; i <= ix1; i++) {
      final x = view.toScreen(Offset(i * step, 0)).dx;
      c.drawLine(
          Offset(x, 0), Offset(x, size.height), i % 10 == 0 ? major : minor);
    }
    final iy0 = (tl.dy / step).floor();
    final iy1 = (br.dy / step).ceil();
    for (var j = iy0; j <= iy1; j++) {
      final y = view.toScreen(Offset(0, j * step)).dy;
      c.drawLine(
          Offset(0, y), Offset(size.width, y), j % 10 == 0 ? major : minor);
    }
  }

  void _wall(Canvas c, Wall w) {
    final sel = w.id == selWall;
    final pa = view.toScreen(w.a);
    final pb = view.toScreen(w.b);
    final th = (w.thickness * view.scale).clamp(2.0, 80.0).toDouble();
    final color = sel ? kAmber : kWall;
    c.drawLine(pa, pb, Paint()..color = color..strokeWidth = th);
    if ((pb - pa).distance > 40) {
      final mid = (pa + pb) / 2;
      _text(c, formatLength(w.length, doc.unit),
          mid + Offset(0, -th / 2 - 10), 11, color,
          bold: sel);
    }
    if (sel) {
      for (final p in [pa, pb]) {
        c.drawCircle(p, 5, Paint()..color = kAmber);
      }
    }
  }

  void _room(Canvas c, Room r) {
    final sel = r.id == selRoom;
    final rect = Rect.fromPoints(view.toScreen(r.a), view.toScreen(r.b));
    final color = sel ? kAmber : kRoom;
    final sw = sel ? 2.5 : 1.5;
    c.drawRect(rect, Paint()..color = color.withValues(alpha: 0.12));
    c.drawRect(
        rect,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = sw
          ..color = color);
    if (rect.width > 70 && rect.height > 50) {
      final center = rect.center;
      _text(c, r.name, center + const Offset(0, -18), 13, Colors.white,
          bold: true);
      _text(c, formatArea(r.area, doc.unit), center, 12, Colors.white);
      _text(
          c,
          '${formatLength(r.width, doc.unit)} × ${formatLength(r.height, doc.unit)}',
          center + const Offset(0, 16),
          11,
          kDim);
    }
  }

  void _draft(Canvas c, Offset a, Offset b) {
    if (draftIsRoom) {
      final rect = Rect.fromPoints(view.toScreen(a), view.toScreen(b));
      c.drawRect(rect, Paint()..color = kRoom.withValues(alpha: 0.15));
      c.drawRect(
          rect,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = kRoom);
      final wmm = (b.dx - a.dx).abs();
      final hmm = (b.dy - a.dy).abs();
      _text(c, '${formatLength(wmm, doc.unit)} × ${formatLength(hmm, doc.unit)}',
          rect.center, 12, kRoom,
          bold: true);
      _text(c, formatArea(wmm * hmm, doc.unit),
          rect.center + const Offset(0, 16), 12, Colors.white);
    } else {
      final pa = view.toScreen(a);
      final pb = view.toScreen(b);
      c.drawLine(pa, pb, Paint()..color = kAccent..strokeWidth = 4);
      _text(c, formatLength((b - a).distance, doc.unit),
          (pa + pb) / 2 + const Offset(0, -14), 12, kAccent,
          bold: true);
    }
  }

  void _axes(Canvas c) {
    final o = view.toScreen(Offset.zero);
    c.drawLine(o, o + const Offset(40, 0),
        Paint()..color = const Color(0xFFFF5252)..strokeWidth = 2);
    c.drawLine(o, o + const Offset(0, -40),
        Paint()..color = const Color(0xFF52FF7A)..strokeWidth = 2);
  }

  void _text(Canvas c, String s, Offset at, double size, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: s,
        style: TextStyle(
          fontSize: size,
          color: color,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, at - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(covariant PlanPainter old) => true;
}
