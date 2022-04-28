import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/world/world.dart';

class WorldScreen extends AbstractScreen
{
  late final World _world;
  late final Player _player;
  late final Decor _decor;

  WorldScreen(Vector2 size):super("W", size);

  @override
  Future<void> onLoad() async 
  {
    print("WorldScreen.onLoad");
    await super.onLoad();

    _decor = Decor(gameRef);
    add(_decor);

    _player = Player(this);
    add(_player);
    
    _world = Storage.getWorld();
    _world.setWorldScreen(this);
    _world.setPlayerListener(_player);

    Position entityPosition = _world.entityPosition;
    _decor.position = Vector2(entityPosition.x, entityPosition.y)..multiply(Vector2.all(-50));
    print("WorldScreen.onLoaded");
  }

  void startFight()
  {
    print("WorldScreen.startFight");
    gameRef.startFight();
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    _world.update(dt);
    if(!shouldRemove)
      _player.onMove();
  }

  void onClick(Vector2 p) 
  {
    final eClick = Vector2(p.x - 425, p.y - 250);
    final click = eClick..divide(Vector2(50, 50));
    _world.entityGoTo(click);
  }

  @override
  void onRemove() 
  {
    print("WorldScreen.onRemove");
    super.onRemove();
  }
}

class Decor extends SpriteComponent with HasGameRef<GameLayout>
{
  final GameLayout gameRef;

  Decor(this.gameRef):super(priority: 0);

  @override
  Future<void> onLoad() async 
  {
    print("Decor.onLoad");
    await super.onLoad();
    sprite = Sprite(await Images().load("plaine.png"));
    size = Vector2(618, 618);
    print("Decor.onLoaded");
  }
}

class Player extends SpriteAnimationComponent with HasGameRef<GameLayout> implements EntityListener 
{
  final WorldScreen _worldScreen;
  late final GameLayout gameRef;
  late final SpriteAnimation idle;
  late final SpriteAnimation move;

  bool moving = false;

  Player(this._worldScreen):super(priority: 1)
  {
    gameRef = _worldScreen.gameRef;
  }

  @override
  Future<void> onLoad() async 
  {
    print("Player.onLoad");
    await super.onLoad();
    final spriteSheet = SpriteSheet(image: await Images().load("hero_knight.png"), srcSize: Vector2(100, 55));
    idle = spriteSheet.createAnimation(row: 0, stepTime: .15, from: 0, to: 7);
    final List<Sprite> runSprites = [];
    final List<Sprite> row0 = List<int>.generate(2, (i) => 8 + i).map((e) => spriteSheet.getSprite(0, e)).toList();
    runSprites.addAll(row0);
    final List<Sprite> row1 = List<int>.generate(8, (i) => 0 + i).map((e) => spriteSheet.getSprite(1, e)).toList();
    runSprites.addAll(row1);
    move = SpriteAnimation.spriteList(runSprites, stepTime: .075, loop: true);
    animation = idle;
    size = Vector2(150, 82.5);
    anchor = Anchor.bottomCenter;
    position = gameRef.size / 2;
    print("Player.onLoaded");
  }

  @override
  void onStartMove(double dir) 
  {
    moving = true;
    renderFlipX = dir < 0;
    animation = move;
  }

  void onMove()
  {
    if(moving)
    {
      Position entityPosition = _worldScreen._world.entityPosition;
      _worldScreen._decor.position = Vector2(entityPosition.x, entityPosition.y)..multiply(Vector2.all(-50));
    }
  }

  @override
  void onStopMove() 
  {
    moving = false;
    animation = idle;
  }

  @override
  void onRemove() 
  {
    print("Player.onRemove");
    super.onRemove();
  }
}