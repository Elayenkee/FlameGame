import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/main.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:myapp/storage/storage.dart';

class OptionsScreen  extends AbstractScreen
{
  late final Popup popup;
  late final VoidCallback? onClickClose;

  late Entity selectedEntity;
  final List<BuilderBehaviourComponent> behaviours = [];
  BuilderBehaviourComponent? draggingBehaviour;
  double draggingOffsetY = 0;

  PopupBuilderBehaviour? popupBuilderBehaviour;

  OptionsScreen(GameLayout gameRef, Vector2 size, {VoidCallback? this.onClickClose}):super(gameRef, "D", size);

  @override
  Future<void> onLoad() async 
  {
    print("OptionsScreen.onLoad");
    await super.onLoad();

    selectedEntity = Storage.getEntity();

    final b = Background(gameRef.size);
    b.setColor(Color.fromARGB(129, 0, 0, 0));
    add(b);

    await Popup.init();

    print("add popup");
    final marge = 120.0;  
    popup = Popup(gameRef.size - Vector2.all(marge), onClickClose: onClickClose);
    popup.position = Vector2.all(marge / 2);
    add(popup);

    final player = Player();
    player.position = Vector2(Popup.square, -30);
    popup.addChild(player);

    for(BuilderBehaviour behaviour in selectedEntity.builder.builderTotal.builderBehaviours)
      addBuilderBehaviour(behaviour);
    
    print("OptionsScreen.onLoaded");
  }

  void addBuilderBehaviour(BuilderBehaviour behaviour)
  {
    BuilderBehaviourComponent behaviourComponent = BuilderBehaviourComponent(gameRef, selectedEntity, behaviour, Vector2(popup.size.x - 30, popup.size.y / 7.2));
    behaviourComponent.position = Vector2(10, 55 + ((10 + behaviourComponent.size.y) * behaviours.length));
    behaviourComponent.init();
    behaviours.add(behaviourComponent);
    popup.addChild(behaviourComponent);
  }

  void onBehaviourDragging(DragUpdateInfo info)
  {
    if(behaviours.length <= 1 || draggingBehaviour == null)
      return;

    draggingBehaviour!.y += info.delta.game.y;
    for(int i = 0; i < behaviours.length; i++)
    {
      BuilderBehaviourComponent b = behaviours[i];
      if(b != draggingBehaviour)
      {
        if(draggingBehaviour!.y >= b.initialPosition.y - 10 && draggingBehaviour!.y < b.initialPosition.y + b.size.y)
        {
          behaviours[behaviours.indexOf(draggingBehaviour!)] = b;
          behaviours[i] = draggingBehaviour!;
          Vector2 tmp = Vector2.copy(b.initialPosition);
          b.initialPosition = draggingBehaviour!.initialPosition;
          b.targetPosition = Vector2.copy(b.initialPosition);
          draggingBehaviour!.initialPosition = tmp;
          selectedEntity.builder.builderTotal.switchBehaviours(draggingBehaviour!.builderBehaviour, b.builderBehaviour);
          Storage.storeEntity(selectedEntity);
          return;
        }
      }
    }
  }

  @override
  bool onClick(Vector2 p) 
  {
    if(popupBuilderBehaviour != null)
    {
      popupBuilderBehaviour?.onClick(p);
      return true;
    }

    popup.onClick(p);

    for(BuilderBehaviourComponent b in behaviours)
    {
      if(b.onClick(p))
        return true;
    }

    if(draggingBehaviour == null)
    {
      for(BuilderBehaviourComponent b in behaviours)
      {
        if(b.containsPoint(p))
        {
          draggingBehaviour = b;
          gameRef.changePriority(draggingBehaviour!, 1000);
        }
        else
        {
          gameRef.changePriority(b, 900);
        }
      }
    }
    
    return true;
  }

  void onPanUpdate(DragUpdateInfo info)
  {
    print("onPanUpdate");
    onBehaviourDragging(info);
  }

  void onPanEnd()
  {
    print("onPanEnd");
    draggingBehaviour?.targetPosition = draggingBehaviour?.initialPosition;
    draggingBehaviour = null;
  }
}

class BuilderBehaviourComponent extends SpriteComponent
{
  final GameLayout gameRef;
  final Entity entity;
  final BuilderBehaviour builderBehaviour;

  late Vector2 initialPosition;
  Vector2? targetPosition;

  late final TextComponent textName;

  late final Sprite torchActivated;
  late final Sprite torchDesactivated;
  late final SpriteComponent torch;

  late final SpriteComponent edit;

  BuilderBehaviourComponent(this.gameRef, this.entity, this.builderBehaviour, size):super(size: size);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    Sprite spriteLeft = Sprite(await Images().load("cadre_1_left.png"));
    SpriteComponent left = SpriteComponent(sprite: spriteLeft);
    left.size = Vector2(size.y * .3, size.y);
    addChild(left);

    SpriteComponent right = SpriteComponent(sprite: spriteLeft);
    right.size = Vector2(size.y * .3, size.y);
    right.position = Vector2(size.x - right.size.x + 5, 0);
    right.renderFlipX = true;
    addChild(right);

    SpriteComponent middle = SpriteComponent(sprite: Sprite(await Images().load("cadre_1_middle.png")));
    middle.size = Vector2(size.x - right.size.x * 2 + 5, size.y);
    middle.position = Vector2(left.size.x, 0);
    addChild(middle);

    torchActivated = Sprite(await Images().load("torch_activated.png"));
    torchDesactivated = Sprite(await Images().load("torch_desactivated.png"));

    torch = SpriteComponent();
    torch.size = Vector2(17, 43);
    torch.position = Vector2.all(size.y / 2);
    torch.sprite = builderBehaviour.activated ? torchActivated : torchDesactivated;
    torch.anchor = Anchor.center;
    addChild(torch);

    edit = SpriteComponent(sprite: Sprite(await Images().load("icon_edit.png")));
    edit.size = Vector2.all(30);
    edit.anchor = Anchor.center;
    edit.position = Vector2(size.x - 20, size.y / 2);
    addChild(edit);

    textName = TextComponent(builderBehaviour.name);
    textName.position = Vector2(50, 10);
    addChild(textName);
  }

  void init()
  {
    initialPosition = Vector2.copy(position);
  }

  bool onClick(Vector2 p) 
  {
    if(edit.containsPoint(p))
    {
      gameRef.add(PopupBuilderBehaviour(gameRef));
      return true;
    }

    if(torch.containsPoint(p) && (builderBehaviour.activated || builderBehaviour.isValid(Validator(false))))
    {
      builderBehaviour.activated = !builderBehaviour.activated;
      torch.sprite = builderBehaviour.activated ? torchActivated : torchDesactivated;
      Storage.storeEntity(entity);
      return true;
    }
    return false;
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    if(targetPosition != null)
    {
        position.moveToTarget(targetPosition!, 30);
        if(position.distanceTo(targetPosition!) < 1)
          targetPosition = null;
    }
  }
}

class PopupBuilderBehaviour extends SpriteComponent
{
  final GameLayout gameRef;

  late final SpriteComponent _buttonClose;

  PopupBuilderBehaviour(this.gameRef):super(size: Vector2(730, 400))
  {
    gameRef.optionsScreen!.popupBuilderBehaviour = this;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    print("PopupBuilderBehaviour.onLoad");
    sprite = Sprite(await Images().load("cadre_behaviour.png"));
    anchor = Anchor.center;
    position = gameRef.size / 2;

    _buttonClose = SpriteComponent(sprite: Sprite(await Images().load("button_close.png")), position: Vector2(size.x - 32, -6), size: Vector2.all(38));
      addChild(_buttonClose);

    print("PopupBuilderBehaviour.onLoaded");
  }

  bool onClick(Vector2 p) 
  {
    if(_buttonClose.containsPoint(p))
    {
      gameRef.optionsScreen!.popupBuilderBehaviour = null;
      remove();
    }
    return true;
  }
}

class Player extends SpriteComponent
{
  Player():super(size: Vector2(70, 80));
  
  @override
  Future<void> onLoad() async 
  {
    print("Player.onLoad");
    await super.onLoad();
    final spriteSheet = SpriteSheet(image: await Images().load("hero_knight.png"), srcSize: Vector2(100, 55));
    final SpriteAnimationComponent player = SpriteAnimationComponent();
    player.animation = spriteSheet.createAnimation(row: 0, stepTime: .15, from: 0, to: 6);
    player.size = Vector2(130, 72);
    player.anchor = Anchor.topCenter;
    player.position = Vector2(size.x / 2, 0);
    addChild(player);

    sprite = Sprite(await Images().load("cadre_player.png"));

    print("Player.onLoaded");
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

    inited = true;
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

    //addChild(SpriteComponent(sprite: _centerTop, size: Vector2(size.x - square2, square), position: Vector2(square, 0)));
    //addChild(SpriteComponent(sprite: _centerBottom, size: Vector2(size.x - square2, square), position: Vector2(square, size.y - square)));

    final left = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(square, square));
    left.angle = degrees2Radians * 90;
    //addChild(left);

    final right = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(size.x, square));
    right.angle = degrees2Radians * 90;
    right.renderFlipY = true;
    //addChild(right);

    //addChild(SpriteComponent(sprite: _cornerTopLeft, size: Vector2.all(square)));
    //addChild(SpriteComponent(sprite: _cornerTopRight, size: Vector2.all(square), position: size - Vector2(square, size.y)));
    //addChild(SpriteComponent(sprite: _cornerBottomLeft, size: Vector2.all(square), position: size - Vector2(size.x, square)));
    //addChild(SpriteComponent(sprite: _cornerBottomRight, size: Vector2.all(square), position: size - Vector2(square, square)));
    //addChild(SpriteComponent(sprite: _center, size: size - Vector2.all(square2), position: Vector2(square, square)));
  
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

class Bouton extends SpriteComponent with Tappable
{
  final Function onTap;

  Bouton(this.onTap, Sprite sprite):super(sprite:sprite)
  {
    size = Vector2(30, 30);
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    onTap();
    return true;
  }
}