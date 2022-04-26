import 'package:myapp/utils.dart';

import 'valuesolver.dart';

abstract class Condition {
  Condition(List params);
  bool check(Object target);
}

abstract class ConditionAtom extends Condition {
  ConditionAtom(List params) : super(params);
}

abstract class ConditionBinary extends Condition 
{
  late ValueReader targetA;
  late ValueReader targetB;
  VALUE? value;

  ConditionBinary(List params) : super(params) 
  {
    this.targetA = params[0];
    this.targetB = params[1];
    if(params[2] is VALUE)
      this.value = params[2];
  }
}

class ConditionGroup extends Condition 
{
  late Condition conditionA;
  late Condition conditionB;
  late ConditionLink link;

  ConditionGroup(List params) : super(params) {
    this.conditionA = params[0];
    this.conditionB = params[1];
    this.link = params[2];
  }

  @override
  bool check(Object target) 
  {
    //Utils.logRun("ConditionGroup.run.check $target $conditionA $conditionB");
    bool result = false;
    if (conditionA.check(target))
      result = link == ConditionLink.OU || conditionB.check(target);
    else
      result = link == ConditionLink.OU && conditionB.check(target);
    //Utils.logRun("ConditionGroup.run.check $result");
    return result;
  }
}

class TRUE extends ConditionAtom {
  TRUE() : super([]);

  @override
  bool check(Object target) {
    return true;
  }
}

/*class EXIST extends ConditionAtom {
  late TargetSelector targetSelector;
  late int nb;

  EXIST(List params) : super(params) {
    this.targetSelector = params[0];
    this.nb = params[1];
  }

  @override
  bool check(Object target) {
    if (target is Server) {
      target = (target as Server).entities;
    }

    if (target is List) {
      try {
        List<Entity> liste = List.from(target);
        int result = 0;
        while (liste.length > 0) {
          Entity? e = targetSelector.get(liste);
          if (e != null) {
            result++;
            if (result >= nb) return true;
            liste.remove(e);
          }
        }
      } catch (e) {
        
      }
    }
    return false;
  }
}*/

class EQUALS extends ConditionBinary 
{
  EQUALS(List params) : super(params);

  @override
  bool check(Object target) 
  {
    Utils.logRun("EQUALS.run.check.start $targetA, $targetB, $value");
    Object? valueA = targetA.getValue(value);
    Utils.logRun("EQUALS.run.check valueA $valueA");
    Object? valueB = targetB.getValue(value);
    Utils.logRun("EQUALS.run.check valueB $valueB");
    bool result = valueA == valueB;
    Utils.logRun("EQUALS.run.check.end $result");
    return result;
  }
}

class NOT_EQUALS extends EQUALS {
  NOT_EQUALS(List params) : super(params);

  @override
  bool check(Object target) {
    return !super.check(target);
  }
}

class LOWER extends ConditionBinary {
  LOWER(List params) : super(params);

  @override
  bool check(Object target) 
  {
    Utils.logRun("LOWER.run.check.start $targetA $targetB");
    Object? valueA = targetA.getValue(value);
    Object? valueB = targetB.getValue(value);
    Utils.logRun("LOWER.run.check $valueA $valueB");

    bool aComparable = valueA is Comparable;
    bool bComparable = valueB is Comparable;

    bool result = false;
    if (aComparable && bComparable) 
    {
      int r = valueA.compareTo(valueB);
      result = r < 0;
    }
    Utils.logRun("LOWER.run.check.end $result");
    return result;
  }
}

class HIGHER extends ConditionBinary {
  HIGHER(List params) : super(params);

  @override
  bool check(Object target) {
    Object? valueA = targetA.getValue(value);
    Object? valueB = targetB.getValue(value);

    bool aComparable = valueA is Comparable;
    bool bComparable = valueB is Comparable;

    if (aComparable && bComparable) {
      int result = valueA.compareTo(valueB);
      return result > 0;
    }
    return false;
  }
}

enum ConditionLink { ET, OU }
