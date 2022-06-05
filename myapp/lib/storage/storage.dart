import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
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
  static late Donjon donjon;
  static bool newGame = true;

  static Future<void> init(String uuid) async
  {
    logDebug("Storage.init.start $uuid");
    Storage.uuid = uuid;
    storage = Local();
    logDebug("Starting..");
    await storage.start();
    logDebug("OK");

    //Entities
    logDebug("Get entities..");
    var pEntities = storage.getEntities();
    if(pEntities == null)
      entities = [Storage._createEntity()];
    else 
      entities = pEntities;
    entity = entities[0];
    logDebug("OK");

    //World
    /*var pWorld = storage.getWorld();
    if(pWorld == null)
      world = World.fromMap(null);
    else 
      world = pWorld;*/

    //Donjon
    logDebug("Get donjon..");
    var pDonjon = storage.getDonjon();
    if(pDonjon == null)
      donjon = Donjon.generate();
    else
      donjon = pDonjon;
    logDebug("OK");

    //if(pWorld == null)
    //  storeWorld(world);

    if(pEntities == null)
      storeEntities();

    if(pDonjon == null)
      storeDonjon(donjon);
    else
      newGame = false;
    
    logDebug("Storage.init.end");
  }

  Future<void> start() async{}

  static bool isNewGame()
  {
    return newGame;
  }
  
  // Donjon
  Donjon? getDonjon();
  void setDonjon(Donjon donjon);
  static void storeDonjon(Donjon donjon)
  {
    Storage.donjon = donjon;
    storage.setDonjon(donjon);
  }

  // World
  /*World? getWorld();
  void setWorld(World world);
  static void storeWorld(World world)
  {
    Storage.world = world;
    storage.setWorld(world);
  }*/

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
    values[VALUE.NAME] = "Sydell";
    values[VALUE.HP_MAX] = 46;
    values[VALUE.ATK] = 15;
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
    BuilderBehaviour builderBehaviour2 = builder.addBehaviour(name: Language.attaquer_monstre.str);
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
    entity.addAvailableBuilderCondition(isEnnemy(builderEntity));
    entity.addAvailableBuilderCondition(isMe(builderEntity));

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
    //print("Remote.start");
    try
    {
      userCollection = FirebaseFirestore.instance.collection("users");
      //print("Remote.start.1");
      DocumentSnapshot<Map<String, dynamic>> snapshot = await userCollection!.doc(Storage.uuid).get();
      //print("Remote.start.2");
      all = snapshot.data();
      //print("Remote.start.3");
    }
    catch(e)
    {
      print(e);
    }
    //print("Remote.start.end");
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

  /*@override
  World? getWorld()
  {
    //print("Remote.getWorld.start");
    if(all != null && all!.containsKey("world"))
    {
      World world = World.fromMap(all!["world"]);
      return world;
    }
    //print("Remote.getWorld.null.end");
    return null;
  }

  @override
  void setWorld(World world)
  {
    saveUser();
  }*/

  @override
  List<Entity>? getEntities()
  {
    //print("Remote.getEntities");
    if(all != null && all!.containsKey("entities"))
    {
      List<Entity> entities = [];
      List liste = all!["entities"];
      liste.forEach((element) {
        entities.add(Entity.fromJson(element));
      });
      //print("Remote.getEntities.end");
      return entities;
    }
    //print("Remote.getEntities.null.end");
    return null;
  }

  @override
  void setEntities(List<Entity> entities)
  {
    saveUser();
  }

  void saveUser() async 
  {
    //print("Remote.saveUser.start");
    Map<String, dynamic> all = {};

    // World
    all["world"] = Storage.world.toMap();
    //print("Remote.saveUser.world.ok");

    //Donjon
    all["donjon"] = Storage.donjon.toMap();
    //print("Remote.saveUser.donjon.ok");

    // Entities
    List liste = [];
    Storage.entities.forEach((element) {liste.add(element.toMap());});
    all["entities"] = liste;
    //print("Remote.saveUser.entities.ok");

    try
    {
      userCollection?.doc(Storage.uuid).set(all);
    }
    catch(e)
    {
      print(e);
    }
    //print("Remote.saveUser.end");
  }
}

class Local extends Storage
{
  late final SharedPreferences prefs;

  @override
  Future<void> start() async
  {
    //print("Local.start");
    prefs = await SharedPreferences.getInstance();
    //print("Local.start.end");
  }

  @override
  Donjon? getDonjon()
  {
    String? json = prefs.getString('donjon');
    /*if(json != null)
    {
      Map<String, dynamic> map = jsonDecode(json);
      try
      {
        return Donjon.fromMap(map);
      }
      catch(e)
      {
        print(e);
        logDebug(e.toString());
      }
    }*/  
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

  /*@override
  World? getWorld()
  {
    //print("Local.getWorld.start");
    String? json = prefs.getString('world');
    //print("Local.getWorld.start.json = $json");
    if(json != null)
    {
      Map<String, dynamic> map = jsonDecode(json);
      World world = World.fromMap(map);
      //print("Local.getWorld.fromMap.end");
      return world;
    }
    //print("Local.getWorld.fromNull.end");
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
  }*/

  @override
  List<Entity>? getEntities()
  {
    String? json = prefs.getString('entities');
    /*if(json != null)
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
          logDebug(e.toString());
        }
      });
      return entities;
    }*/
    return null;
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
