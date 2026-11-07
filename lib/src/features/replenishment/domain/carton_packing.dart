// Carton packing guide for a van load. Count only: cartons are never
// stock-moved or posted anywhere.
//
// Pure Dart on purpose (no Flutter imports) so the rules are unit-tested
// without a widget tree.

enum CartonType { b2b, large }

/// B2B carton capacity in integer units: 12 medium, 8 large or 20 small.
const int b2bCartonUnits = 120;

/// Large carton capacity in integer units: 20 medium, 11 large or 33 small.
///
/// The 33-small figure is an ASSUMPTION (not measured); the unit costs below
/// derive from it, so adjust [smallUnitLarge] if the real number differs.
const int largeCartonUnits = 660;

/// Units one jar takes up in a B2B carton.
const int smallUnitB2b = 6;
const int mediumUnitB2b = 10;
const int largeUnitB2b = 15;

/// Units one jar takes up in a Large carton.
const int smallUnitLarge = 20;
const int mediumUnitLarge = 33;
const int largeUnitLarge = 60;

/// One line of the load to pack.
class PackLine {
  const PackLine({
    required this.itemCode,
    required this.name,
    required this.size,
    required this.qty,
  });

  final String itemCode;
  final String name;

  /// "small" | "medium" | "large" | "" (unknown, packed by hand).
  final String size;
  final int qty;
}

class CartonLine {
  const CartonLine({
    required this.itemCode,
    required this.name,
    required this.size,
    required this.qty,
  });

  final String itemCode;
  final String name;
  final String size;
  final int qty;
}

class Carton {
  Carton({required this.number, required this.type});

  final int number;
  CartonType type;
  final List<CartonLine> lines = [];

  /// Units used, measured in this carton's current type.
  int get usedUnits => unitsFor(type);

  int get capacity => type == CartonType.large ? largeCartonUnits : b2bCartonUnits;

  int unitsFor(CartonType t) {
    var total = 0;
    for (final line in lines) {
      total += line.qty * jarUnits(line.size, t);
    }
    return total;
  }

  int get jars => lines.fold(0, (sum, l) => sum + l.qty);

  /// 0..100, rounded.
  int get fillPercent => (usedUnits * 100 / capacity).round();

  bool get isFull => usedUnits >= capacity;
}

class PackingResult {
  const PackingResult({
    required this.cartons,
    required this.unpacked,
    required this.totalJars,
  });

  final List<Carton> cartons;

  /// Lines with no known jar size: pack by hand.
  final List<PackLine> unpacked;
  final int totalJars;

  int get largeUsed => cartons.where((c) => c.type == CartonType.large).length;
  int get b2bUsed => cartons.where((c) => c.type == CartonType.b2b).length;
  bool get isEmpty => cartons.isEmpty && unpacked.isEmpty;
}

/// Units one jar of [size] takes in a carton of type [type]; 0 when unknown.
int jarUnits(String size, CartonType type) {
  final large = type == CartonType.large;
  switch (size) {
    case 'small':
      return large ? smallUnitLarge : smallUnitB2b;
    case 'medium':
      return large ? mediumUnitLarge : mediumUnitB2b;
    case 'large':
      return large ? largeUnitLarge : largeUnitB2b;
    default:
      return 0;
  }
}

int _sizeRank(String size) {
  switch (size) {
    case 'large':
      return 0;
    case 'medium':
      return 1;
    default:
      return 2;
  }
}

/// Packs [lines] into cartons.
///
/// Lines are grouped large jars first, then medium, then small, and by item
/// name inside a size, then filled sequentially so each item occupies
/// consecutive cartons. Sizes may mix in a carton (they share space by units).
/// Cartons open as Large while [largeInHand] lasts, else B2B; a trailing Large
/// carton that would fit a B2B one is switched, saving a Large carton.
PackingResult packCartons(List<PackLine> lines, {int largeInHand = 0}) {
  final packable = <PackLine>[];
  final unpacked = <PackLine>[];
  var totalJars = 0;
  for (final line in lines) {
    if (line.qty <= 0) continue;
    if (jarUnits(line.size, CartonType.b2b) == 0) {
      unpacked.add(line);
    } else {
      packable.add(line);
      totalJars += line.qty;
    }
  }
  packable.sort((a, b) {
    final bySize = _sizeRank(a.size).compareTo(_sizeRank(b.size));
    if (bySize != 0) return bySize;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });

  final cartons = <Carton>[];
  var largeUsed = 0;
  Carton open() {
    final type = largeUsed < largeInHand ? CartonType.large : CartonType.b2b;
    if (type == CartonType.large) largeUsed += 1;
    final carton = Carton(number: cartons.length + 1, type: type);
    cartons.add(carton);
    return carton;
  }

  for (final line in packable) {
    var remaining = line.qty;
    while (remaining > 0) {
      final carton = cartons.isEmpty ? open() : cartons.last;
      final unit = jarUnits(line.size, carton.type);
      final free = carton.capacity - carton.usedUnits;
      final n = remaining < free ~/ unit ? remaining : free ~/ unit;
      if (n == 0) {
        open();
        continue;
      }
      carton.lines.add(
        CartonLine(
          itemCode: line.itemCode,
          name: line.name,
          size: line.size,
          qty: n,
        ),
      );
      remaining -= n;
    }
  }

  if (cartons.isNotEmpty) {
    final last = cartons.last;
    if (last.type == CartonType.large &&
        last.unitsFor(CartonType.b2b) <= b2bCartonUnits) {
      last.type = CartonType.b2b;
    }
  }

  return PackingResult(
    cartons: cartons,
    unpacked: unpacked,
    totalJars: totalJars,
  );
}
