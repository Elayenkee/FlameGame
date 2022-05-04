import 'dart:convert';

import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/world/world.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage 
{
  static late Storage storage;

  static late final uuid;
  static late World world;
  static late List<Entity> entities;
  static late Entity entity;
  static late Donjon? donjon;

  static Future<void> init() async
  {
    print("Storage.init.start");
    storage = Local();
    await storage.start();
    print("Storage.init.started");
    entities = await storage.getEntities();
    print("Storage.init.entities.ok");
    entity = entities[0];
    print("Storage.init.entity.ok");
    world = await storage.getWorld();
    print("Storage.init.world.ok");
    donjon = await storage.getDonjon();
    print("Storage.init.donjon.ok");
    print("Storage.init.end");
  }

  Future<void> start() async{}
  
  // Donjon
  Future<Donjon?> getDonjon();
  void setDonjon(Donjon donjon);
  static bool hasDonjon()
  {
    return donjon != null;
  }
  static void storeDonjon(Donjon donjon)
  {
    Storage.donjon = donjon;
    storage.setDonjon(donjon);
  }

  // World
  Future<World> getWorld();
  void setWorld(World world);
  static void storeWorld(World world)
  {
    Storage.world = world;
    storage.setWorld(world);
  }

  // Entities
  Future<List<Entity>> getEntities();
  void setEntities(List<Entity> entities);
  static void storeEntities()
  {
    storage.setEntities(entities);
  }

  static Entity _createEntity()
  {
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

    return entity;
  }
}

class Remote extends Storage
{
  @override
  Future<void> start() async
  {
    
  }

  @override
  Future<Donjon> getDonjon() async
  {
    Donjon donjon = Donjon.fromMap(null);
    Storage.storeDonjon(donjon);
    return donjon;
  }

  @override
  void setDonjon(Donjon donjon)
  {
    
  }

  @override
  Future<World> getWorld() async
  {
    print("Remote.getWorld.start");
    World world = World.fromMap(null);
    Storage.storeWorld(world);
    print("Remote.getWorld.end");
    return world;
  }

  @override
  void setWorld(World world)
  {
    
  }

  @override
  Future<List<Entity>> getEntities() async
  {
    Utils.log("Storage.getEntities null");
    Storage.entities = [Storage._createEntity()];
    Storage.storeEntities();
    return Storage.entities;
  }

  @override
  void setEntities(List<Entity> entities)
  {
    
  }
}

class Local extends Storage
{
  late final SharedPreferences prefs;

  @override
  Future<void> start() async
  {
    print("Local.start");
    prefs = await SharedPreferences.getInstance();
    await Future.delayed(Duration(milliseconds: 2000), () {});
    print("Local.end $prefs");
  }

  @override
  Future<Donjon?> getDonjon() async
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
    
    //TODO REMOVE
    Donjon.generate();
    return Storage.donjon;
    
    //return null;
  }

  @override
  void setDonjon(Donjon donjon)
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

  @override
  Future<World> getWorld() async
  {
    print("Local.getWorld.start");
    String? json = prefs.getString('world');
    print("Local.getWorld.start.json = $json");
    if(json != null)
    {
      Map<String, dynamic> map = jsonDecode(json);
      World world = World.fromMap(map);
      print("Local.getWorld.fromMap.end");
      return world;
    }
    World world = World.fromMap(null);
    print("Local.getWorld.fromNull.end");
    return world;
  }

  @override
  void setWorld(World world)
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

  @override
  Future<List<Entity>> getEntities() async
  {
    String? json = prefs.getString('entities');
    if(json != null)
    {
      List<Entity> entities = [];
      List liste = jsonDecode(json);
      liste.forEach((element) { 
        try
        {
          Entity entity = Entity.fromJson(element);
          entities.add(entity);
        }
        catch(e)
        {
          print(e);
          Utils.log("Storage.getEntity.end.ko");
        }
      });
      return entities;
    }

    Utils.log("Storage.getEntities null");
    Storage.entities = [Storage._createEntity()];
    Storage.storeEntities();
    return Storage.entities;
  }

  @override
  void setEntities(List<Entity> entities)
  {
    List liste = [];
    entities.forEach((element) {liste.add(element.toMap());});
    final json = jsonEncode(liste);
    prefs.setString('entities', json);
  }
}
