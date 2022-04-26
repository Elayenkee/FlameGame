import 'dart:convert';

import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Storage 
{
  static late final prefs;

  static Future<void> init() async
  {
    prefs = await SharedPreferences.getInstance();
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
    values[VALUE.HP_MAX] = 46;
    values[VALUE.ATK] = 23;
    values[VALUE.NAME] = "Warrior";
    values[VALUE.CLAN] = 1;
    Entity entity = Entity(values);
    return entity;
  }
}
