import 'dart:ui';

import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class ImagesUtils
{
  static late final Images images;

  static void init(Images images)
  {
    ImagesUtils.images = images;
  }

  static List<String> loaded = [];
  static Future<Image> loadImage(String fileName) async
  {
    try
    {
      if(!loaded.contains(fileName))
      {
        print("ImagesUtils : add $fileName");
        loaded.add(fileName);
        return await images.load(fileName);
      }
      print("ImagesUtils : get $fileName");
      return images.fromCache(fileName);
    }
    catch(e)
    {
      print("ImagesUtils.loadImage.Exception $e");
    }
    return await images.load(fileName);
  }

  static Map<String, Vector2> sizes = {
    "gui.png": Vector2.all(32),
    "hero_knight.png": Vector2(100, 55)
  };
  static Map<String, SpriteSheet> guis = {};
  static Future<SpriteSheet> loadGUI(String fileName) async
  {
    try
    {
      if(!guis.containsKey(fileName))
      {
        SpriteSheet spriteSheet = SpriteSheet(image: await loadImage(fileName), srcSize: sizes[fileName]!);
        guis[fileName] = spriteSheet;
      }
    }
    catch(e)
    {
      print("ImagesUtils.loadGUI.Exception $e");
    }
    SpriteSheet? result = guis[fileName];
    if(result == null)
    {
      print("ImagesUtils.loadGUI.Error no $fileName");
      throw Exception("No $fileName");
    }
    return result;
  }
}