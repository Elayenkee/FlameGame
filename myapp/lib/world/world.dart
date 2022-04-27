import 'dart:math';
import 'dart:core';
import 'package:flame/game.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/world/world_screen.dart';

class World
{
  static final Rand = new Random(0);

  final WorldScreen _worldScreen;

  final WorldEntity _worldEntity;

  double _time = 0;

  World(this._worldScreen, this._worldEntity)
  {
    print("World start");
    _worldEntity._world = this;
    _worldEntity._resetNext();
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

  WorldEntity(this._entity);

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["position"] = _position.toMap();
    return map;
  }

  WorldEntity.fromMap(this._entity, Map<String, dynamic> map)
  {
    _position = Position.fromMap(map["position"]);
  }

  void _resetNext()
  {
    _next = 2 + World.Rand.nextDouble() * 2;
  }

  void _goTo(Position p)
  {
    timeDeplacement = _world._time;
    print("WorldEntity.goTo $p from $_position");
    _target = p;
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
      return;
    }
    
    final v = Vector2(_target!.x - _position.x, _target!.y - _position.y)..normalize()..multiply(Vector2.all(max));
    _position.x += v.x;
    _position.y += v.y;
    
    _next -= dt;
    if(_next <= 0)
    {
      _resetNext();
      _target = null;
      _world._startFight();
    }
  }
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
