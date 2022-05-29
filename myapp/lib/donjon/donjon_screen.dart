import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/donjon/entity_component.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
import 'package:myapp/options/options_screen.dart';
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

    _buttonSettings = SpriteComponent(size: Vector2.all(32), sprite: Sprite(ImagesUtils.getImage("button_settings.png")));
    _buttonSettings.position = Storage.entity.nbCombat > 0 ? Vector2(gameRef.size.x - 80, 5) : Vector2(-1000, 0); 
    await addToHud(_buttonSettings);

    for(int i = 0; i < Storage.entities.length; i++)
    {
      Entity e = Storage.entities[i];
      EntityInfos entityInfos = EntityInfos(Storage.entity);
      entityInfos.position = Vector2(60 + (i * (entityInfos.size.x = 5)), 20);
      infos[e.uuid] = entityInfos;
      await addToHud(entityInfos);
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
  List<ObjectClicked> onClick(Vector2 p) 
  {
    List<ObjectClicked> objects = [];

    if(_buttonSettings.containsPoint(p))
    {
      Function call = (){
        gameRef.startOptions();
      };
      ObjectClicked object = ObjectClicked("DonjonScreen.Settings", TutorielSettings.EVENT_CLICK_OPEN_SETTINGS, call, null);
      objects.add(object);
    }

    final eClick = Vector2(p.x, p.y) - gameRef.size / 2;
    final click = eClick..divide(Vector2(50, 50));

    ObjectClicked? entityGoTo = donjon.entityGoTo(click);
    if(entityGoTo != null)
    {
      objects.add(entityGoTo);
    } 
    else
    {
      if(_decor.clickedEst(p))
      {
        Function call = (){donjon.entityGoTo(Vector2(6.5, 0.96), dir: 1);};
        objects.add(ObjectClicked("DonjonScreen.DoorEast", "", call, null));
      }
      
      else if(_decor.clickedNord(p))
      {
        Function call = (){donjon.entityGoTo(Vector2(0, -2.2), dir: 0);};
        objects.add(ObjectClicked("DonjonScreen.DoorNorth", "", call, null));
      }
      
      else if(_decor.clickedSud(p))
      {
        Function call = (){donjon.entityGoTo(Vector2(0, 4.1), dir: 2);};
        objects.add(ObjectClicked("DonjonScreen.DoorSouth", "", call, null));
      }  

      else if(_decor.clickedOuest(p))
      {
        Function call = (){donjon.entityGoTo(Vector2(-6.5, .96), dir: 3);};
        objects.add(ObjectClicked("DonjonScreen.DoorWest", "", call, null));
      }
    }

    return objects;
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

    sprite = Sprite(ImagesUtils.getImage("salle.png"));
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
      porteSud.sprite = Sprite(ImagesUtils.getImage("porte_sud.png"));
      porteSud.size = Vector2(130, 28);
      porteSud.anchor = Anchor.bottomCenter;
      porteSud.position = Vector2(size.x /2, size.y);
      await addChild(porteSud, gameRef: gameRef);

      if(donjon.currentSalle.s != null)
      {
        arrowSud = SpriteComponent();
        arrowSud!.sprite = Sprite(ImagesUtils.getImage('arrow.png'));
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
      porteNord.sprite = Sprite(ImagesUtils.getImage("porte_nord.png"));
      porteNord.size = Vector2(130, 95);
      porteNord.anchor = Anchor.topCenter;
      porteNord.position = Vector2(size.x / 2, 0);
      await addChild(porteNord, gameRef: gameRef);

      arrowNord = SpriteComponent();
      arrowNord!.sprite = Sprite(ImagesUtils.getImage('arrow.png'));
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
      porteOuest.sprite = Sprite(ImagesUtils.getImage("porte_ouest.png"));
      porteOuest.size = Vector2(43, 130);
      porteOuest.anchor = Anchor.centerLeft;
      porteOuest.position = Vector2(0, size.y / 2);
      await addChild(porteOuest, gameRef: gameRef);

      arrowOuest = SpriteComponent();
      arrowOuest!.sprite = Sprite(ImagesUtils.getImage('arrow.png'));
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
      porteEst.sprite = Sprite(ImagesUtils.getImage("porte_ouest.png"));
      porteEst.size = Vector2(43, 130);
      porteEst.anchor = Anchor.centerRight;
      porteEst.renderFlipX = true;
      porteEst.position = Vector2(size.x, size.y / 2);
      await addChild(porteEst, gameRef: gameRef);

      arrowEst = SpriteComponent();
      arrowEst!.sprite = Sprite(ImagesUtils.getImage('arrow.png'));
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
    List<Vector2> already = [];
    for(Entity e in server.entities)
    {
      if(e.getClan() != Storage.entity.getClan())
      {
        EntityComponent ennemy = EntityComponent(container.gameRef, e, getEntityPosition);
        EntityInfos infos = EntityInfos(e);
        infos.position = Vector2(container.gameRef.size.x - 60 -(indexEnnemy * (infos.size.x + 5)), 20);
        print("createbar ${infos.position} $indexEnnemy");
        container.infos[e.uuid] = infos;
        Vector2 newPosition = randomEnnemyPosition(already);
        already.add(newPosition);
        EntityFight ennemyF = EntityFight(e, ennemy, infos, newPosition);
        entities[e.uuid] = ennemyF;
        ennemy.face(player.position.x - ennemyF.position.x);
        if(indexEnnemy == 1)
        {
          entities.values.forEach((element) { 
            if(element.entity.getClan() == 1)
              element.component.face(-player.position.x + ennemyF.position.x);
          });
        }
        await container.addWithGameRef(ennemy);
        
        indexEnnemy++;
      } 
    }

    await Future.delayed(const Duration(milliseconds: 100));
    if(Storage.entity.nbCombat <= 0)
    {
      startTutorielSettings();
    }
    else if(Storage.entity.nbCombat == 1)
    {
      startTutorielManyEnnemies();
    }
    else
    {
      onEndTutoriel();
    }
    //onEndTutoriel();
    print("Fight.start.end");
  }

  Vector2 randomEnnemyPosition(List<Vector2> already)
  {
    int nbW = 10;
    double w = DonjonEntity.Width / nbW;

    int nbH = 6;
    double h = DonjonEntity.Height / nbH;

    Vector2 p = Vector2.copy(container.donjon.entityPosition) - Vector2(DonjonEntity.minX, DonjonEntity.minY);
    int i = p.x ~/ w;
    int j = p.y ~/ h;
    int eI = -1;
    int eJ = -1;
    int marge = 4;
    print("POSITION $i $j");
    while(eI < 0 || eI > nbW - 1)
      eI = i + Random().nextInt(2 * marge) - marge;
    print("POSITION EI $eI");
    int diff = (marge - (eI - i).abs()) ~/ 2;
    print("POSITION DIFF $diff");
    while(eJ < 0 || eJ > nbH - 1)
      eJ = j + diff * (Random().nextBool() ? -1 : 1); 
    print("POSITION EJ $eJ");
    Vector2 result = Vector2(eI * w + DonjonEntity.minX, eJ * h + DonjonEntity.minY);
    if(already.contains(result))
      return randomEnnemyPosition(already);
    return result;
  }

  void onEndTutoriel() async
  {
    print("Fight.onEndTutoriel.start");
    for(Entity e in server.entities)
    {
      if(e.getClan() != Storage.entity.getClan())
      {
        print("updatebar ");
        EntityInfos infos = container.infos[e.uuid]!;
        await container.addToHud(infos, gameRef: container.gameRef);
        infos.updateBars(e);
      }
    }
    
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
    /*TextComponent txtFin = TextComponent(Language.finDev.str, textRenderer: TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.red, fontSize: 40)));
    txtFin.anchor = Anchor.center;
    txtFin.position = container.gameRef.size / 2;
    container.hud.addChild(txtFin, gameRef: container.gameRef);*/
    print("Fight.finish");

    // Remove les cadres des ennemis
    server.entities.forEach((element) { 
      if(element.getClan() != 1)
        container.infos[element.uuid]?.remove();
    });
  
    Storage.entity.nbCombat++;
    Storage.storeEntities();
  }

  void addEnnemies(BuilderServer builder)
  {
    Function hp = (){
      return Storage.entity.nbCombat == 0 ? 22 : 28;
    };

    Function atk = (){
      return Storage.entity.nbCombat == 0 ? 8 : 8;
    };

    int nbEnnemies = min(3, 1 + Storage.entity.nbCombat);
    for(int i = 0; i < nbEnnemies; i++)
    {
      Map values = {};
      values[VALUE.HP_MAX] = hp();
      values[VALUE.MP_MAX] = 0;
      values[VALUE.ATK] = atk();
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
  }

  void startTutorielSettings()
  {
    if(container.gameRef.tutorielScreen == null)
    {
      container.gameRef.startTutoriel(TutorielSettings(container.gameRef, container._buttonSettings, onEndTutoriel));
    }
  }

  void startTutorielManyEnnemies()
  {
    if(container.gameRef.tutorielScreen == null)
    {
      container.gameRef.startTutoriel(TutorielManyEnnemies(container.gameRef, container._buttonSettings, onEndTutoriel));
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

    wait(.02);
      steps.add(new Step((){callerComponent.moveToInitialPosition();}, () => callerComponent.targetPosition == null));

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
    this.component.setStatus(status);
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