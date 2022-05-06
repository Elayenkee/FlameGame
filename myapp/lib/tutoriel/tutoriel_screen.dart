import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/graphics/my_text_box_component.dart';
import 'package:myapp/main.dart';
import 'package:myapp/options/options_screen.dart';

abstract class TutorielScreen extends AbstractScreen
{
  late final Popup cadre;

  MyTextBoxComponent? txtPhrase = null;
  String phrase = "";

  VoidCallback? onEnd;

  TutorielScreen(GameLayout gameRef, Vector2 size, this.onEnd):super(gameRef, "T", size, priority: 6500);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    cadre = Popup(Vector2(gameRef.size.x, 150));
    cadre.position = Vector2(0, gameRef.size.y - cadre.size.y);
    await addChild(cadre);
  }

  void startPhrase(String phrase)
  {
    this.phrase = phrase;

    txtPhrase?.remove();
    txtPhrase = null;

    txtPhrase = MyTextBoxComponent(phrase, textRenderer: textPaint, priority: 2500, boxConfig: TextBoxConfig(maxWidth: cadre.size.x - 200, timePerChar: .001));
    txtPhrase!.position = Vector2(150, 25);
    txtPhrase!.size = Vector2(1000, 1000);
    cadre.addChild(txtPhrase!, gameRef: gameRef);
  }

  @override
  bool onClick(Vector2 p) 
  {
    return false;
  }

  void next({Map? map})
  {

  }
}

class TutorielSettings extends TutorielScreen
{
  final SpriteComponent buttonSettings;

  int step = 1;

  TutorielSettings(GameLayout gameRef, this.buttonSettings, VoidCallback onEnd):super(gameRef, gameRef.size, onEnd);

  @override
  Future<void> onLoad() async 
  {
    print("TutorielSettings.onLoad.start");
    await super.onLoad();

    startPhrase("Attention !\nDes monstres m'attaquent ! Je ferais mieux de réviser ma stratégie de combat.");
    txtPhrase?.onEnd = () => buttonSettings.position = Vector2(gameRef.size.x - 100, 5);
    print("TutorielSettings.onLoad.end");
  }

  @override
  void next({Map? map})
  {
    if(step == 1)
    {
      startPhrase("Pour l'instant, ma stratégie est plutôt simple :\nJ'ATTAQUE LE MONSTRE !");
      step = 2;
    }
    else if(step == 2)
    {
      startPhrase("En détail : \nMon action c'est d'attaquer;\nEt ma cible, c'est l'ennemi.");
      txtPhrase?.onEnd = () => step = 4;
      step = 3;
    }
  }

  @override
  bool onClick(Vector2 p)
  {
    print("TutorielSettings.onClick $step");
    if(step == 4)
    {
      gameRef.stopTutoriel();
      Future.delayed(Duration(milliseconds: 200), gameRef.closeOptions);
      Future.delayed(Duration(milliseconds: 500), onEnd);
      return true;
    }
    return false;
  }
}