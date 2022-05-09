import 'package:myapp/builder.dart';
import 'package:myapp/engine/dot.dart';
import 'package:myapp/engine/work.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/behaviour.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/works/work.dart';

class Entity extends UUIDHolder implements ValueReader//, Param
{
  late String uuid;

  Map<VALUE, dynamic> values = Map();

  int maxTimer = 45;
  late int timer = maxTimer;

  List<Behaviour> behaviours = [];
  late BuilderEntity builder;

  List<Work> _availablesWorks = [];

  int nbCombat = 0;

  Entity(Map map) 
  {
    setValues(map);
    builder = BuilderEntity(this);
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
    uuid = Utils.generateUUID();//Uuid().v4();
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
    /*if(value == VALUE.POISON)
      return DotList.withValue(VALUE.POISON, getDots());

    if(value == VALUE.BLEED)
      return DotList.withValue(VALUE.BLEED, getDots());*/
    
    return values[value!];
  }

  void setBehaviours(List<Behaviour> behaviours) 
  {
    this.behaviours = behaviours;
  }

  void run(Server server, Story story) 
  {
    Utils.logRun("Entity.run.start");
    /*List<DOT> dots = getDots().dots;
    Utils.logRun("Entity.run dots : $dots");
    for(DOT dot in dots)
    {
      dot.execute(this, this, story);
      if(!isAlive())
      {
        Utils.logRun("Entity.run.end DEAD");
        return;
      }
    }*/

    timer = maxTimer;
    Utils.logRun("Entity.run behaviours : $behaviours");
    for(Behaviour behaviour in behaviours)
    {
      if (behaviour.check(server)) 
      {
        Utils.logRun("Entity.run execute Behaviour " + behaviour.name);
        if(behaviour.execute(this, story))
        {
          Utils.logRun("Entity.run.end executed Behaviour " + behaviour.name);
          return;
        }
      }
    }

    Utils.logRun("Entity.run.end Nothing to execute");
    Work.aucun.execute(this, this, story);
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

  /*DotList getDots()
  {
    return getValue(VALUE.DOT) as DotList;
  }*/

  void addHP(int h) 
  {
    int hp = getHP();
    int hpMax = getHPMax();
    int newHP = hp + h;
    if (newHP > hpMax) newHP = hpMax;
    setValue(VALUE.HP, newHP);
  }

  void addAvailableWork(Work work)
  {
    if(!_availablesWorks.contains(work))
      _availablesWorks.add(work);
  }

  List<Work> availablesWorks()
  {
    return _availablesWorks;
  }

  @override
  String toString() {
    return "${getName()} [${getHP()}/ ${getHPMax()}]";
  }

  Entity.fromJson(Map<String, dynamic> map)
  {
    uuid = map["uuid"];
    final uuids = Map<String, dynamic>();
    uuids[uuid] = this;
    nbCombat = map["nbCombat"]??0;
    final Map k = map["values"];
    k.keys.forEach((key) {
      VALUE? value = ValueExtension.get(key);
      if(value != null)
      {
        values[value] = k[key];
      }
    });
    List w = map["works"];
    w.forEach((element) {_availablesWorks.add(Work.get(element));});
    setValue(VALUE.DOT, VALUE.DOT.defaultValue);
    setValue(VALUE.POISON, VALUE.POISON.defaultValue);
    setValue(VALUE.BLEED, VALUE.BLEED.defaultValue);
    builder = BuilderEntity.fromJson(this, map["builder"], uuids);
    Utils.logFromJson("Entity.fromJson.end");
  }

  addToMap(Map<String, dynamic> map)
  {
    map["values"] = Map();
    values.forEach((key, value) {
      map["values"][key.name] = value is int ? value : value.toString();
    });
    map["works"] = [];
    _availablesWorks.forEach((element) { 
      map["works"].add(element.name);
    });
    map["builder"] = builder.toMap();
    map["nbCombat"] = nbCombat;
  }

  @override
  String getUUID()
  {
    return uuid;
  }

  Map toStoryMap()
  {
    Map map = Map();
    map["uuid"] = uuid;
    values.forEach((key, value) {
      map[key] = value;
    });
    return map;
  }
}
