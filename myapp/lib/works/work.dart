import 'dart:math';

import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/utils.dart';

abstract class Work
{
  static Work aucun = Aucun();
  static Work attaquer = Attaquer();
  static Work bandage = Bandage();
  static Work soin = Soin();
  
  static List<Work> get values => [aucun, attaquer, soin];

  static Work get(String name)
  {
    for(Work w in values)
    {
      if(w.name == name)
        return w;
    }
    return aucun;
  }

  String get name;

  bool execute(Entity caller, Entity target, Story story) 
  {
    return false;
  }

  @override
  String toString()
  {
    return name;
  }
}

abstract class MagicWork extends Work
{
  int get mp;
}

class Attaquer extends Work
{
  String get name => "Attaquer";

  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    StoryEvent event = StoryEvent();

    int atk = caller.getATK();
    int def = target.getDEF();

    double rand = Random().nextDouble();
    rand = 1 + (rand * 0.125);

    atk = (rand * atk).toInt();
    int dmg = atk - def;
    target.addHP(-dmg);

    event.set("work", "ATTACK");
    event.set("source", "sword");
    event.setCaller(caller);
    event.setTarget(target);
    event.set("damage", -dmg);
    event.log = "$caller used ATTACK [$dmg] on $target";

    story.addStoryEvent(event);

    return true;
  }
}

class Bandage extends Work
{
  String get name => "Bandage";

  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    StoryEvent event = StoryEvent();

    int hpMax = caller.getHPMax();
    int hpToGain = (hpMax * 15) ~/ 100;
    target.addHP(hpToGain);
    event.set("work", name);
    event.setCaller(caller);
    event.setTarget(caller);
    event.set("damage", hpToGain);
    event.log = "$caller used $name [$hpToGain] on $caller";

    story.addStoryEvent(event);

    return true;
  }
}

class Soin extends MagicWork
{
  String get name => "Soin ${mp}mp";
  int get mp => 5;

  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    if (caller.getMP() < mp) 
    {
      Utils.log("$caller pas assez de MP pour use $name");
      return false;
    }

    StoryEvent event = StoryEvent();
    int pow = caller.getPow();
    int mr = target.getMR();

    double rand = Random().nextDouble();
    rand = 1 + (rand * 0.125);

    pow = (rand * pow.toDouble()).toInt();
    int dmg = pow - mr;

    int dmg2 = 2 + ((mr * mr)) ~/ 256;
    dmg2 *= dmg;
    target.addHP(dmg2);

    event.set("work", name);
    event.setCaller(caller);
    event.setTarget(target);
    event.set("damage", dmg2);
    event.log = "$caller used HEAL on $target";

    story.addStoryEvent(event);
    return true;
  }
}

/*class DOT extends Work
{
  VALUE source;
  Function toExecute;

  int count = 0;
  
  DOT(this.source, this.toExecute);

  bool execute(Entity caller, Entity target, Story story) 
  {
    toExecute.call(story, this);
    count++;
    return true;
  }
}*/

class Aucun extends Work
{
  String get name => "Aucun";

  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    StoryEvent event = StoryEvent();
    event.set("work", name);
    event.set("caller", caller.toMap());
    event.log = "$caller ne fait rien";
    return true;
  }
}