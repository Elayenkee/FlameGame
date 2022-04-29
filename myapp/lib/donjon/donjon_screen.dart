import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/sprite.dart';
import 'package:myapp/donjon/donjon.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/world/world.dart';

class DonjonScreen extends AbstractScreen
{
  late final Donjon _donjon;
  late final Player _player;
  late final Decor _decor;

  DonjonScreen(Vector2 size):super("D", size);

  @override
  Future<void> onLoad() async 
  {
    print("DonjonScreen.onLoad");
    await super.onLoad();

    _decor = Decor(gameRef);
    add(_decor);

    _player = Player(this);
    add(_player);
    
    _donjon = Storage.getDonjon();
    _donjon.setScreen(this);
    _donjon.setPlayerListener(_player);

    _player.onMove(force: true);
    print("DonjonScreen.onLoaded");
  }

  void startFight()
  {
    print("DonjonScreen.startFight");
    gameRef.startFight();
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    _donjon.update(dt);
    if(!shouldRemove)
      _player.onMove();
  }

  void onClick(Vector2 p) 
  {
    final eClick = Vector2(p.x, p.y) - gameRef.size / 2;
    final click = eClick..divide(Vector2(50, 50));
    _donjon.entityGoTo(click);
  }

  @override
  void onRemove() 
  {
    print("DonjonScreen.onRemove");
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
    size = gameRef.size;
    print("Decor.onLoaded");
  }
}

class Player extends SpriteAnimationComponent with HasGameRef<GameLayout> implements EntityListener 
{
  final DonjonScreen _donjonScreen;
  late final GameLayout gameRef;
  late final SpriteAnimation idle;
  late final SpriteAnimation move;

  bool moving = false;

  Player(this._donjonScreen):super(priority: 1)
  {
    gameRef = _donjonScreen.gameRef;
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
    onMove(force: true);
    print("Player.onLoaded");
  }

  @override
  void onStartMove(double dir) 
  {
    moving = true;
    renderFlipX = dir < 0;
    animation = move;
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
    animation = idle;
  }

  @override
  void onRemove() 
  {
    print("Player.onRemove");
    super.onRemove();
  }
}