import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';

abstract class TriFunction {
  List<Entity> sort(List<Entity> liste) {
    List<Entity> oldListe = List.from(liste);
    List<Entity> newListe = List.empty(growable: true);

    while (oldListe.length > 0) {
      Entity current = oldListe.first;
      for (int i = 1; i < oldListe.length; i++) {
        Entity c = oldListe[i];
        if (isBefore(c, current)) current = c;
      }
      oldListe.remove(current);
      newListe.add(current);
    }

    return newListe;
  }

  bool isBefore(ValueReader a, ValueReader b);
}

class LOWEST extends TriFunction {
  late VALUE value;

  LOWEST(VALUE value) {
    this.value = value;
  }

  @override
  bool isBefore(ValueReader a, ValueReader b) {
    Object? valueA = a.getValue(value);
    Object? valueB = b.getValue(value);

    bool aComparable = valueA is Comparable;
    bool bComparable = valueB is Comparable;

    if (aComparable && bComparable) {
      int result = valueA.compareTo(valueB);
      return result < 0;
    }

    return false;
  }
}

class HIGHEST extends TriFunction {
  late VALUE value;

  HIGHEST(VALUE value) {
    this.value = value;
  }

  @override
  bool isBefore(ValueReader a, ValueReader b) {
    Object? valueA = a.getValue(value);
    Object? valueB = b.getValue(value);

    bool aComparable = valueA is Comparable;
    bool bComparable = valueB is Comparable;

    if (aComparable && bComparable) {
      int result = valueA.compareTo(valueB);
      return result > 0;
    }

    return false;
  }
}
