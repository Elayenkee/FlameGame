import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class OptionsScreen  extends AbstractScreen
{
  late final Popup popup;
  late final VoidCallback? onClickClose;

  OptionsScreen(Vector2 size, {VoidCallback? this.onClickClose}):super("D", size);

  @override
  Future<void> onLoad() async 
  {
    print("OptionsScreen.onLoad");
    await super.onLoad();

    final b = Background(gameRef.size);
    b.setColor(Color.fromARGB(129, 0, 0, 0));
    add(b);

    await Popup.init();

    print("add popup");
    final marge = 120.0;  
    popup = Popup(gameRef.size - Vector2.all(marge), onClickClose: onClickClose);
    popup.position = Vector2.all(marge / 2);
    add(popup);

    print("OptionsScreen.onLoaded");
  }

  @override
  bool onClick(Vector2 p) 
  {
    popup.onClick(p);
    return true;
  }
}

class Popup extends SpriteComponent
{
  static bool inited = false;
  static late final Sprite _cornerTopLeft;
  static late final Sprite _cornerTopRight;
  static late final Sprite _cornerBottomLeft;
  static late final Sprite _cornerBottomRight;
  static late final Sprite _center;
  static late final Sprite _centerTop;
  static late final Sprite _centerBottom;

  static final double square = 19;
  static final double square2 = square * 2;

  static Future<void> init() async
  {
    if(inited)
      return;

    print("Popup.init.start");
    final sheet = SpriteSheet(image: await Images().load("gui.png"), srcSize: Vector2(32, 32));
    _cornerTopLeft = sheet.getSprite(7, 0);
    _cornerTopRight = sheet.getSprite(7, 3);
    _cornerBottomLeft = sheet.getSprite(10, 0);
    _cornerBottomRight = sheet.getSprite(10, 3);
    _center = sheet.getSprite(1, 13);
    _centerTop = sheet.getSprite(7, 1);
    _centerBottom = sheet.getSprite(10, 1);

    print("Popup.init.end");
  }

  late final SpriteComponent? _buttonClose;
  late final VoidCallback? onClickClose;

  Popup(Vector2 size, {VoidCallback? this.onClickClose}):super(size: size);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    addChild(SpriteComponent(sprite: _centerTop, size: Vector2(size.x - square2, square), position: Vector2(square, 0)));
    addChild(SpriteComponent(sprite: _centerBottom, size: Vector2(size.x - square2, square), position: Vector2(square, size.y - square)));

    final left = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(square, square));
    left.angle = degrees2Radians * 90;
    addChild(left);

    final right = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(size.x, square));
    right.angle = degrees2Radians * 90;
    right.renderFlipY = true;
    addChild(right);

    addChild(SpriteComponent(sprite: _cornerTopLeft, size: Vector2.all(square)));
    addChild(SpriteComponent(sprite: _cornerTopRight, size: Vector2.all(square), position: size - Vector2(square, size.y)));
    addChild(SpriteComponent(sprite: _cornerBottomLeft, size: Vector2.all(square), position: size - Vector2(size.x, square)));
    addChild(SpriteComponent(sprite: _cornerBottomRight, size: Vector2.all(square), position: size - Vector2(square, square)));
    addChild(SpriteComponent(sprite: _center, size: size - Vector2.all(square2), position: Vector2(square, square)));
  
    if(kIsWeb)
    {
      _buttonClose = SpriteComponent(sprite: Sprite(await Images().load("button_close.png")), position: Vector2(size.x - square2, 0), size: Vector2.all(square2));
      addChild(_buttonClose!);
    }
  }

  void onClick(Vector2 p) 
  {
    print(p);
    if(kIsWeb && _buttonClose!.containsPoint(p))
    {
      onClickClose?.call();
    }
    
  }
}