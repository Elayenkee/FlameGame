import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/google/google_signin.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:flame/assets.dart';

class StartScreen  extends AbstractScreen
{
  late final TextComponent _txtConnexion;

  int step = 1;

  StartScreen(GameLayout gameRef, Vector2 size):super(gameRef, "S", size, priority: 1);

  @override
  Future<void> onLoad() async 
  {
    //print("StartScreen.onLoad");
    await super.onLoad();

    gameRef.setBackgroundColor(Colors.black);

    SpriteComponent start = SpriteComponent();
    start.sprite = Sprite(await Images().load("startscreen.png"));
    start.size = gameRef.size;
    add(start);

    TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
    _txtConnexion = TextComponent("", textRenderer: textPaint);
    _txtConnexion.position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
    _txtConnexion.anchor = Anchor.center;
    await add(_txtConnexion);

    //print("StartScreen.onLoaded");
  }

  void start() async
  {
    _txtConnexion.text = "${Language.connexion}...";
    logDebug("Connexion..");
    await Future.delayed(const Duration(seconds: 1));
    String? uuid = await signInWithGoogle();
    //print("StartScreen.signedIn.uuid $uuid");
    if(uuid != null)
    {
      step = 2;
      logDebug("Storage.init..");
      await Storage.init(uuid);
      logDebug("OK");
      await Future.delayed(const Duration(seconds: 1));
    }  
    step = 3;
  }

  @override
  bool onClick(Vector2 p) 
  {
    if(Storage.uuid != null)
      gameRef.startDonjon();
    else
      start();
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
        _txtConnexion.text = "${Language.chargementDonnees}...";
      if(step == 3)
      {
        if(Storage.isNewGame())
          _txtConnexion.text = Language.nouvellePartie.str;
        else
          _txtConnexion.text = Language.continuer.str;
      }
      step = -1; 
    }
  }
}