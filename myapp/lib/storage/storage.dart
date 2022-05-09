import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/works/work.dart';
import 'package:myapp/world/world.dart';
import 'package:shared_preferences/shared_preferences.dart';

abstract class Storage 
{
  static late Storage storage;

  static late String? uuid = null;
  static late World world;
  static late List<Entity> entities;
  static late Entity entity;
  static Donjon? donjon = null;

  static Future<void> init(String uuid) async
  {
    print("Storage.init.start $uuid");
    Storage.uuid = uuid;
    storage = Local();
    print("Storage.init.start.init");
    await storage.start();
    print("Storage.init.start.init.ok");

    //Entities
    var pEntities = storage.getEntities();
    if(pEntities == null)
      entities = [Storage._createEntity()];
    else 
      entities = pEntities;
    entity = entities[0];

    //World
    var pWorld = storage.getWorld();
    if(pWorld == null)
      world = World.fromMap(null);
    else 
      world = pWorld;

    //Donjon
    donjon = storage.getDonjon();

    if(pWorld == null)
      storeWorld(world);

    if(pEntities == null)
      storeEntities();
    
    print("Storage.init.end");
  }

  Future<void> start() async{}
  
  // Donjon
  Donjon? getDonjon();
  void setDonjon(Donjon donjon);
  static bool hasDonjon()
  {
    print("Storage.hasDonjon");
    return donjon != null;
  }
  static void storeDonjon(Donjon donjon)
  {
    Storage.donjon = donjon;
    storage.setDonjon(donjon);
  }

  // World
  World? getWorld();
  void setWorld(World world);
  static void storeWorld(World world)
  {
    Storage.world = world;
    storage.setWorld(world);
  }

  // Entities
  List<Entity>? getEntities();
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
    /*BuilderBehaviour builderBehaviour = builder.addBehaviour(name: "Poison if no poison");
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
    builderCondition2Bleed.setParam(2, builderCountBleed);*/

    // Attack lowest HP
    /*BuilderBehaviour builderBehaviour2 = builder.addBehaviour(name: "Attaquer monstre");
    builderBehaviour2.activated = true;
    builderBehaviour2.builderWork.work = Works.ATTACK;
    BuilderConditionGroup builderConditionGroup2 = builderBehaviour2.builderTargetSelector.builderConditionGroup;
    BuilderTriFunction builderTriFunction2 = builderBehaviour2.builderTargetSelector.builderTriFunction;
    builderTriFunction2.tri = TriFunctions.LOWEST;
    builderTriFunction2.value = VALUE.HP;
    BuilderCondition builderCondition3 = builderConditionGroup2.addCondition();
    builderCondition3.setCondition(Conditions.NOT_EQUALS);
    builderCondition3.setParam(1, builderEntity);
    builderCondition3.setParam(2, VALUE.CLAN);*/

    // Attack lowest HP
    BuilderBehaviour builderBehaviour2 = builder.addBehaviour(name: "Attaquer monstre");
    builderBehaviour2.activated = true;
    builderBehaviour2.builderWork.work = Work.attaquer;
    BuilderConditionGroup builderConditionGroup2 = builderBehaviour2.builderTargetSelector.builderConditionGroup;
    //BuilderTriFunction builderTriFunction2 = builderBehaviour2.builderTargetSelector.builderTriFunction;
    //builderTriFunction2.tri = TriFunctions.LOWEST;
    //builderTriFunction2.value = VALUE.HP;
    BuilderCondition builderCondition = isEnnemy(builderEntity);
    builderConditionGroup2.addCondition(b: builderCondition);
    builderCondition.onAddedToTargetSelector(builderBehaviour2.builderTargetSelector);

    entity.addAvailableWork(Work.attaquer);
    entity.addAvailableWork(Work.bandage);
    entity.addAvailableWork(Work.aucun);

    //builder.addBehaviour(name: "");
    //builder.addBehaviour(name: "");

    return entity;
  }
}

class Remote extends Storage
{
  late CollectionReference<Map<String, dynamic>>? userCollection = null;
  late Map<String, dynamic>? all = null; 

  @override
  Future<void> start() async
  {
    print("Remote.start");
    try
    {
      userCollection = FirebaseFirestore.instance.collection("users");
      print("Remote.start.1");
      DocumentSnapshot<Map<String, dynamic>> snapshot = await userCollection!.doc(Storage.uuid).get();
      print("Remote.start.2");
      all = snapshot.data();
      print("Remote.start.3");
    }
    catch(e)
    {
      print(e);
    }
    print("Remote.start.end");
  }

  @override
  Donjon? getDonjon()
  {
    if(all != null && all!.containsKey("donjon"))
    {
      Donjon donjon = Donjon.fromMap(all!["donjon"]);
      return donjon;
    }
    return null;
  }

  @override
  void setDonjon(Donjon donjon)
  {
    saveUser();
  }

  @override
  World? getWorld()
  {
    print("Remote.getWorld.start");
    if(all != null && all!.containsKey("world"))
    {
      World world = World.fromMap(all!["world"]);
      return world;
    }
    print("Remote.getWorld.null.end");
    return null;
  }

  @override
  void setWorld(World world)
  {
    saveUser();
  }

  @override
  List<Entity>? getEntities()
  {
    print("Remote.getEntities");
    if(all != null && all!.containsKey("entities"))
    {
      List<Entity> entities = [];
      List liste = all!["entities"];
      liste.forEach((element) {
        entities.add(Entity.fromJson(element));
      });
      print("Remote.getEntities.end");
      return entities;
    }
    print("Remote.getEntities.null.end");
    return null;
  }

  @override
  void setEntities(List<Entity> entities)
  {
    saveUser();
  }

  void saveUser() async 
  {
    print("Remote.saveUser.start");
    Map<String, dynamic> all = {};

    // World
    all["world"] = Storage.world.toMap();
    print("Remote.saveUser.world.ok");

    //Donjon
    if(Storage.donjon != null)
      all["donjon"] = Storage.donjon!.toMap();
    print("Remote.saveUser.donjon.ok");

    // Entities
    List liste = [];
    Storage.entities.forEach((element) {liste.add(element.toMap());});
    all["entities"] = liste;
    print("Remote.saveUser.entities.ok");

    try
    {
      userCollection?.doc(Storage.uuid).set(all);
    }
    catch(e)
    {
      print(e);
    }
    print("Remote.saveUser.end");
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
    print("Local.start.end");
  }

  @override
  Donjon? getDonjon()
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
    return null;
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
  World? getWorld()
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
    print("Local.getWorld.fromNull.end");
    return null;
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
  List<Entity>? getEntities()
  {
    String? json = prefs.getString('entities');
    print(json);
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
    return null;
  }

  @override
  void setEntities(List<Entity> entities)
  {
    List liste = [];
    entities.forEach((element) {liste.add(element.toMap());});
    final json = jsonEncode(liste);
    prefs.setString('entities', json);
    print(json);
  }
}
