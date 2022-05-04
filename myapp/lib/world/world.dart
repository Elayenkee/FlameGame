import 'dart:math';
import 'dart:core';
import 'package:flame/game.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/world/world_screen.dart';

class World
{
  static final Rand = new Random();

  late final WorldScreen _worldScreen;
  late final WorldEntity _worldEntity;

  double _time = 0;

  void setWorldScreen(WorldScreen worldScreen)
  {
    _worldScreen = worldScreen;
  }

  void update(double dt)
  {
    _time += dt;
    _worldEntity._update(dt);
  }

  void entityGoTo(Vector2 target)
  {
    Position newPosition = Position.fromVector2(target);
    newPosition.x += _worldEntity._position.x;
    newPosition.y += _worldEntity._position.y;
    _worldEntity._goTo(newPosition);
  }

  void _startFight()
  {
    print("World.startFight");
    _worldScreen.startFight();
  }

  void setPlayerListener(EntityListener listener)
  {
    _worldEntity.listener = listener;
  }

  get entityPosition => _worldEntity._position;

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["entity"] = _worldEntity.toMap();
    return map;
  }

  World.fromMap(Map<String, dynamic>? map)
  {
    print("World.fromMap.start");
    if(map != null)
    {
      print("World.fromMap.map");
      _worldEntity = WorldEntity.fromMap(Storage.entity, map["entity"]);
    }
    else
    {
      print("World.fromMap.null");
      _worldEntity = WorldEntity(Storage.entity);
    }
    _worldEntity._world = this;
    _worldEntity._resetNext();
    print("World.fromMap.end");
  }
}

class WorldEntity
{
  late World _world;
  Entity _entity;
  Position _position = Position(0, 0);
  Position? _target;
  final double _speed = 2.5;
  double _next = -1; 

  double timeDeplacement = 0;

  EntityListener? listener;

  WorldEntity(this._entity)
  {
    print("WorldEntity.<init> : $_position");
  }

  void _resetNext()
  {
    _next = 1 + World.Rand.nextDouble() * 2;
  }

  void _goTo(Position p)
  {
    timeDeplacement = _world._time;
    _target = p;
    double diffX = _target!.x - _position.x;
    print("WorldEntity.goTo $p from $_position $diffX");
    listener?.onStartMove(diffX);
  }

  void _update(double dt)
  {
    if(_target == null)
      return;
    
    final d = _position.distance(_target!);
    final max = _speed * dt;
    if(d < max)
    {
      print("WorldEntity arrived at target $_target in ${_world._time - timeDeplacement}");
      _position = _target!;
      _target = null;
      listener?.onStopMove();
      Storage.storeWorld(_world);
      return;
    }
    
    final v = Vector2(_target!.x - _position.x, _target!.y - _position.y)..normalize()..multiply(Vector2.all(max));
    _position.x += v.x;
    _position.y += v.y;
    //listener?.onPlayerMove(_position);
    
    _next -= dt;
    if(_next <= 0)
    {
      listener?.onStopMove();
      Storage.storeWorld(_world);
      _resetNext();
      _target = null;
      _world._startFight();
    }
  }

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["position"] = _position.toMap();
    return map;
  }

  WorldEntity.fromMap(this._entity, Map<String, dynamic> map)
  {
    _position = Position.fromMap(map["position"]);
    print("WorldEntity.fromMap : $_position");
  }
}

abstract class EntityListener
{
  void onStartMove(double dir);
  void onStopMove();
}

class Position
{
  double x = 0;
  double y = 0;

  Position(this.x, this.y);

  Map<String, dynamic> toMap()
  {
    return {"x":x, "y":y};
  }

  Position.fromMap(Map<String, dynamic> map)
  {
    x = map["x"];
    y = map["y"];
  }

  Position.fromVector2(Vector2 v)
  {
    x = v.x;
    y = v.y;
  }

  double distance(Position p)
  {
    final dx = p.x - x;
    final dy = p.y - y;
    return sqrt(pow(dx, 2) + pow(dy, 2));
  }

  @override
  String toString()
  {
    return "[$x, $y]";
  }
}
