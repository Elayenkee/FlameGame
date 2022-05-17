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

  Fight? fight;
  final Map<String, EntityInfos> infos = {};

  DonjonScreen(GameLayout gameRef, Vector2 size):super(gameRef, "D", size);

  @override
  Future<void> onLoad() async 
  {
    //print("DonjonScreen.onLoad.start");
    await super.onLoad();

    //print("DonjonScreen.onLoad.gameRef");

    gameRef.setBackgroundColor(Colors.black);
    //print("DonjonScreen.onLoad.background.ok");

    donjon = Storage.donjon;
    //print("DonjonScreen.onLoad.donjon.ok");
    
    _decor = Decor(gameRef, donjon);
    await add(_decor);
    //print("DonjonScreen.onLoad.decor.ok");

    _player = EntityComponent(gameRef, Storage.entity, getEntityPosition);
    await add(_player);
    //print("DonjonScreen.onLoad.player.ok");
    
    donjon.setScreen(this);
    donjon.setPlayerListener(_player); 

    _buttonSettings = SpriteComponent(size: Vector2.all(32), sprite: Sprite(await ImagesUtils.loadImage("button_settings.png")));
    _buttonSettings.position = Storage.entity.nbCombat > 0 ? Vector2(gameRef.size.x - 32, 5) : Vector2(-1000, 0); 
    await hud.addChild(_buttonSettings);

    for(int i = 0; i < Storage.entities.length; i++)
    {
      Entity e = Storage.entities[i];
      EntityInfos entityInfos = EntityInfos(Storage.entity);
      entityInfos.position = Vector2(60 + (i * (entityInfos.size.x = 5)), 20);
      infos[e.uuid] = entityInfos;
      await hud.addChild(entityInfos);
      entityInfos.updateBars(e);
    }
    
    _player.onMove(force: true);

    //print("DonjonScreen.onLoad.end");
  }

  Vector2 getEntityPosition(Entity entity)
  {
    if(fight != null)
      return fight!.getEntityPosition(entity);
    return donjon.entityPosition;
  }

  void startFight() async
  {
    //print("DonjonScreen.startFight.start");
    fight = Fight(this)..start();
    //print("DonjonScreen.startFight.end");
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
    fight?.update(dt);
  }

  @override
  bool onClick(Vector2 p) 
  {
    if(fight != null && gameRef.tutorielScreen == null)
      return true;

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
    //print("Decor.onLoad");
    await super.onLoad();

    sprite = Sprite(await ImagesUtils.loadImage("salle.png"));
    size = gameRef.size - Vector2(100, 70);
    position = Vector2(50, 35);

    await changeSalle();

    //print("Decor.onLoaded");
  }

  Future<void> changeSalle() async
  {
    children.clear();
    if(donjon.currentSalle == donjon.start || donjon.currentSalle.s != null)
    {
      //print("Decor.addPorteSud.start");
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
      //print("Decor.addPorteSud.end");
    }

    if(donjon.currentSalle.n != null)
    {
      //print("Decor.addPorteNord.start");
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
      //print("Decor.addPorteNord.end");
    }

    if(donjon.currentSalle.w != null)
    {
      //print("Decor.addPorteOuest.start");
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
      //print("Decor.addPorteOuest.end");
    }

    if(donjon.currentSalle.e != null)
    {
      //print("Decor.addPorteEst.start");
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
      //print("Decor.addPorteEst.end");
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

class Fight
{
  final DonjonScreen container;
  late final Server server;

  bool started = false;
  final List<Story> stories = [];
  StoryAnimation? storyAnimation;

  final Map<String, EntityFight> entities = {};

  Fight(this.container);

  void start() async
  {
    print("Fight.start.start");
    EntityFight player = EntityFight(Storage.entity, container._player, container.infos[Storage.entity.uuid]!, container.donjon.entityPosition);
    entities[Storage.entity.uuid] = player;

    BuilderServer builder = BuilderServer();
    Storage.entities.forEach((element) {builder.addEntity(e:element);});
    addEnnemies(builder);
    server = builder.build();
    int indexEnnemy = 1;
    server.entities.forEach((element) async{ 
      if(element.getClan() != Storage.entity.getClan())
      {
        EntityComponent ennemy = EntityComponent(container.gameRef, element, getEntityPosition);
        EntityInfos infos = EntityInfos(element);
        infos.position = Vector2(container.gameRef.size.x - 60 -(indexEnnemy * (infos.size.x + 5)), 20);
        container.infos[element.uuid] = infos;
        entities[element.uuid] = EntityFight(element, ennemy, infos, Vector2.all(0));
        ennemy.face(player.position.x - entities[element.uuid]!.position.x);
        await container.addWithGameRef(ennemy);
        //TODO POSITION
      }  
    });

    await Future.delayed(const Duration(milliseconds: 100));
    //if(Storage.entity.nbCombat <= 0)
    //{
    //  startTutorielSettings();
    //}
    //else
    //{
      onEndTutoriel();
    //}
    print("Fight.start.end");
  }

  void onEndTutoriel()
  {
    print("Fight.onEndTutoriel.start");
    server.entities.forEach((element) async{ 
      if(element.getClan() != Storage.entity.getClan())
      {
        EntityInfos infos = container.infos[element.uuid]!;
        container.hud.addChild(infos, gameRef: container.gameRef);
        infos.updateBars(element);
      }  
    });
    
    Story? story;
    do{
      story = server.next();
      if(story != null)
        stories.add(story);  
    } while (story != null && stories.length < 100);
    started = true;
    print("Fight.onEndTutoriel.end");
  }

  Vector2 getEntityPosition(Entity entity)
  {
    Vector2 result = entities[entity.uuid]!.position;
    return result;
  }

  void update(double dt) 
  {
    entities.values.forEach((element) { 
      element.update(dt);
      container.gameRef.changePriorities({
        element.component: element.component.position.y.toInt()
      });
    });

    if(!started)
      return;

    if(storyAnimation != null)
    {
      storyAnimation!.update(dt);
      if(storyAnimation!.isFinished)
        storyAnimation = null;
      return;
    }

    if(stories.length > 0)
    {
      Story story = stories.removeAt(0);
      storyAnimation = StoryAnimation(this, story);
    }
    else if(!finished)
    {
      finish();
    }
  }

  bool finished = false;
  void finish()
  {
    finished = true;
    TextComponent txtFin = TextComponent("FIN DU DEV EN COURS ! MERCI !", textRenderer: TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.red, fontSize: 40)));
    txtFin.anchor = Anchor.center;
    txtFin.position = container.gameRef.size / 2;
    container.hud.addChild(txtFin, gameRef: container.gameRef);
    print("Fight.finish");
  }

  void addEnnemies(BuilderServer builder)
  {
    Map values = {};
    values[VALUE.HP_MAX] = 22;
    values[VALUE.MP_MAX] = 0;
    values[VALUE.ATK] = 8;
    values[VALUE.NAME] = "DemonBat";
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
    builderBehaviour4.activated = true;
  }

  void startTutorielSettings()
  {
    if(container.gameRef.tutorielScreen == null)
    {
      container.gameRef.startTutoriel(TutorielSettings(container.gameRef, container._buttonSettings, onEndTutoriel));
    }
  }
}

class StoryAnimation
{
  final Fight fight;
  final Story story;
  bool isFinished = false;

  int indexCurrentEvent = -1;
  EventAnimation? eventAnimation;

  StoryAnimation(this.fight, this.story);

  void update(double dt)
  {
    if(eventAnimation == null)
    {
      indexCurrentEvent++;
      if(story.events.length <= indexCurrentEvent)
      {
        isFinished = true;
      }
      else
      {
        eventAnimation = EventAnimation(fight, story.events[indexCurrentEvent]);
        eventAnimation!.start();
      }
    }
    else
    {
      if(eventAnimation!.isFinished)
      {
        eventAnimation = null;
      }
      else
      {
        eventAnimation!.update(dt);
      }
    }
  }
}

class EventAnimation
{
  final Fight fight;
  final StoryEvent event;
  bool isFinished = false;

  List<Step> steps = [];
  Step? currentStep;
  double waiter = 0;

  EventAnimation(this.fight, this.event);

  void start()
  {
    print("EventAnimation.start.start ${event.log}");
    EntityFight callerComponent = getEntityFight("caller")!;
    EntityFight? targetComponent = getEntityFight("target");

    steps.add(new Step((){callerComponent.stepForward(targetComponent);}, () => callerComponent.targetPosition == null));
    wait(.05);
    
    List<PositionComponent> toReset = [];
    if(event.values.containsKey("work"))
    {
      steps.add(new Step((){
        WorkAnimation workAnimation = callerComponent.component.work(Work.getFromName(event.values["work"]));
        workAnimation.onEvent = (WorkEvent workEvent){
          if(workEvent == WorkEvent.HIT)
          {
            Map target = event.get("target") as Map;
            targetComponent?.setStatus(target);
            targetComponent?.component.onHit();
          }
        };
        workAnimation.start();
      }, () => callerComponent.component.workAnimation == null || callerComponent.component.workAnimation!.isFinished));
    }

    if(event.values.containsKey("type"))
    {
      steps.add(new StepTrue(()
      {
        /*SpriteComponent sprite = game.mapAnimations[event.get("source") as String];
        sprite.position = targetComponent!.position - Vector2(0, 150);
        toReset.add(sprite);*/
      }));
    }

    if(targetComponent != null)
    {
      steps.add(new StepTrue(()
      {
        /*if(event.has("damage"))
        {
          int value = event.get("damage") as int;
          game.damage.position = targetComponent.position - Vector2(0, 120);
          game.damage.text = "$value";
          game.damage.textRenderer = TextPaint(config: TextPaintConfig(color: value < 0 ? Colors.red : Colors.green));
          toReset.add(game.damage);
        }*/

        //targetComponent.setHP();
      }));
    }

    // Reset positions
    //wait(.5);
    steps.add(new StepTrue(()
    {
      for(PositionComponent c in toReset)
        c.position = Vector2.all(-100);
    }));

    if(callerComponent != null)
    {
      wait(.02);
      steps.add(new Step((){callerComponent.moveToInitialPosition();}, () => callerComponent.targetPosition == null));
    }

    wait(1);

    next();

    print("EventAnimation.start.end ${event.log}");
  }

  void wait(double s)
  {
    steps.add(new Step((){waiter = s;}, () => waiter <= 0));
  }

  void update(double dt)
  {
    if(waiter > 0)
    {
      waiter -= dt;
      if(waiter < 0)
        waiter = 0;
    }

    if(currentStep?.stopCondition())
      next();
  }

  void next()
  {
    if(!steps.isEmpty)
    {
      currentStep = steps.removeAt(0);
      currentStep!.action();    
    }
    else
    {
      isFinished = true;
    }
  }

  EntityFight? getEntityFight(String type)
  {
    try
    {
      Map caller = event.get(type) as Map;
      if(caller.containsKey("uuid"))
      {
        String uuidCaller = caller["uuid"];
        EntityFight callerComponent = fight.entities[uuidCaller]!;
        return callerComponent;
      }
    }
    catch(e)
    {
      print("Fight.getEntityFight.exception $e");
    }
    return null;
  }
}

class EntityFight
{
  final Entity entity;
  final EntityComponent component;
  final EntityInfos infos;
  final Vector2 initialPosition;

  late Vector2 position;
  Vector2? targetPosition;

  int faceForwarded = 1;
  Vector2? forwarded;

  final double _speed = 5;

  EntityFight(this.entity, this.component, this.infos, this.initialPosition)
  {
    print("EntityFight.init.start");
    position = Vector2.copy(initialPosition);
    print("EntityFight.init.end");
  }

  void setStatus(Map status)
  {
    this.infos.setStatus(status);
  }

  void stepForward(EntityFight? target)
  {
    if(target != null && target.entity != entity)
    {
      targetPosition = Vector2.copy(target.position);
      Vector2 direction = (targetPosition! - position)..normalize();
      targetPosition = targetPosition! - direction * .9;
      component.onStartMove(targetPosition!.x - position.x);
      faceForwarded = 1;
      forwarded = Vector2.copy(targetPosition!);
      print("EntityFight.stepFoward $entity $forwarded");
    }
  }

  void moveToInitialPosition()
  {
    print("EntityFight.moveToInitialPosition $entity");
    targetPosition = Vector2.copy(initialPosition);
    component.onStartMove(targetPosition!.x - position.x);
  }

  void update(double dt)
  {
    if(targetPosition == null)
      return;
    
    final d = position.distanceTo(targetPosition!);
    final max = _speed * dt;
    if(d < max)
    {
      position = targetPosition!;
      targetPosition = null;
      component.onStopMove();
      if(forwarded != null)
      {
        if(faceForwarded == 1)
        {
          faceForwarded = 0;
        }
        else
        {
          component.face(forwarded!.x - position.x);
          forwarded = null;
        }
      }
      else
      {
        print("Forwarded null");
      }
      return;
    }
    
    final v = Vector2(targetPosition!.x - position.x, targetPosition!.y - position.y)..normalize()..multiply(Vector2.all(max));
    position.x += v.x;
    position.y += v.y;
  }
}

class Step 
{
  final Function action;
  final Function stopCondition;

  Step(this.action, this.stopCondition);
}

class StepTrue extends Step
{
  StepTrue(Function action):super(action, () => true);
}