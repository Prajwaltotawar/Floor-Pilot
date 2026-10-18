enum LengthUnit { mm, m, ftIn }

String unitName(LengthUnit u) => switch (u) {
      LengthUnit.mm => 'mm',
      LengthUnit.m => 'm',
      LengthUnit.ftIn => 'ft-in',
    };

LengthUnit nextUnit(LengthUnit u) =>
    LengthUnit.values[(u.index + 1) % LengthUnit.values.length];

String formatLength(double mm, LengthUnit u) {
  if (mm < 0) return '-${formatLength(-mm, u)}';
  return switch (u) {
    LengthUnit.mm => '${mm.round()} mm',
    LengthUnit.m => '${(mm / 1000).toStringAsFixed(3)} m',
    LengthUnit.ftIn => _ftIn(mm),
  };
}

String _ftIn(double mm) {
  final totalIn = mm / 25.4;
  var feet = totalIn ~/ 12;
  var inch = (totalIn - feet * 12).round();
  if (inch == 12) {
    feet += 1;
    inch = 0;
  }
  return "$feet' $inch\"";
}

String formatArea(double mm2, LengthUnit u) {
  if (u == LengthUnit.ftIn) {
    return '${(mm2 / 92903.04).toStringAsFixed(2)} sq ft';
  }
  return '${(mm2 / 1e6).toStringAsFixed(2)} m²';
}

/// Text that parses back exactly. Used to pre-fill edit dialogs.
String inputText(double mm, LengthUnit u) => switch (u) {
      LengthUnit.mm => '${mm.round()}mm',
      LengthUnit.m => '${(mm / 1000).toStringAsFixed(3)}m',
      LengthUnit.ftIn => _ftInInput(mm),
    };

String _ftInInput(double mm) {
  final totalIn = mm / 25.4;
  final feet = totalIn ~/ 12;
  final inch = (totalIn - feet * 12).toStringAsFixed(2);
  return '${feet}ft${inch}in';
}

double _factor(String unit) => switch (unit) {
      'mm' => 1.0,
      'cm' => 10.0,
      'm' => 1000.0,
      'ft' => 304.8,
      _ => 25.4,
    };

String _short(LengthUnit u) => switch (u) {
      LengthUnit.mm => 'mm',
      LengthUnit.m => 'm',
      LengthUnit.ftIn => 'ft',
    };

/// Parses a length and returns millimetres. Throws FormatException with a
/// plain-language message when the input is not understood.
double parseLength(String input, LengthUnit fallback) {
  final s = input.trim().toLowerCase();
  if (s.isEmpty) {
    throw const FormatException('Enter a length such as 3m, 2500mm or 8ft');
  }
  final feetInches =
      RegExp(r'^(\d+)\s*ft\s*(\d+(?:\.\d+)?)\s*(?:in)?$').firstMatch(s);
  if (feetInches != null) {
    return double.parse(feetInches.group(1)!) * 304.8 +
        double.parse(feetInches.group(2)!) * 25.4;
  }
  final single =
      RegExp(r'^(\d+(?:\.\d+)?)\s*(mm|cm|m|ft|in)?$').firstMatch(s);
  if (single != null) {
    final value = double.parse(single.group(1)!);
    return value * _factor(single.group(2) ?? _short(fallback));
  }
  throw FormatException(
      'Could not read "${input.trim()}". Try 3m, 2500mm, 8ft, 36in or 8ft6in');
}
