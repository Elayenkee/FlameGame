import 'dart:ui';
import 'package:flame/components.dart';
import 'package:flame/extensions.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils/images.dart';

class EntityComponent extends PositionComponent implements EntityListener
{
  final GameLayout gameRef;
  final Entity entity;
  final Function getEntityPosition;

  late final EntityAnimationComponent entityAnimationComponent;

  bool moving = false;

  EntityComponent(this.gameRef, this.entity, this.getEntityPosition):super(priority: 1);

  @override
  Future<void> onLoad() async 
  {
    print("EntityComponent.onLoad.start");
    await super.onLoad();
    entityAnimationComponent = createEntityAnimationComponent();
    size = entityAnimationComponent.size;
    await addChild(Shadow(Vector2(35, 10), Vector2(size.x / 2, size.y)));
    await addChild(entityAnimationComponent);
    anchor = Anchor.bottomCenter;
    onMove(force: true);
    print("EntityComponent.onLoad.end");
  }

  @override
  void onStartMove(double dir) 
  {
    moving = true;
    renderFlipX = dir < 0;
    entityAnimationComponent.animation = entityAnimationComponent.move;
  }

  @override
  void onStopMove() 
  {
    moving = false;
    entityAnimationComponent.animation = entityAnimationComponent.idle;
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

  EntityAnimationComponent createEntityAnimationComponent()
  {
    if(entity == Storage.entity)
    {
      return PlayerAnimationComponent();
    }
    return PlayerAnimationComponent();
  }
}

class EntityAnimationComponent extends SpriteAnimationComponent
{
  late final SpriteAnimation idle;
  late final SpriteAnimation move;

  EntityAnimationComponent(Vector2 size):super(size: size);
}

class PlayerAnimationComponent extends EntityAnimationComponent
{
  late final SpriteAnimation idle;
  late final SpriteAnimation move;
  
  PlayerAnimationComponent():super(Vector2(160, 95));
  
  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    final spriteSheet = await ImagesUtils.loadGUI("hero_knight.png");
    idle = spriteSheet.createAnimation(row: 0, stepTime: .1, from: 0, to: 6);
    final List<Sprite> runSprites = [];
    final List<Sprite> row0 = List<int>.generate(2, (i) => 8 + i).map((e) => spriteSheet.getSprite(0, e)).toList();
    runSprites.addAll(row0);
    final List<Sprite> row1 = List<int>.generate(8, (i) => 0 + i).map((e) => spriteSheet.getSprite(1, e)).toList();
    runSprites.addAll(row1);
    move = SpriteAnimation.spriteList(runSprites, stepTime: .06, loop: true);
    animation = idle;
  }
}

abstract class EntityListener
{
  void onStartMove(double dir);
  void onStopMove();
}

class Shadow extends PositionComponent 
{
  late final Rect rect;
  late final Paint paint;

  Shadow(Vector2 size, Vector2 position) : super(size: size) 
  {
    paint = Paint()..color = Color.fromARGB(178, 28, 26, 26);
    rect = Rect.fromLTWH(-size.x / 2 + position.x, -size.y + position.y, size.x, size.y);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawOval(rect, paint);
    super.render(canvas);
  }
}