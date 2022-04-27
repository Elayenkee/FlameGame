import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/world/world.dart';

class WorldScreen extends AbstractScreen with Tappable, HasGameRef<GameLayout>
{
  late final World _world;

  WorldScreen(Vector2 size):super("W", size);

  @override
  Future<void> onLoad() async 
  {
    print("WorldScreen.onLoad");
    super.onLoad();
    _world = Storage.getWorld();
    _world.setWorldScreen(this);
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
  }

  @override
  bool onTapDown(TapDownInfo event) 
  {
    return true;
  }

  @override
  bool onTapUp(TapUpInfo event) 
  {
    final eClick = Vector2(event.eventPosition.game.x - 350, event.eventPosition.game.y - 250);
    final click = eClick..divide(Vector2(50, 50));
    _world.entityGoTo(click);
    return true;
  }

  @override
  bool onTapCancel() 
  {
    print("tap cancel");
    return true;
  }
}