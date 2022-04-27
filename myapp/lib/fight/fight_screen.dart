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

class FightScreen extends AbstractScreen with Tappable, HasGameRef<GameLayout>
{
  final List<Story> stories = [];

  FightScreen(Vector2 size):super("F", size);

  @override
  Future<void> onLoad() async 
  {
    print("FightScreen.onLoad");
    super.onLoad();

    Entity entity = Storage.getEntity();

    //TODO REMOVE
    //entity.addHP(1000);

    BuilderServer builder = BuilderServer();
    builder.addEntity(e:entity);
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
    Storage.storeEntity(entity);
    print("FightScreen.onLoaded : ${stories.length} stories");
  }

  @override
  void update(double dt) 
  {
    super.update(dt);

    if(stories.length > 0)
    {
      Story story = stories.removeAt(0);
      story.events.forEach((event) {
        Utils.log(event.log);
      });
    }
    else
    {
      waitAndFinish(dt);
    }
  }

  @override
  bool onTapDown(TapDownInfo event) 
  {
    return true;
  }

  @override
  bool onTapUp(TapUpInfo event) 
  {
    return true;
  }

  @override
  bool onTapCancel() 
  {
    return true;
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
}