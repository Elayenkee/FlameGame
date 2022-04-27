import 'package:myapp/engine/dot.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/engine/entity.dart';
import 'dart:math';

class Work 
{
  bool execute(Entity caller, Entity target, Story story) 
  {
    return false;
  }
}

class HEAL extends Work 
{
  final int mp = 5;

  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    if (caller.getMP() < mp) 
    {
      Utils.log("$caller pas assez de MP pour use HEAL");
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

    event.set("work", "HEAL");
    event.set("source", "heal");
    event.setCaller(caller);
    event.setTarget(target);
    event.set("damage", dmg2);
    event.log = "$caller used HEAL on $target";

    story.addStoryEvent(event);
    return true;
  }
}

class ATTACK extends Work 
{
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

class POISON extends Work
{
  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    DOT dot = DOT(VALUE.POISON, (Story s, DOT dot){
      target.addHP(-2);
      StoryEvent e = StoryEvent();
      e.set("type", "DOT");
      e.set("source", "dot_poison");
      e.setTarget(target);
      e.set("damage", -2);
      e.log = "$target subit le poison";
      s.addStoryEvent(e);
    });
    target.getDots().add(dot);

    StoryEvent event = StoryEvent();
    event.set("work", "POISON");
    event.set("source", "work_poison");
    event.setCaller(caller);
    event.setTarget(target);
    event.log = "$caller used POISON on $target";
    story.addStoryEvent(event);
    return true;
  }
}

class BLEED extends Work
{
  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    DOT dot = DOT(VALUE.BLEED, (Story s, DOT dot){
      target.addHP(-2);
      StoryEvent e = StoryEvent();
      e.set("type", "DOT");
      e.set("source", "dot_bleed");
      e.setTarget(target);
      e.set("damage", -2);
      e.log = "$target subit le saignement";
      s.addStoryEvent(e);
    });
    target.getDots().add(dot);

    StoryEvent event = StoryEvent();
    event.set("work", "BLEED");
    event.set("source", "work_bleed");
    event.setCaller(caller);
    event.setTarget(target);
    event.log = "$caller used BLEED on $target";
    story.addStoryEvent(event);
    return true;
  }
}

class NOTHING extends Work
{
  @override
  bool execute(Entity caller, Entity target, Story story) 
  {
    StoryEvent event = StoryEvent();
    event.set("work", "NOTHING");
    event.set("caller", caller.toMap());
    event.log = "$caller ne fait rien";
    return true;
  }
}
