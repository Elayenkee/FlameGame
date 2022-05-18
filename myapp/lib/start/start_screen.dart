import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/google/google_signin.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
import 'package:myapp/options/options_screen.dart';
import 'package:myapp/storage/storage.dart';
import 'package:flame/assets.dart';
import 'package:myapp/utils/images.dart';

class StartScreen  extends AbstractScreen
{
  late final LanguageChooser? languageChooser;
  late final TextComponent _txtConnexion;

  int step = 0;

  StartScreen(GameLayout gameRef, Vector2 size):super(gameRef, "S", size, priority: 1);

  @override
  Future<void> onLoad() async 
  {
    print("StartScreen.onLoad.start");
    await super.onLoad();
    gameRef.setBackgroundColor(Colors.black);
    
    languageChooser = LanguageChooser(gameRef, addStartScreen);
    await add(languageChooser!);
    print("StartScreen.onLoad.end");
  }

  void addStartScreen() async
  {
    languageChooser?.remove();
    
    SpriteComponent start = SpriteComponent();
    start.sprite = Sprite(await Images().load("startscreen.png"));
    start.size = gameRef.size;
    await addWithGameRef(start);
    
    TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
    _txtConnexion = TextComponent("", textRenderer: textPaint);
    _txtConnexion.position = Vector2(gameRef.size.x / 2, gameRef.size.y - 50);
    _txtConnexion.anchor = Anchor.center;
    await addWithGameRef(_txtConnexion);
    
    step = 1;
  }

  void start() async
  {
    _txtConnexion.text = "${Language.connexion}...";
    logDebug("Connexion..");
    await Future.delayed(const Duration(seconds: 1));
    String? uuid = await signInWithGoogle();
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
    if(step == 0)
    {
      languageChooser?.onClick(p);
      return true;
    }

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
      if(step > 0)
        step = -1; 
    }
  }
}

class LanguageChooser extends HorizontalContainer
{
  late final PositionComponent francais;
  late final PositionComponent anglais;
  final VoidCallback onEnd;

  LanguageChooser(GameLayout gameRef, this.onEnd):super(gameRef, divider: 35)
  {
    anchor = Anchor.center;
    position = gameRef.size / 2;
    
    francais = SpriteComponent();
    francais.size = Vector2.all(100);
    add(francais);

    anglais = SpriteComponent();
    anglais.size = Vector2.all(100);
    add(anglais);
  }

  @override
  Future<void> onLoad() async 
  {
    print("LanguageChooser.onLoad.start");
    await super.onLoad();
    (francais as SpriteComponent).sprite = Sprite(await ImagesUtils.loadImage("flag_fr.png"));
    (anglais as SpriteComponent).sprite = Sprite(await ImagesUtils.loadImage("flag_en.png"));
    print("LanguageChooser.onLoad.end");
  }

  bool onClick(Vector2 p)
  {
    if(francais.containsPoint(p))
    {
      Language.locale = "fr";
      onEnd();
      return true;
    }
    if(anglais.containsPoint(p))
    {
      Language.locale = "en";
      onEnd();
      return true;
    }
    return true;
  }
}