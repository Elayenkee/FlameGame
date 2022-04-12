import 'package:myapp/engine/dot.dart';
import 'package:myapp/engine/work.dart';
import 'package:uuid/uuid.dart';

import 'server.dart';
import 'behaviour.dart';
import 'valuesolver.dart';

class Entity implements ValueReader 
{
  late String uuid;

  Map values = Map();

  int maxTimer = 45;
  late int timer = maxTimer;

  List<Behaviour> behaviours = [];

  Entity(Map map) 
  {
    setValues(map);
  }

  void setValues(Map map)
  {
    VALUE.values.forEach((value) {
      values[value] = value.defaultValue;
    });
    map.forEach((key, value) {
      values[key] = value;
    });
    init();
  }

  void init()
  {
    uuid = Uuid().v1();
    setValue(VALUE.HP, getValue(VALUE.HP_MAX));
    setValue(VALUE.MP, getValue(VALUE.MP_MAX));
  }

  void setValue(VALUE value, var object) 
  {
    values[value] = object;
    switch (value) {
      case VALUE.HP:
      case VALUE.HP_MAX:
        values[VALUE.HP_PERCENT] = getPercent(VALUE.HP, VALUE.HP_MAX);
        break;

      case VALUE.MP:
      case VALUE.MP_MAX:
        values[VALUE.MP_PERCENT] = getPercent(VALUE.MP, VALUE.MP_MAX);
        break;
    }
  }

  int getPercent(VALUE value, VALUE valueMax) 
  {
    int v = getValue(value) as int;
    if (v <= 0) return 0;
    int max = getValue(valueMax) as int;
    if(max <= 0) return 100;
    double percent = (100 * v) / max;
    return percent.toInt();
  }

  @override
  getValue(VALUE? value) 
  {
    if(value == VALUE.POISON)
      return DotList.withValue(VALUE.POISON, getDots());

    if(value == VALUE.BLEED)
      return DotList.withValue(VALUE.BLEED, getDots());
    
    return values[value!];
  }

  void setBehaviours(List<Behaviour> behaviours) 
  {
    this.behaviours = behaviours;
  }

  void run(Server server, Story story) 
  {
    List<DOT> dots = getDots().dots;
    for(DOT dot in dots)
    {
      dot.execute(this, this, story);
      if(!isAlive())
        return;
    }

    timer = maxTimer;
    for(Behaviour behaviour in behaviours)
    {
      if (behaviour.check(server)) 
      {
        if(behaviour.execute(this, story))
          return;
      }
    }

    NOTHING().execute(this, this, story);
  }

  void ellapse(int time)
  {
    timer -= time;
  }

  bool isAlive() 
  {
    int hp = int.parse(getValue(VALUE.HP).toString());
    return hp > 0;
  }

  String getName() {
    return getValue(VALUE.NAME).toString();
  }

  int getHP() {
    return getValue(VALUE.HP) as int;
  }

  int getHPMax() {
    return getValue(VALUE.HP_MAX) as int;
  }

  int getMP() {
    return getValue(VALUE.MP) as int;
  }

  int getMPMax() {
    return int.parse(getValue(VALUE.MP_MAX).toString());
  }

  int getPow() {
    return int.parse(getValue(VALUE.POW).toString());
  }

  int getMR() {
    return int.parse(getValue(VALUE.MR).toString());
  }

  int getATK() {
    return int.parse(getValue(VALUE.ATK).toString());
  }

  int getDEF() {
    return int.parse(getValue(VALUE.DEF).toString());
  }

  int getClan() {
    return int.parse(getValue(VALUE.CLAN).toString());
  }

  DotList getDots()
  {
    return getValue(VALUE.DOT) as DotList;
  }

  void addHP(int h) 
  {
    int hp = getHP();
    int hpMax = getHPMax();
    int newHP = hp + h;
    if (newHP > hpMax) newHP = hpMax;
    setValue(VALUE.HP, newHP);
  }

  @override
  String toString() {
    return "${getName()} [${getHP()}/ ${getHPMax()}]";
  }

  Map toMap()
  {
    Map map = Map();
    map["uuid"] = uuid;
    values.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }
}
