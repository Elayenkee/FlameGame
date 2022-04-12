import 'package:myapp/engine/condition.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/engine/trifunction.dart';
import 'package:myapp/engine/work.dart';
import 'package:myapp/utils.dart';

enum Works { ATTACK, HEAL, POISON, BLEED }

extension WorksExtension on Works {
  Work instanciate() {
    switch (this) {
      case Works.ATTACK:
        return ATTACK();
      case Works.HEAL:
        return HEAL();
      case Works.POISON:
        return POISON();
      case Works.BLEED:
        return BLEED();
    }
  }

  String getName() {
    switch (this) {
      case Works.ATTACK:
        return "ATTACK";
      case Works.HEAL:
        return "HEAL";
      case Works.POISON:
        return "POISON";
      case Works.BLEED:
        return "BLEED";
    }
  }
}

enum ParamTypes { ValueReader, Value, TargetSelector, Int }

extension ParamTypesExtension on ParamTypes {}

enum Conditions { /*EXIST, */ EQUALS, NOT_EQUALS, LOWER, HIGHER }

extension ConditionsExtension on Conditions {
  List<ParamTypes> getParams() {
    switch (this) {
      //case Conditions.EXIST:
      //  return [ParamTypes.TargetSelector, ParamTypes.Int];
      case Conditions.EQUALS:
      case Conditions.NOT_EQUALS:
      case Conditions.LOWER:
      case Conditions.HIGHER:
        return [
          ParamTypes.ValueReader,
          ParamTypes.ValueReader,
          ParamTypes.Value
        ];
    }
  }

  Condition instanciate(List params) 
  {
    Utils.log("Condition::instanciate $this $params");
    switch (this) {
      //case Conditions.EXIST:
      //  return EXIST(params);
      case Conditions.EQUALS:
        return EQUALS(params);
      case Conditions.NOT_EQUALS:
        return NOT_EQUALS(params);
      case Conditions.LOWER:
        return LOWER(params);
      case Conditions.HIGHER:
        return HIGHER(params);
    }
  }

  bool isBinary() {
    switch (this) {
      case Conditions.EQUALS:
      case Conditions.NOT_EQUALS:
      case Conditions.LOWER:
      case Conditions.HIGHER:
        return true;
      default:
        return false;
    }
  }

  String getName() {
    switch (this) {
      //case Conditions.EXIST:
      //  return "EXIST";
      case Conditions.EQUALS:
        return "=";
      case Conditions.NOT_EQUALS:
        return "<>";
      case Conditions.LOWER:
        return "<";
      case Conditions.HIGHER:
        return ">";
    }
  }
}

enum TriFunctions { LOWEST, HIGHEST }

extension TriFunctionsExtension on TriFunctions {
  TriFunction instanciate(VALUE value) {
    switch (this) {
      case TriFunctions.LOWEST:
        return LOWEST(value);
      case TriFunctions.HIGHEST:
        return HIGHEST(value);
    }
  }

  String getName() {
    switch (this) {
      case TriFunctions.HIGHEST:
        return "HIGHEST";
      case TriFunctions.LOWEST:
        return "LOWEST";
    }
  }
}
