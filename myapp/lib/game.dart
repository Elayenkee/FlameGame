import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:myapp/main.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/valuesolver.dart';

class GameScreen extends StatelessWidget
{
  final Server server;
  late final GameLayout game;

  GameScreen(this.server);

  @override
  Widget build(BuildContext context) 
  {
    return GameWidget(game: GameLayout(server));
  }
}

class GameLayout extends AbstractLayout
{
  final Server server;

  late final TextComponent damage;

  bool paused = false;
  StoryAnimation? storyAnimation = null;

  Map mapComponents = Map();
  Map mapAnimations = Map();

  GameLayout(this.server)
  {
    server.init();
  }

  @override
  Future<void> onLoad() async
  {
    viewport = FixedResolutionViewport(Vector2(840, 500));

    await images.load('entity_dead.png');
    await images.load('entity_warrior.png');
    await images.load('entity_orc.png');
    loadAnimation('sword');
    loadAnimation('heal');
    loadAnimation('work_poison');
    loadAnimation('dot_poison');
    loadAnimation('work_bleed');
    loadAnimation('dot_bleed');
    
    damage = TextComponent("", priority: 1000);
    damage.anchor = Anchor.bottomCenter;
    damage.position = Vector2.all(-100);
    add(damage);

    List<Entity> allies = server.getAllies();
    double xAllies = 150;
    double ecart = size.y / (allies.length + 1);
    for(int i = 0; i < allies.length; i++)
    {
      Entity entity = allies[i];
      EntityComponent allie = EntityComponent(this, entity, xAllies, (i + 1) * ecart);
      add(allie);
      mapComponents[entity.uuid] = allie;
    }

    List<Entity> ennemies = server.getEnnemies();
    double xEnnemies = size.x - 150;
    ecart = size.y / (ennemies.length + 1);
    for(int i = 0; i < ennemies.length; i++)
    {
      Entity entity = ennemies[i];
      EntityComponent ennemy = EntityComponent(this, entity, xEnnemies, (i + 1) * ecart);
      add(ennemy);
      mapComponents[entity.uuid] = ennemy;
    }

    return super.onLoad();
  }

  Future<void> loadAnimation(String name) async
  {
    await images.load("$name.png");
    SpriteComponent sprite = SpriteComponent(sprite: Sprite(images.fromCache("$name.png")), priority: 1000);
    sprite.anchor = Anchor.bottomCenter;
    sprite.size = Vector2.all(60);
    sprite.position = Vector2.all(-100);
    add(sprite);
    mapAnimations[name] = sprite;
  }

  @override
  void render(Canvas canvas) 
  {
    //super.render(canvas);
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
    
    if(paused || storyAnimation != null || server.finished)
      return;

    Story? story = server.next();
    if(story != null)
    {
        //print("Story : ${story.events.length}");
        storyAnimation = StoryAnimation(this, story);
    }
  }

  EntityComponent getComponentByUUID(String uuid)
  {
    return mapComponents[uuid];
  }

  @override
  Color backgroundColor() => const Color(0xFFFFFFFF);
}

class StoryAnimation
{
  final GameLayout game;
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
  final GameLayout game;
  final StoryEvent event;
  bool isFinished = false;

  List<Step> steps = [];
  Step? currentStep;

  double waiter = 0;

  EventAnimation(this.game, this.event);

  void start()
  {
    print(event.log);
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
        if(event.has("damage"))
        {
          int value = event.get("damage") as int;
          game.damage.position = targetComponent.position - Vector2(0, 120);
          game.damage.text = "$value";
          game.damage.textRenderer = TextPaint(config: TextPaintConfig(color: value < 0 ? Colors.red : Colors.green));
          toReset.add(game.damage);
        }

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
  final GameLayout gameLayout;
  final Entity entity;
  final double initialX;
  final double initialY;

  late final spriteDead;
  
  late final Vector2 positionForward;
  Vector2? targetPosition = null;

  late final HealthBarComponent healthBar;
  late final HealthBarComponent manaBar;

  Map? status;

  EntityComponent(this.gameLayout, this.entity, this.initialX, this.initialY)
  {
    this.x = initialX;
    this.y = initialY;
    positionForward = Vector2(entity.getClan() == 1 ? x + 200 : x - 200, y);
  }

  @override
  Future<void>? onLoad() async 
  {
    int clan = entity.getClan();
    spriteDead = Sprite(gameLayout.images.fromCache('entity_dead.png'));
    sprite = Sprite(gameLayout.images.fromCache(clan == 1 ? 'entity_warrior.png' : 'entity_orc.png'));
    size = Vector2(clan == 1 ? 94 : 120, clan == 1 ? 150 : 120);
    anchor = Anchor.bottomCenter;

    healthBar = HealthBarComponent(entity.getHPMax());
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
    }

    return super.onLoad();
  }

  void setStatus(Map status)
  {
    //print("setStatus :: $status");
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
    //print("setHP :: $status");
    int hp = status![VALUE.HP] as int;
    healthBar.setHP(hp);
    if(hp <= 0)
      sprite = spriteDead;
  }
}

class HealthBarComponent extends PositionComponent
{
  final double w = 18;
  final double h = 120;
  final int max;

  late final Rect bgRect;
  late final Paint bgPaint;

  late Rect hpRect;
  late final Paint hpPaint;
  MaterialColor hpColor = Colors.green;


  HealthBarComponent(this.max);

  @override
  Future<void>? onLoad() async 
  {
    bgRect = hpRect = Rect.fromLTWH(0, 0, w, h);
    bgPaint = Paint()..color = Colors.black;
    hpPaint = Paint()..color = hpColor;
    return super.onLoad();
  }

  void setColor(MaterialColor color)
  {
    this.hpColor = color;
  }

  void setHP(int current)
  {
    current = current < 0 ? 0 : current;
    double height = (h * current) / max;
    hpRect = Rect.fromLTWH(0, 120 - height, w, height);
  }

  @override
  void render(Canvas canvas) 
  {
    super.render(canvas);

    canvas.drawRect(bgRect, bgPaint);
    canvas.drawRect(hpRect, hpPaint);
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