import 'dart:math';
import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils/images.dart';
import 'package:myapp/works/work.dart';

class EntityComponent extends PositionComponent implements EntityListener
{
  final GameLayout gameRef;
  final Entity entity;
  final Function getEntityPosition;

  late final EntityAnimationComponent entityAnimationComponent;

  bool moving = false;
  WorkAnimation? workAnimation;

  EntityComponent(this.gameRef, this.entity, this.getEntityPosition):super(priority: 1)
  {
    entityAnimationComponent = createEntityAnimationComponent();
  }

  @override
  Future<void> onLoad() async 
  {
    print("EntityComponent.onLoad.start");
    await super.onLoad();
    size = entityAnimationComponent.size;
    await addChild(entityAnimationComponent);
    anchor = Anchor.bottomCenter;
    onMove(force: true);
    print("EntityComponent.onLoad.end");
  }

  @override
  void onStartMove(double dir) 
  {
    moving = true;
    entityAnimationComponent.animation = entityAnimationComponent.move;
    if(dir != 0)
      entityAnimationComponent.renderFlipX = dir < 0;
  }

  @override
  void onStopMove() 
  {
    moving = false;
    entityAnimationComponent.animation = entityAnimationComponent.idle;
  }

  void face(double dir)
  {
    print("EntityComponent.face $dir ${entity}");
    if(dir != 0)
      entityAnimationComponent.renderFlipX = dir < 0;
  }

  void onMove({bool force = false})
  {
    if(moving || force)
    {
      Vector2 entityPosition = getEntityPosition(entity);
      position = Vector2(entityPosition.x, entityPosition.y) * 50;
      position += gameRef.size / 2;
    }
  }

  void onHit()
  {
    if(entityAnimationComponent.animation != entityAnimationComponent.death)
      entityAnimationComponent.animation = entityAnimationComponent.hit;
  }

  void setStatus(Map status)
  {
    int hp = status[VALUE.HP];
    if(hp <= 0 && entityAnimationComponent.animation != entityAnimationComponent.death)
    {
      entityAnimationComponent.death.reset();
      entityAnimationComponent.previous = entityAnimationComponent.death;
      entityAnimationComponent.animation = entityAnimationComponent.death;
    }
  }

  @override
  void update(double dt)
  {
    super.update(dt);
    onMove();
    workAnimation?.update();
    if(workAnimation != null && workAnimation!.isFinished)
      workAnimation = null;
    if(entityAnimationComponent.animation == entityAnimationComponent.death)
    {
      int index = entityAnimationComponent.animation!.currentIndex + 1;
      int length = entityAnimationComponent.animation!.frames.length; 
      int a = index * 255;
      int alpha = 255 - a ~/ length;
      entityAnimationComponent.alpha = alpha;
      if(alpha <= 0)
        entityAnimationComponent.animation = null;
    }
  }

  WorkAnimation work(Work work)
  {
    workAnimation = WorkAnimation(this, work);
    return workAnimation!;
  }

  EntityAnimationComponent createEntityAnimationComponent()
  {
    if(entity == Storage.entity)
    {
      return PlayerAnimationComponent(gameRef);
    }
    return EnnemyAnimationComponent(gameRef);
  }
}

class EntityAnimationComponent extends SpriteAnimationComponent
{
  final GameLayout gameRef;
  late final SpriteAnimation idle;
  late final SpriteAnimation move;
  late final SpriteAnimation attack;
  late final SpriteAnimation hit;
  late final SpriteAnimation death;

  SpriteAnimation? previous;

  EntityAnimationComponent(this.gameRef,  size):super(size: size);

  @override
  void update(double dt)
  {
    super.update(dt);
    if(animation == hit && animation!.currentIndex >= hit.frames.length - 1)
    {
      hit.reset();
      animation = previous ?? idle;
    }  
  }

  set alpha(int alpha)
  {
    overridePaint = BasicPalette.white.withAlpha(alpha).paint();
  }
}

class PlayerAnimationComponent extends EntityAnimationComponent
{
  PlayerAnimationComponent(GameLayout gameRef):super(gameRef, Vector2(160, 95));
  
  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    final spriteSheet = ImagesUtils.getGUI("hero_knight.png");
    idle = spriteSheet.createAnimation(row: 0, stepTime: .1, from: 0, to: 6);

    final List<Sprite> runSprites = [];
    final List<Sprite> row0 = List<int>.generate(2, (i) => 8 + i).map((e) => spriteSheet.getSprite(0, e)).toList();
    runSprites.addAll(row0);
    final List<Sprite> row1 = List<int>.generate(8, (i) => 0 + i).map((e) => spriteSheet.getSprite(1, e)).toList();
    runSprites.addAll(row1);
    move = SpriteAnimation.spriteList(runSprites, stepTime: .06, loop: true);
    
    final List<Sprite> attackSprites = [];
    final List<Sprite> aRow0 = List<int>.generate(2, (i) => 8 + i).map((e) => spriteSheet.getSprite(1, e)).toList();
    attackSprites.addAll(aRow0);
    final List<Sprite> aRow1 = List<int>.generate(4, (i) => 0 + i).map((e) => spriteSheet.getSprite(2, e)).toList();
    attackSprites.addAll(aRow1);
    attack = AttackAnimation.spriteList(attackSprites, .06, 2);

    hit = spriteSheet.createAnimation(row: 4, stepTime: .12, from: 5, to: 8);

    death = spriteSheet.createAnimation(row: 0, stepTime: .1, from: 0, to: 6);
    death.loop = false;

    animation = idle;

    await addChild(Shadow(Vector2(35, 10), Vector2(size.x / 2, size.y)));
  }
}

class EnnemyAnimationComponent extends EntityAnimationComponent
{
  late SpriteAnimationComponent? animApparition;
  late final Shadow shadow;

  EnnemyAnimationComponent(GameLayout gameRef):super(gameRef, Vector2(180, 90));

  @override
  Future<void> onLoad() async 
  {
    //print("EnnemyAnimationComponent.onLoad.start");
    await super.onLoad();
    SpriteSheet sheetApparition = ImagesUtils.getGUI("smoke_2.png");
    animApparition = SpriteAnimationComponent();
    animApparition!.size = Vector2.all(size.y / 2);
    animApparition!.anchor = Anchor.center;
    animApparition!.position = size / 2;
    animApparition!.animation =sheetApparition.createAnimation(row: 0, stepTime: .078, from: 0, to: 9);
    
    SpriteSheet sheetIdle = ImagesUtils.getGUI("bat_idle.png");
    idle = sheetIdle.createAnimation(row: 0, stepTime: .08, from: 0, to: 8);
    idle.currentIndex = Random().nextInt(idle.frames.length);
    move = idle;

    SpriteSheet sheetAttack = ImagesUtils.getGUI("bat_attack.png");
    List<Sprite> sprites = List<int>.generate(9, (i) => 0 + i).map((e) => sheetAttack.getSprite(0, e)).toList();
    attack = AttackAnimation.spriteList(sprites, .06, 6);

    SpriteSheet sheetHit = ImagesUtils.getGUI("bat_hit.png");
    hit = sheetHit.createAnimation(row: 0, stepTime: .1, from: 0, to: 4);

    SpriteSheet sheetDeath = ImagesUtils.getGUI("bat_death.png");
    death = sheetDeath.createAnimation(row: 0, stepTime: .08, from: 0, to: 4);
    death.loop = false;

    animation = idle;
    apparition();
    //print("EnnemyAnimationComponent.onLoad.end $animApparition");
  }

  void apparition()
  {
    addChild(animApparition!, gameRef: gameRef);
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    if(animApparition != null && animApparition!.animation!.currentIndex == 7)
    {
      animApparition!.remove();
      animApparition = null;
      shadow = Shadow(Vector2(35, 10), Vector2(size.x / 2, size.y - 10));
      addChild(shadow, gameRef: gameRef);
    }  
  }

  set alpha(int alpha)
  {
    shadow.alpha = alpha;
    overridePaint = BasicPalette.white.withAlpha(alpha).paint();
  }
}

class AttackAnimation extends SpriteAnimation
{
  final int frameHit;

  AttackAnimation.spriteList(List<Sprite> sprites, double stepTime, this.frameHit):super.spriteList(sprites, stepTime: stepTime);
}

class WorkAnimation
{
  final EntityComponent entityComponent;
  final Work work;

  Function? onEvent;

  bool isFinished = false;

  WorkAnimation(this.entityComponent, this.work);

  void start()
  {
    if(work == Work.attaquer)
    {
      entityComponent.entityAnimationComponent.attack.reset();
      entityComponent.entityAnimationComponent.animation = entityComponent.entityAnimationComponent.attack;
      return;
    }
    isFinished = true;
  }

  void update()
  {
    SpriteAnimation animation = entityComponent.entityAnimationComponent.animation!; 
    if(animation.isLastFrame)
    {
      entityComponent.entityAnimationComponent.animation = entityComponent.entityAnimationComponent.idle;
      isFinished = true;
    }
    else if(onEvent != null)
    {
      if(work == Work.attaquer)
      {
        if(animation is AttackAnimation)
        {
          if(animation.currentIndex == animation.frameHit)
          {
            onEvent!.call(WorkEvent.HIT);
          }
        }
      }
    }
  }
}

enum WorkEvent
{
  HIT
}

abstract class EntityListener
{
  void onStartMove(double dir);
  void onStopMove();
}

class Bar extends SpriteComponent
{
  final String type;
  late final SpriteComponent content;

  Bar(this.type)
  {
    content = SpriteComponent();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    sprite = Sprite(ImagesUtils.getImage("bar.png"));
    size = Vector2(90, 9);

    content.sprite = Sprite(ImagesUtils.getImage(type));
    content.position = Vector2(2.5, 2);
    await addChild(content);
  }

  void setValue(double value, double max)
  {
    double v = (85 * value) / max;
    content.size = Vector2(v, 5);
  }
}

class EntityInfos extends SpriteComponent
{
  late final TextComponent txtName;
  late final Bar healthBar;
  Bar? manaBar = null;

  late final String imageCadre;

  EntityInfos(Entity entity)
  {
    imageCadre = entity.getClan() == 1 ? "button_work.png" : "button_ennemy.png";
    size = Vector2(100, 35);
    txtName = TextComponent(entity.getName(), textRenderer: TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white, fontSize: 20)));
    txtName.position = Vector2(size.x / 2, -5);
    txtName.anchor = Anchor.topCenter;
    healthBar = Bar("health.png");
    healthBar.position = Vector2(5, 15);

    if(entity.getMPMax() > 0)
    {
      manaBar = Bar("mana.png");
      manaBar!.position = Vector2(5, 25);
    }
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    Sprite spriteCadre = Sprite(ImagesUtils.getImage(imageCadre));
    spriteCadre.paint = BasicPalette.blue.withAlpha(200).paint(); 
    SpriteComponent cadre = SpriteComponent(sprite: spriteCadre);
    cadre.size = Vector2(100, 35);
    await addChild(cadre);
    await addChild(txtName);
    await addChild(healthBar);
    if(manaBar != null)
      await addChild(manaBar!);
  }

  void updateBars(Entity entity)
  {
    int hp = entity.getHP();
    int hpMax = entity.getHPMax();
    int mp = entity.getMP();
    int mpMax = entity.getMPMax();
    healthBar.setValue(hp.toDouble(), hpMax.toDouble());
    manaBar?.setValue(mp.toDouble(), mpMax.toDouble());
    print("EntityInfos.updateBars.end $entity");
  }

  void setStatus(Map status)
  {
    int hp = status[VALUE.HP];
    int hpMax = status[VALUE.HP_MAX];
    int mp = status[VALUE.MP];
    int mpMax = status[VALUE.MP_MAX];
    healthBar.setValue(hp.toDouble(), hpMax.toDouble());
    manaBar?.setValue(mp.toDouble(), mpMax.toDouble());
  }
}

class Shadow extends PositionComponent 
{
  late final Rect rect;
  late Paint paint;

  Shadow(Vector2 size, Vector2 position) : super(size: size) 
  {
    paint = Paint()..color = Color.fromARGB(178, 28, 26, 26);
    rect = Rect.fromLTWH(-size.x * .6 + position.x, -size.y + position.y, size.x, size.y);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawOval(rect, paint);
    super.render(canvas);
  }

  set alpha(int alpha)
  {
    paint = Paint()..color = Color.fromARGB(alpha, 28, 26, 26);
  }
}