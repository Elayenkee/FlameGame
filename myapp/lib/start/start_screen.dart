import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';

class StartScreen  extends AbstractScreen
{
  late final TextComponent _txtConnexion;

  StartScreen(GameLayout gameRef, Vector2 size):super(gameRef, "S", size, priority: 1);

  @override
  Future<void> onLoad() async 
  {
    print("StartScreen.onLoad");
    await super.onLoad();

    gameRef.setBackgroundColor(Colors.black);

    TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
    _txtConnexion = TextComponent("Connexion...", textRenderer: textPaint);
    _txtConnexion.position = Vector2(5, 0);
    add(_txtConnexion);

    print("StartScreen.onLoaded");
  }

  void onLoading()
  {
    _txtConnexion.text = "Chargement des données...";
  }

  void onNewGame()
  {

  }

  @override
  bool onClick(Vector2 p) 
  {
    return true;
  }
}