import 'dart:ui';

import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';

class ImagesUtils
{
  static late final Images _images;

  static Future<void> init(Images images, VoidCallback onEnd) async
  {
    print("ImagesUtils.init");
    ImagesUtils._images = images;
    await loadGUI("gui.png");
    await loadGUI("hero_knight.png");
    await loadGUI("smoke_2.png");
    await loadGUI("bat_idle.png");
    await loadGUI("bat_attack.png");
    await loadGUI("bat_hit.png");
    await loadGUI("bat_death.png");
    final List<String> liste = ["flag_fr.png", "flag_en.png", "button_settings.png", "salle.png", "arrow.png", "porte_sud.png", "porte_nord.png", 
    "porte_ouest.png", "bar.png", "health.png", "mana.png", "button_close.png", "cadre_1_left.png", "cadre_1_middle.png", 
    "torch_activated.png", "torch_desactivated.png", "icon_edit.png", "cadre_behaviour.png", "button_ennemy.png", "button_me.png", "button_none.png", 
    "button_work.png", "button_magic.png", "portrait.png", "cadre_player.png", "button_plus.png", "button_build.png", 
    "icon_build.png", "button_large.png", "popup_build.png", "icon_builder_container.png", 
    "icon_health_percent.png","icon_builder_greater.png"];
    liste.forEach((element) async{
      await images.load(element);
      print("Loaded $element");
    });
    onEnd();
  }

  static Image getImage(String fileName)
  {
    return _images.fromCache(fileName);
  }

  static Map<String, Vector2> _sizes = {
    "gui.png": Vector2.all(32),
    "hero_knight.png": Vector2(100, 55),
    "smoke_2.png": Vector2(64, 64),
    "bat_idle.png": Vector2(150, 75),
    "bat_attack.png": Vector2(150, 75),
    "bat_death.png": Vector2(150, 75),
    "bat_hit.png": Vector2(150, 75)
  };
  static Map<String, SpriteSheet> _guis = {};
  static Future<void> loadGUI(String fileName) async
  {
    if(_guis.containsKey(fileName))
      return;
    print("ImagesUtils._loadGUI $fileName");
    await _images.load(fileName);
    SpriteSheet spriteSheet = SpriteSheet(image: getImage(fileName), srcSize: _sizes[fileName]!);
    _guis[fileName] = spriteSheet;
  }

  static SpriteSheet getGUI(String fileName)
  {
    print("ImagesUtils.getGUI $fileName");
    return _guis[fileName]!;
  }
}