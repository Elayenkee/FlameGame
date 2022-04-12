import 'package:myapp/engine/dot.dart';

class ValueSolver {}

enum VALUE {
  NAME,
  HP,
  HP_MAX,
  MP,
  MP_MAX,
  ATK,
  DEF,
  MR,
  POW,
  HP_PERCENT,
  MP_PERCENT,
  CLAN,
  DOT,
  POISON,
  BLEED,
}

extension ValueExtension on VALUE 
{
  Object get defaultValue 
  {
    switch (this) 
    {
      case VALUE.NAME:
        return "unknown";
      case VALUE.DOT:
        return DotList();
      case VALUE.POISON:
        return DotList();
      case VALUE.BLEED:
        return DotList();
    }
    return 0;
  }

  String getName()
  {
    switch (this) 
    {
      case VALUE.NAME:
        return "NAME";
      case VALUE.HP:
        return "HP";
      case VALUE.HP_MAX:
        return "HP_MAX";
      case VALUE.MP:
        return "MP";
      case VALUE.MP_MAX:
        return "HP";
      case VALUE.ATK:
        return "ATK";
      case VALUE.DEF:
        return "DEF";
      case VALUE.MR:
        return "MR";
      case VALUE.POW:
        return "POW";
      case VALUE.HP_PERCENT:
        return "HP_PERCENT";
      case VALUE.MP_PERCENT:
        return "MP_PERCENT";
      case VALUE.CLAN:
        return "CLAN";
      case VALUE.DOT:
        return "DOT";
      case VALUE.POISON:
        return "POISON";
      case VALUE.BLEED:
        return "BLEED";
    }
  }
}

abstract class ValueReader 
{
  Object? getValue(VALUE? value);
}

class ValueAtom implements ValueReader 
{
  final Object value;

  ValueAtom(this.value);

  @override
  Object? getValue(VALUE? value) 
  {
    return this.value;
  }

  String getName()
  {
    return value.toString();
  }

  int getIntValue()
  {
    return value as int;
  }
}

class Count implements ValueReader
{
  ValueReader target;
  VALUE value;

  Count(this.target, this.value);

  @override
  Object? getValue(VALUE? v) 
  {
    Object? toCount = target.getValue(value);
    if(toCount != null && toCount is Countable)
      return toCount.count();
    return toCount;
  }
  
}

abstract class Countable
{
  int count();
}