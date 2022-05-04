import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/world/world.dart';

class DonjonScreen extends AbstractScreen
{
  late final Donjon _donjon;
  late final PlayerComponent _player;
  late final Decor _decor;

  late final SpriteComponent _buttonSettings;

  DonjonScreen(GameLayout gameRef, Vector2 size):super(gameRef, "D", size);

  @override
  Future<void> onLoad() async 
  {
    print("DonjonScreen.onLoad");
    await super.onLoad();

    gameRef.setBackgroundColor(Colors.black);

    _donjon = Storage.getDonjon();

    _decor = Decor(gameRef, _donjon);
    add(_decor);

    _player = PlayerComponent(this);
    add(_player);
    
    _donjon.setScreen(this);
    _donjon.setPlayerListener(_player);

    _buttonSettings = SpriteComponent(position: Vector2(gameRef.size.x - 100, 5), size: Vector2.all(32), sprite: Sprite(await Images().load("button_settings.png")));
    hud.addChild(_buttonSettings);

    _player.onMove(force: true);
    print("DonjonScreen.onLoaded");
  }

  void startFight()
  {
    //print("DonjonScreen.startFight");
    gameRef.startFight();
  }

  void changeSalle()
  {
    Vector2 p = Vector2.copy(_decor.position);
    _decor.position = Vector2.all(1000);
    _player.position = Vector2.all(1000);
    Future.delayed(Duration(milliseconds: 600), () {
      _decor.position = p;
      _player.onMove(force: true);
    });
    _decor.changeSalle();
    
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    _donjon.update(dt);
    if(!shouldRemove)
      _player.onMove();
  }

  @override
  bool onClick(Vector2 p) 
  {
    print(p);

    if(_buttonSettings.containsPoint(p))
    {
      gameRef.startOptions();
      return true;
    }

    final eClick = Vector2(p.x, p.y) - gameRef.size / 2;
    final click = eClick..divide(Vector2(50, 50));
    if(!_donjon.entityGoTo(click))
    {
      if(_decor.clickedEst(p))
        _donjon.entityGoTo(Vector2(6.5, 0.96), dir: 1);

      if(_decor.clickedNord(p))
        _donjon.entityGoTo(Vector2(0, -2.2), dir: 0);

      if(_decor.clickedSud(p))
        _donjon.entityGoTo(Vector2(0, 4.1), dir: 2);

      if(_decor.clickedOuest(p))
        _donjon.entityGoTo(Vector2(-6.5, .96), dir: 3);
    }
    return true;
  }

  @override
  void onRemove() 
  {
    //print("DonjonScreen.onRemove");
    super.onRemove();
  }
}

class Decor extends SpriteComponent with HasGameRef<GameLayout>
{
  final GameLayout gameRef;
  final Donjon donjon;

  SpriteComponent? arrowSud;
  SpriteComponent? arrowNord;
  SpriteComponent? arrowOuest;
  SpriteComponent? arrowEst;

  Decor(this.gameRef, this.donjon):super(priority: 0);

  @override
  Future<void> onLoad() async 
  {
    //print("Decor.onLoad");
    await super.onLoad();

    await gameRef.images.load('arrow.png');

    sprite = Sprite(await Images().load("salle.png"));
    size = gameRef.size - Vector2(100, 70);
    position = Vector2(50, 35);

    changeSalle();

    //print("Decor.onLoaded");
  }

  void changeSalle() async
  {
    children.clear();
    if(donjon.currentSalle == donjon.start || donjon.currentSalle.s != null)
    {
      //print("Decor.addPorteSud");
      final porteSud = SpriteComponent();
      porteSud.sprite = Sprite(await Images().load("porte_sud.png"));
      porteSud.size = Vector2(130, 28);
      porteSud.anchor = Anchor.bottomCenter;
      porteSud.position = Vector2(size.x /2, size.y);
      addChild(porteSud);

      if(donjon.currentSalle.s != null)
      {
        arrowSud = SpriteComponent();
        arrowSud!.sprite = Sprite(await gameRef.images.fromCache('arrow.png'));
        arrowSud!.size = Vector2(50, 30);
        arrowSud!.anchor = Anchor.bottomCenter;
        arrowSud!.position = Vector2(size.x /2, size.y + 35);
        arrowSud!.renderFlipY = true;
        addChild(arrowSud!);
      }
    }

    if(donjon.currentSalle.n != null)
    {
      //print("Decor.addPorteNord");
      final porteNord = SpriteComponent();
      porteNord.sprite = Sprite(await Images().load("porte_nord.png"));
      porteNord.size = Vector2(130, 95);
      porteNord.anchor = Anchor.topCenter;
      porteNord.position = Vector2(size.x / 2, 0);
      addChild(porteNord);

      arrowNord = SpriteComponent();
      arrowNord!.sprite = Sprite(await gameRef.images.fromCache('arrow.png'));
      arrowNord!.size = Vector2(50, 30);
      arrowNord!.anchor = Anchor.topCenter;
      arrowNord!.position = Vector2(size.x / 2, -15);
      addChild(arrowNord!);
    }

    if(donjon.currentSalle.w != null)
    {
      //print("Decor.addPorteOuest");
      final porteOuest = SpriteComponent();
      porteOuest.sprite = Sprite(await Images().load("porte_ouest.png"));
      porteOuest.size = Vector2(43, 130);
      porteOuest.anchor = Anchor.centerLeft;
      porteOuest.position = Vector2(0, size.y / 2);
      addChild(porteOuest);

      arrowOuest = SpriteComponent();
      arrowOuest!.sprite = Sprite(await gameRef.images.fromCache('arrow.png'));
      arrowOuest!.size = Vector2(50, 35);
      arrowOuest!.anchor = Anchor.centerLeft;
      arrowOuest!.position = Vector2(-35, size.y / 2 + 35);
      arrowOuest!.renderFlipX = true;
      arrowOuest!.angle = degrees2Radians * 270;
      addChild(arrowOuest!);
    }

    if(donjon.currentSalle.e != null)
    {
      //print("Decor.addPorteEst");
      final porteEst = SpriteComponent();
      porteEst.sprite = Sprite(await Images().load("porte_ouest.png"));
      porteEst.size = Vector2(43, 130);
      porteEst.anchor = Anchor.centerRight;
      porteEst.renderFlipX = true;
      porteEst.position = Vector2(size.x, size.y / 2);
      addChild(porteEst);

      arrowEst = SpriteComponent();
      arrowEst!.sprite = Sprite(await gameRef.images.fromCache('arrow.png'));
      arrowEst!.size = Vector2(50, 35);
      arrowEst!.position = Vector2(size.x + 50, size.y / 2 - 15);
      arrowEst!.angle = degrees2Radians * 90;
      addChild(arrowEst!);
    }
  }

  bool clickedOuest(Vector2 p)
  {
    return p.x < 40 && p.y > 240 && p.y < 280;
  }

  bool clickedEst(Vector2 p)
  {
    return p.x > 800 && p.x < 845 && p.y > 240 && p.y < 280;
  }

  bool clickedSud(Vector2 p)
  {
    return arrowSud != null && arrowSud!.containsPoint(p);
  }

  bool clickedNord(Vector2 p)
  {
    return arrowNord != null && arrowNord!.containsPoint(p);
  }
}

class PlayerComponent extends PositionComponent with HasGameRef<GameLayout> implements EntityListener
{
  final DonjonScreen _donjonScreen;
  late final Player _player;
  late final GameLayout gameRef;

  bool moving = false;

  PlayerComponent(this._donjonScreen):super(priority: 1)
  {
    gameRef = _donjonScreen.gameRef;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    _player = Player();
    size = _player.size;
    anchor = Anchor.bottomCenter;
    final shadow = Shadow(Vector2(35, 10), Vector2(_player.size.x * .37, _player.size.y - 10));
    addChild(shadow);
    addChild(_player);
    onMove(force: true);
  }
  
  @override
  void onStartMove(double dir) 
  {
    moving = true;
    renderFlipX = dir < 0;
    _player.animation = _player.move;
  }

  void onMove({bool force = false})
  {
    if(moving || force)
    {
      Position entityPosition = _donjonScreen._donjon.entityPosition;
      position = Vector2(entityPosition.x, entityPosition.y) * 50;
      position += gameRef.size / 2;
    }
  }

  @override
  void onStopMove() 
  {
    moving = false;
    _player.animation = _player.idle;
  }

  @override
  void onRemove() 
  {
    //print("PlayerComponent.onRemove");
    super.onRemove();
  }
}

class Player extends SpriteAnimationComponent
{
  late final SpriteAnimation idle;
  late final SpriteAnimation move;
  
  Player():super(size: Vector2(160, 95));
  
  @override
  Future<void> onLoad() async 
  {
    //print("Player.onLoad");
    await super.onLoad();
    final spriteSheet = SpriteSheet(image: await Images().load("hero_knight.png"), srcSize: Vector2(100, 55));
    idle = spriteSheet.createAnimation(row: 0, stepTime: .1, from: 0, to: 6);
    final List<Sprite> runSprites = [];
    final List<Sprite> row0 = List<int>.generate(2, (i) => 8 + i).map((e) => spriteSheet.getSprite(0, e)).toList();
    runSprites.addAll(row0);
    final List<Sprite> row1 = List<int>.generate(8, (i) => 0 + i).map((e) => spriteSheet.getSprite(1, e)).toList();
    runSprites.addAll(row1);
    move = SpriteAnimation.spriteList(runSprites, stepTime: .06, loop: true);
    animation = idle;
    //anchor = Anchor.bottomCenter;
    //print("Player.onLoaded");
  }
}