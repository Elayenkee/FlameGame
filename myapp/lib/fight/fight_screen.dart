import 'package:flutter/material.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/main.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils.dart';

class FightScreen extends AbstractScreen
{
  final Map mapComponents = Map();
  final Map mapAnimations = Map();

  final List<Story> stories = [];
  StoryAnimation? storyAnimation;

  FightScreen(GameLayout gameRef, Vector2 size):super(gameRef, "F", size);

  @override
  Future<void> onLoad() async 
  {
    print("FightScreen.onLoad");
    await super.onLoad();

    BuilderServer builder = BuilderServer();
    Storage.entities.forEach((element) {builder.addEntity(e:element);});
    addRandomEnemmy(builder);

    print("FightScreen.onLoad.build");
    Server server = builder.build();
    print("FightScreen.onLoad.builded");

    Story? story;
    do{
      story = server.next();
      if(story != null)
        stories.add(story);  
    } while (story != null && stories.length < 100);
    Storage.storeEntities();

    List<Entity> allies = server.getAllies();
    double xAllies = 150;
    double ecart = gameRef.size.y / (allies.length + 1);
    for(int i = 0; i < allies.length; i++)
    {
      Entity entity = allies[i];
      EntityComponent allie = EntityComponent(this, entity, xAllies, (i + 1) * ecart);
      add(allie);
      mapComponents[entity.uuid] = allie;
    }

    List<Entity> ennemies = server.getEnnemies();
    double xEnnemies = gameRef.size.x - 150;
    ecart = gameRef.size.y / (ennemies.length + 1);
    for(int i = 0; i < ennemies.length; i++)
    {
      Entity entity = ennemies[i];
      EntityComponent ennemy = EntityComponent(this, entity, xEnnemies, (i + 1) * ecart);
      add(ennemy);
      mapComponents[entity.uuid] = ennemy;
    }
    print("FightScreen.onLoaded : ${stories.length} stories");
  }

  @override
  void update(double dt) 
  {
    super.update(dt);

    if(storyAnimation != null)
    {
      storyAnimation!.update(dt);
      if(storyAnimation!.isFinished)
        storyAnimation = null;
    }

    if(stories.length > 0)
    {
      Story story = stories.removeAt(0);
      storyAnimation = StoryAnimation(this, story);
    }
    else
    {
      waitAndFinish(dt);
    }
  }

  EntityComponent getComponentByUUID(String uuid)
  {
    return mapComponents[uuid];
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
    builderBehaviour4.builderWork.work = Works.ATTACK;

    BuilderConditionGroup builderConditionGroup4 = builderBehaviour4.builderTargetSelector.builderConditionGroup;
    BuilderCondition builderCondition5 = builderConditionGroup4.addCondition();
    builderCondition5.setCondition(Conditions.NOT_EQUALS);
    builderCondition5.setParam(1, entity3);
    builderCondition5.setParam(2, VALUE.CLAN);

    BuilderTriFunction builderTriFunction4 = builderBehaviour4.builderTargetSelector.builderTriFunction;
    builderTriFunction4.tri = TriFunctions.LOWEST;
    builderTriFunction4.value = VALUE.HP;
  }

  double _waitAndFinish = 1;
  void waitAndFinish(double dt)
  {
    if(_waitAndFinish == 1)
      print("FightScreen.waitAndFinish");
    _waitAndFinish -= dt;
    if(_waitAndFinish <= 0 && _waitAndFinish > -1)
    {
      _waitAndFinish = -1;
      gameRef.startWorld();
    }
  }

  @override
  bool onClick(Vector2 p) 
  {
    return true;
  }
}

class StoryAnimation
{
  final FightScreen game;
  final Story story;
  bool isFinished = false;

  int indexCurrentEvent = -1;
  EventAnimation? eventAnimation;

  StoryAnimation(this.game, this.story);

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
        eventAnimation = EventAnimation(game, story.events[indexCurrentEvent]);
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
  final FightScreen game;
  final StoryEvent event;
  bool isFinished = false;

  List<Step> steps = [];
  Step? currentStep;

  double waiter = 0;

  EventAnimation(this.game, this.event);

  void start()
  {
    Utils.log(event.log);
    EntityComponent? callerComponent = getEntityComponent("caller");
    EntityComponent? targetComponent = getEntityComponent("target");
    
    if(callerComponent != null)
    {
      steps.add(new Step((){callerComponent.stepForward();}, () => callerComponent.targetPosition == null));
      wait(.2);
    }
    
    List<PositionComponent> toReset = [];
    if(event.values.containsKey("work"))
    {
      steps.add(new StepTrue(()
      {
        SpriteComponent sprite = game.mapAnimations[event.get("source") as String];
        sprite.position = targetComponent!.position - Vector2(0, 30);
        toReset.add(sprite);
      }));
    }

    if(event.values.containsKey("type"))
    {
      steps.add(new StepTrue(()
      {
        SpriteComponent sprite = game.mapAnimations[event.get("source") as String];
        sprite.position = targetComponent!.position - Vector2(0, 150);
        toReset.add(sprite);
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

        targetComponent.setHP();
      }));
    }

    // Reset positions
    wait(.5);
    steps.add(new StepTrue(()
    {
      for(PositionComponent c in toReset)
        c.position = Vector2.all(-100);
    }));

    if(callerComponent != null)
    {
      wait(.2);
      steps.add(new Step((){callerComponent.moveToInitialPosition();}, () => callerComponent.targetPosition == null));
    }

    wait(1);

    next();
  }

  EntityComponent? getEntityComponent(String type)
  {
    try
    {
      Map caller = event.get(type) as Map;
      if(caller.containsKey("uuid"))
      {
        String uuidCaller = caller["uuid"];
        EntityComponent callerComponent = game.getComponentByUUID(uuidCaller);
        callerComponent.setStatus(caller);
        return callerComponent;
      }
    }
    catch(e)
    {
      
    }
    return null;
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
}

class EntityComponent extends SpriteComponent
{
  final FightScreen game;
  final Entity entity;
  final double initialX;
  final double initialY;

  late final spriteDead;
  
  late final Vector2 positionForward;
  Vector2? targetPosition = null;

  //late final HealthBarComponent healthBar;
  //late final HealthBarComponent manaBar;

  Map? status;

  EntityComponent(this.game, this.entity, this.initialX, this.initialY)
  {
    this.x = initialX;
    this.y = initialY;
    positionForward = Vector2(entity.getClan() == 1 ? x + 200 : x - 200, y);
  }

  @override
  Future<void>? onLoad() async 
  {
    int clan = entity.getClan();
    //spriteDead = Sprite(game.images.fromCache('entity_dead.png'));
    //sprite = Sprite(game.images.fromCache(clan == 1 ? 'entity_warrior.png' : 'entity_orc.png'));
    size = Vector2(clan == 1 ? 94 : 120, clan == 1 ? 150 : 120);
    anchor = Anchor.bottomCenter;

    /*healthBar = HealthBarComponent(entity.getHPMax());
    healthBar.position.x = 120;
    healthBar.position.y = size.y - 120;
    addChild(healthBar);

    if(entity.getMPMax() > 0)
    {
      manaBar = HealthBarComponent(entity.getMPMax());
      manaBar.position.x = 140;
      manaBar.position.y = size.y - 120;
      manaBar.setColor(Colors.blue);
      addChild(manaBar);
    }*/

    return super.onLoad();
  }

  void setStatus(Map status)
  {
    this.status = status;
  }

  void moveToInitialPosition()
  {
    setTargetPosition(Vector2(initialX, initialY));
  }

  void stepForward()
  {
    setTargetPosition(positionForward);
  }

  void setTargetPosition(Vector2 targetPosition)
  {
    this.targetPosition = targetPosition;
  }

  @override
  void update(double dt)
  {
    if(targetPosition != null)
    {
      position.moveToTarget(targetPosition!, 10);
      double distance = position.distanceTo(targetPosition!);
      if(distance < 10)
        targetPosition = null;
    }

    super.update(dt);
  }

  void setHP()
  {
    int hp = status![VALUE.HP] as int;
    //healthBar.setHP(hp);
    if(hp <= 0)
      sprite = spriteDead;
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