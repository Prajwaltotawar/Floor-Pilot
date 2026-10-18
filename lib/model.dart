import 'dart:convert';
import 'dart:ui' show Offset;
import 'units.dart';

/// Shortest distance from point p to segment a-b (world mm).
double distToSegment(Offset p, Offset a, Offset b) {
  final ab = b - a;
  final l2 = ab.dx * ab.dx + ab.dy * ab.dy;
  var t = 0.0;
  if (l2 > 1e-9) {
    t = ((p - a).dx * ab.dx + (p - a).dy * ab.dy) / l2;
    if (t < 0) t = 0;
    if (t > 1) t = 1;
  }
  return (p - (a + ab * t)).distance;
}

Offset _readOffset(Map<String, dynamic> j, String kx, String ky) =>
    Offset((j[kx] as num).toDouble(), (j[ky] as num).toDouble());

class Wall {
  final int id;
  Offset a;
  Offset b;
  double thickness;

  Wall(this.id, this.a, this.b, this.thickness);

  double get length => (b - a).distance;

  Map<String, dynamic> toJson() => {
        'id': id,
        'ax': a.dx,
        'ay': a.dy,
        'bx': b.dx,
        'by': b.dy,
        't': thickness,
      };

  factory Wall.fromJson(Map<String, dynamic> j) => Wall(
        (j['id'] as num).toInt(),
        _readOffset(j, 'ax', 'ay'),
        _readOffset(j, 'bx', 'by'),
        (j['t'] as num).toDouble(),
      );
}

class Room {
  final int id;
  Offset a;
  Offset b;
  String name;

  Room(this.id, this.a, this.b, this.name);

  double get width => (b.dx - a.dx).abs();
  double get height => (b.dy - a.dy).abs();
  double get area => width * height;
  double get perimeter => 2 * (width + height);

  Map<String, dynamic> toJson() => {
        'id': id,
        'ax': a.dx,
        'ay': a.dy,
        'bx': b.dx,
        'by': b.dy,
        'n': name,
      };

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        (j['id'] as num).toInt(),
        _readOffset(j, 'ax', 'ay'),
        _readOffset(j, 'bx', 'by'),
        j['n'] as String,
      );
}

class Doc {
  String name;
  LengthUnit unit;
  int nextId;
  final List<Wall> walls;
  final List<Room> rooms;

  Doc({
    this.name = 'Untitled',
    this.unit = LengthUnit.m,
    this.nextId = 1,
    List<Wall>? walls,
    List<Room>? rooms,
  })  : walls = walls ?? <Wall>[],
        rooms = rooms ?? <Room>[];

  int newId() => nextId++;

  String encode() => jsonEncode({
        'v': 1,
        'name': name,
        'unit': unit.index,
        'nextId': nextId,
        'walls': [for (final w in walls) w.toJson()],
        'rooms': [for (final r in rooms) r.toJson()],
      });

  static Doc decode(String text) {
    final j = jsonDecode(text) as Map<String, dynamic>;
    if ((j['v'] as num) != 1) {
      throw const FormatException('Unsupported project version');
    }
    return Doc(
      name: j['name'] as String,
      unit: LengthUnit.values[(j['unit'] as num).toInt()],
      nextId: (j['nextId'] as num).toInt(),
      walls: [
        for (final w in j['walls'] as List)
          Wall.fromJson(w as Map<String, dynamic>)
      ],
      rooms: [
        for (final r in j['rooms'] as List)
          Room.fromJson(r as Map<String, dynamic>)
      ],
    );
  }
}
