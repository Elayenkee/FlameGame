import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/donjon/entity_component.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/tutoriel/tutoriel_screen.dart';
import 'package:myapp/utils/images.dart';
import 'package:myapp/works/work.dart';
import 'package:myapp/engine/server.dart';

class DonjonScreen extends AbstractScreen
{
  late final Donjon donjon;
  late final EntityComponent _player;
  late final Decor _decor;

  late final SpriteComponent _buttonSettings;

  DonjonScreen(GameLayout gameRef, Vector2 size):super(gameRef, "D", size);

  @override
  Future<void> onLoad() async 
  {
    print("DonjonScreen.onLoad.start");
    await super.onLoad();

    print("DonjonScreen.onLoad.gameRef");

    gameRef.setBackgroundColor(Colors.black);
    print("DonjonScreen.onLoad.background.ok");

    donjon = Storage.donjon;
    print("DonjonScreen.onLoad.donjon.ok");
    
    _decor = Decor(gameRef, donjon);
    await add(_decor);
    print("DonjonScreen.onLoad.decor.ok");

    _player = EntityComponent(gameRef, Storage.entity, getEntityPosition);
    await add(_player);
    print("DonjonScreen.onLoad.player.ok");
    
    donjon.setScreen(this);
    donjon.setPlayerListener(_player);

    _buttonSettings = SpriteComponent(size: Vector2.all(32), sprite: Sprite(await ImagesUtils.loadImage("button_settings.png")));
    _buttonSettings.position = Storage.entity.nbCombat > 0 ? Vector2(gameRef.size.x - 32, 5) : Vector2(-1000, 0); 
    hud.addChild(_buttonSettings);

    _player.onMove(force: true);

    print("DonjonScreen.onLoad.end");
  }

  Vector2 getEntityPosition(Entity entity)
  {

    return donjon.entityPosition;
  }

  void startFight() async
  {
    print("DonjonScreen.startFight");
    BuilderServer builder = BuilderServer();
    Storage.entities.forEach((element) {builder.addEntity(e:element);});
    addRandomEnemmy(builder);
    Server server = builder.build();
    if(Storage.entity.nbCombat <= 0)
      startTutorielSettings();
  }

  void startTutorielSettings()
  {
    if(gameRef.tutorielScreen == null)
    {
      gameRef.startTutoriel(TutorielSettings(gameRef, _buttonSettings, gameRef.startFight));
    }
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
    donjon.update(dt);
    if(!shouldRemove)
      _player.onMove();
  }

  @override
  bool onClick(Vector2 p) 
  {
    if(gameRef.tutorielScreen != null && gameRef.tutorielScreen!.onClick(p))
      return true;

    if(_buttonSettings.containsPoint(p))
    {
      gameRef.tutorielScreen?.onEvent(TutorielSettings.EVENT_CLICK_OPEN_SETTINGS);
      gameRef.startOptions();
      return true;
    }

    if(gameRef.tutorielScreen != null)
      return true;

    final eClick = Vector2(p.x, p.y) - gameRef.size / 2;
    final click = eClick..divide(Vector2(50, 50));
    if(!donjon.entityGoTo(click))
    {
      if(_decor.clickedEst(p))
        donjon.entityGoTo(Vector2(6.5, 0.96), dir: 1);

      if(_decor.clickedNord(p))
        donjon.entityGoTo(Vector2(0, -2.2), dir: 0);

      if(_decor.clickedSud(p))
        donjon.entityGoTo(Vector2(0, 4.1), dir: 2);

      if(_decor.clickedOuest(p))
        donjon.entityGoTo(Vector2(-6.5, .96), dir: 3);
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
    print("Decor.onLoad");
    await super.onLoad();

    sprite = Sprite(await ImagesUtils.loadImage("salle.png"));
    size = gameRef.size - Vector2(100, 70);
    position = Vector2(50, 35);

    await changeSalle();

    print("Decor.onLoaded");
  }

  Future<void> changeSalle() async
  {
    children.clear();
    if(donjon.currentSalle == donjon.start || donjon.currentSalle.s != null)
    {
      print("Decor.addPorteSud.start");
      final porteSud = SpriteComponent();
      porteSud.sprite = Sprite(await ImagesUtils.loadImage("porte_sud.png"));
      porteSud.size = Vector2(130, 28);
      porteSud.anchor = Anchor.bottomCenter;
      porteSud.position = Vector2(size.x /2, size.y);
      await addChild(porteSud, gameRef: gameRef);

      if(donjon.currentSalle.s != null)
      {
        arrowSud = SpriteComponent();
        arrowSud!.sprite = Sprite(await ImagesUtils.loadImage('arrow.png'));
        arrowSud!.size = Vector2(50, 30);
        arrowSud!.anchor = Anchor.bottomCenter;
        arrowSud!.position = Vector2(size.x /2, size.y + 35);
        arrowSud!.renderFlipY = true;
        await addChild(arrowSud!, gameRef: gameRef);
      }
      print("Decor.addPorteSud.end");
    }

    if(donjon.currentSalle.n != null)
    {
      print("Decor.addPorteNord.start");
      final porteNord = SpriteComponent();
      porteNord.sprite = Sprite(await ImagesUtils.loadImage("porte_nord.png"));
      porteNord.size = Vector2(130, 95);
      porteNord.anchor = Anchor.topCenter;
      porteNord.position = Vector2(size.x / 2, 0);
      await addChild(porteNord, gameRef: gameRef);

      arrowNord = SpriteComponent();
      arrowNord!.sprite = Sprite(await ImagesUtils.loadImage('arrow.png'));
      arrowNord!.size = Vector2(50, 30);
      arrowNord!.anchor = Anchor.topCenter;
      arrowNord!.position = Vector2(size.x / 2, -15);
      await addChild(arrowNord!, gameRef: gameRef);
      print("Decor.addPorteNord.end");
    }

    if(donjon.currentSalle.w != null)
    {
      print("Decor.addPorteOuest.start");
      final porteOuest = SpriteComponent();
      porteOuest.sprite = Sprite(await ImagesUtils.loadImage("porte_ouest.png"));
      porteOuest.size = Vector2(43, 130);
      porteOuest.anchor = Anchor.centerLeft;
      porteOuest.position = Vector2(0, size.y / 2);
      await addChild(porteOuest, gameRef: gameRef);

      arrowOuest = SpriteComponent();
      arrowOuest!.sprite = Sprite(await ImagesUtils.loadImage('arrow.png'));
      arrowOuest!.size = Vector2(50, 35);
      arrowOuest!.anchor = Anchor.centerLeft;
      arrowOuest!.position = Vector2(-35, size.y / 2 + 35);
      arrowOuest!.renderFlipX = true;
      arrowOuest!.angle = degrees2Radians * 270;
      await addChild(arrowOuest!, gameRef: gameRef);
      print("Decor.addPorteOuest.end");
    }

    if(donjon.currentSalle.e != null)
    {
      print("Decor.addPorteEst.start");
      final porteEst = SpriteComponent();
      porteEst.sprite = Sprite(await ImagesUtils.loadImage("porte_ouest.png"));
      porteEst.size = Vector2(43, 130);
      porteEst.anchor = Anchor.centerRight;
      porteEst.renderFlipX = true;
      porteEst.position = Vector2(size.x, size.y / 2);
      await addChild(porteEst, gameRef: gameRef);

      arrowEst = SpriteComponent();
      arrowEst!.sprite = Sprite(await ImagesUtils.loadImage('arrow.png'));
      arrowEst!.size = Vector2(50, 35);
      arrowEst!.position = Vector2(size.x + 50, size.y / 2 - 15);
      arrowEst!.angle = degrees2Radians * 90;
      await addChild(arrowEst!, gameRef: gameRef);
      print("Decor.addPorteEst.end");
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

void addRandomEnemmy(BuilderServer builder)
{
  Map values = {};
  values[VALUE.HP_MAX] = 100;
  values[VALUE.MP_MAX] = 0;
  values[VALUE.ATK] = 5;
  values[VALUE.NAME] = "Client 3";
  values[VALUE.CLAN] = 0;
  BuilderEntity entity3 = builder.addEntity();
  entity3.setValues(values);
  BuilderTotal builder3 = entity3.builderTotal;
  BuilderBehaviour builderBehaviour4 = builder3.addBehaviour();
  builderBehaviour4.builderWork.work = Work.attaquer;

  BuilderConditionGroup builderConditionGroup4 = builderBehaviour4.builderTargetSelector.builderConditionGroup;
  BuilderCondition builderCondition5 = builderConditionGroup4.addCondition();
  builderCondition5.setCondition(Conditions.NOT_EQUALS);
  builderCondition5.setParam(1, entity3);
  builderCondition5.setParam(2, VALUE.CLAN);

  BuilderTriFunction builderTriFunction4 = builderBehaviour4.builderTargetSelector.builderTriFunction;
  builderTriFunction4.tri = TriFunctions.LOWEST;
  builderTriFunction4.value = VALUE.HP;
}

class FightComponent extends PositionComponent
{
  @override
  Future<void> onLoad() async 
  {
    //print("Player.onLoad");
    await super.onLoad();
  }
}