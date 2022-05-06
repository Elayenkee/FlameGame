import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/google/google_signin.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flame/sprite.dart';

class StartScreen  extends AbstractScreen
{
  late final TextComponent _txtConnexion;

  int step = 1;

  StartScreen(GameLayout gameRef, Vector2 size):super(gameRef, "S", size, priority: 1);

  @override
  Future<void> onLoad() async 
  {
    print("StartScreen.onLoad");
    await super.onLoad();

    gameRef.setBackgroundColor(Colors.black);

    SpriteComponent start = SpriteComponent();
    start.sprite = Sprite(await Images().load("startscreen.png"));
    start.size = gameRef.size;
    add(start);

    TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
    _txtConnexion = TextComponent("Connexion...", textRenderer: textPaint);
    _txtConnexion.position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
    _txtConnexion.anchor = Anchor.center;
    await add(_txtConnexion);

    print("StartScreen.onLoaded");
  }

  void start() async
  {
    await Future.delayed(const Duration(seconds: 1));
    String? uuid = await signInWithGoogle();
    print("StartScreen.signedIn.uuid $uuid");
    if(uuid != null)
    {
      step = 2;
      await Storage.init(uuid);
      print("StartScreen.storage.init.ok");
      await Future.delayed(const Duration(seconds: 1));
      if(Storage.hasDonjon())
      {
        gameRef.startDonjon();
      }
      else
      {
        step = 3;
      }
    }  
    else
      step = 3;
  }

  @override
  bool onClick(Vector2 p) 
  {
    if(_txtConnexion.text == "NEW GAME")
    {
      if(Storage.uuid == null)
      {
        _txtConnexion.text = "Connexion...";
        start();
      }
      else
      {
        Storage.storeDonjon(Donjon.generate());
        gameRef.startDonjon();
      }
    }
    return true;
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    if(isMounted)
    {
      if(step == 1)
        start();
      if(step == 2)
        _txtConnexion.text = "Chargement des données...";
      if(step == 3)
        _txtConnexion.text = "NEW GAME";
      step = -1; 
    }
  }
}