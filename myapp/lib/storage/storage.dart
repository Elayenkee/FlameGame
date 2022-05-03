import 'dart:convert';

import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/world/world.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage 
{
  static late final prefs;

  static Future<void> init() async
  {
    prefs = await SharedPreferences.getInstance();
  }

  static bool hasDonjon()
  {
    String? json = prefs.getString('donjon');
    return json != null;
  }

  static void storeDonjon(Donjon donjon)
  {
    final map = donjon.toMap();
    try
    {
      final json = jsonEncode(map);
      prefs.setString('donjon', json);
    }
    catch(e)
    {
      print(e);
    }
  }

  static Donjon getDonjon()
  {
    String? json = prefs.getString('donjon');
    if(json != null)
    {
      Map<String, dynamic> map = jsonDecode(json);
      try
      {
        return Donjon.fromMap(map);
      }
      catch(e)
      {
        print(e);
      }
    }
    return Donjon.fromMap(null);
  }

  static void storeWorld(World world)
  {
    final map = world.toMap();
    try
    {
      final json = jsonEncode(map);
      prefs.setString('world', json);
    }
    catch(e)
    {
      print(e);
    }
  }

  static World getWorld()
  {
    String? json = prefs.getString('world');
    if(json != null)
    {
      Map<String, dynamic> map = jsonDecode(json);
      return World.fromMap(map);
    }
    return World.fromMap(null);
  }

  static void storeEntity(Entity entity)
  {
    //Utils.log("Storage.storeEntity");
    final map = entity.toMap();
    //Utils.log("Storage.storeEntity.mapOk");
    try
    {
      final json = jsonEncode(map);
      //Utils.log("Storage.storeEntity.jsonOk");
      prefs.setString('entity', json);
    }
    catch(e)
    {
      print(e);
    }
    //Utils.log("Storage.storeEntity.end");
  }

  static Entity getEntity()
  {
    String? json = prefs.getString('entity');
    if(json != null)
    {
      //Utils.log("Storage.getEntity : value detected : $json");
      Map<String, dynamic> map = jsonDecode(json);
      try
      {
        Entity entity = Entity.fromJson(map);
        return entity;
      }
      catch(e)
      {
        print(e);
        Utils.log("Storage.getEntity.end.ko");
      }
    }
    
    Utils.log("Storage.getEntity : null");
    
    Map values = Map();
    values[VALUE.NAME] = "Entity 1";
    values[VALUE.HP_MAX] = 46;
    values[VALUE.ATK] = 23;
    values[VALUE.CLAN] = 1;

    Entity entity = Entity(values);
    BuilderEntity builderEntity = entity.builder;
    BuilderTotal builder = builderEntity.builderTotal;

    // Poison if no poison
    BuilderBehaviour builderBehaviour = builder.addBehaviour(name: "Poison if no poison");
    builderBehaviour.activated = true;
    builderBehaviour.builderWork.work = Works.POISON;
    BuilderConditionGroup builderConditionGroup = builderBehaviour.builderTargetSelector.builderConditionGroup;
    BuilderTriFunction builderTriFunction = builderBehaviour.builderTargetSelector.builderTriFunction;
    builderTriFunction.tri = TriFunctions.LOWEST;
    builderTriFunction.value = VALUE.HP;
    BuilderCondition builderCondition = builderConditionGroup.addCondition();
    builderCondition.setCondition(Conditions.NOT_EQUALS);
    builderCondition.setParam(1, builderEntity);
    builderCondition.setParam(2, VALUE.CLAN);
    BuilderCondition builderCondition2 = builderConditionGroup.addCondition();
    builderCondition2.setCondition(Conditions.EQUALS);
    builderCondition2.setParam(1, ValueAtom(0));
    BuilderCount builderCount = BuilderCount();
    builderCount.setValue(VALUE.POISON);
    builderCondition2.setParam(2, builderCount);

    // Bleed if no bleed
    BuilderBehaviour builderBehaviourBleed = builder.addBehaviour(name: "Bleed if no bleed");
    builderBehaviourBleed.activated = true;
    builderBehaviourBleed.builderWork.work = Works.BLEED;
    BuilderConditionGroup builderConditionGroupBleed = builderBehaviourBleed.builderTargetSelector.builderConditionGroup;
    BuilderTriFunction builderTriFunctionBleed = builderBehaviourBleed.builderTargetSelector.builderTriFunction;
    builderTriFunctionBleed.tri = TriFunctions.LOWEST;
    builderTriFunctionBleed.value = VALUE.HP;
    BuilderCondition builderConditionBleed = builderConditionGroupBleed.addCondition();
    builderConditionBleed.setCondition(Conditions.NOT_EQUALS);
    builderConditionBleed.setParam(1, builderEntity);
    builderConditionBleed.setParam(2, VALUE.CLAN);
    BuilderCondition builderCondition2Bleed = builderConditionGroupBleed.addCondition();
    builderCondition2Bleed.setCondition(Conditions.EQUALS);
    builderCondition2Bleed.setParam(1, ValueAtom(0));
    BuilderCount builderCountBleed = BuilderCount();
    builderCountBleed.setValue(VALUE.BLEED);
    builderCondition2Bleed.setParam(2, builderCountBleed);

    // Attack lowest HP
    BuilderBehaviour builderBehaviour2 = builder.addBehaviour(name: "Attack lowest HP");
    builderBehaviour2.activated = true;
    builderBehaviour2.builderWork.work = Works.ATTACK;
    BuilderConditionGroup builderConditionGroup2 = builderBehaviour2.builderTargetSelector.builderConditionGroup;
    BuilderTriFunction builderTriFunction2 = builderBehaviour2.builderTargetSelector.builderTriFunction;
    builderTriFunction2.tri = TriFunctions.LOWEST;
    builderTriFunction2.value = VALUE.HP;
    BuilderCondition builderCondition3 = builderConditionGroup2.addCondition();
    builderCondition3.setCondition(Conditions.NOT_EQUALS);
    builderCondition3.setParam(1, builderEntity);
    builderCondition3.setParam(2, VALUE.CLAN);

    builder.addBehaviour(name: "");
    builder.addBehaviour(name: "");

    storeEntity(entity);

    return entity;
  }
}
