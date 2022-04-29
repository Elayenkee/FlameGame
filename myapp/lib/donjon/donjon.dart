import 'dart:math';

import 'package:flame/components.dart';
import 'package:myapp/donjon/donjon_screen.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/world/world.dart';

class Donjon
{
  late final DonjonScreen _donjonScreen;
  late final DonjonEntity _donjonEntity;

  late final Salle start;

  void setScreen(DonjonScreen screen)
  {
    _donjonScreen = screen;
  }

  void update(double dt)
  {
    _donjonEntity._update(dt);
  }

  void entityGoTo(Vector2 target)
  {
    Position newPosition = Position.fromVector2(target);
    _donjonEntity._goTo(newPosition);
  }

  void _startFight()
  {
    print("Donjon.startFight");
    _donjonScreen.startFight();
  }

  void setPlayerListener(EntityListener listener)
  {
    _donjonEntity.listener = listener;
  }

  get entityPosition => _donjonEntity._position;

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["entity"] = _donjonEntity.toMap();
    map["salles"] = [];
    addSalleToMap(start, map, []);
    return map;
  }

  void addSalleToMap(Salle? salle, Map<String, dynamic> map, List<Salle> salles)
  {
    if(salle == null || salles.contains(salle))
      return;

    salles.add(salle);
    map["salles"].add(salle.toMap());
    addSalleToMap(salle.w, map, salles);
    addSalleToMap(salle.e, map, salles);
    addSalleToMap(salle.s, map, salles);
    addSalleToMap(salle.n, map, salles);
  }

  Donjon.fromMap(Map<String, dynamic>? map)
  {
    print("Donjon start");
    if(map != null)
    {
      _donjonEntity = DonjonEntity.fromMap(Storage.getEntity(), map["entity"]);
    }
    else
    {
      _donjonEntity = DonjonEntity(Storage.getEntity());
    }
    _donjonEntity._donjon = this;
    _donjonEntity._resetNext();
  }

  static void generate()
  {
    Donjon donjon = Generate().start();
    Storage.storeDonjon(donjon);
  }
}

class DonjonEntity
{
  late Donjon _donjon;
  Entity _entity;
  Position _position = Position(0, 5);
  Position? _target;
  final double _speed = 2.5;
  double _next = -1;

  EntityListener? listener;

  DonjonEntity(this._entity)
  {
    print("DonjonEntity.<init> : $_position");
  }

  void _resetNext()
  {
    _next = 1 + World.Rand.nextDouble() * 2;
  }

  void _goTo(Position p)
  {
    _target = p;
    double diffX = _target!.x - _position.x;
    print("DonjonEntity.goTo $p from $_position $diffX");
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
      print("DonjonEntity arrived at target $_target");
      _position = _target!;
      _target = null;
      listener?.onStopMove();
      Storage.storeDonjon(_donjon);
      return;
    }
    
    final v = Vector2(_target!.x - _position.x, _target!.y - _position.y)..normalize()..multiply(Vector2.all(max));
    _position.x += v.x;
    _position.y += v.y;
    
    /*_next -= dt;
    if(_next <= 0)
    {
      listener?.onStopMove();
      Storage.storeDonjon(_donjon);
      _resetNext();
      _target = null;
      _donjon._startFight();
    }*/
  }

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["position"] = _position.toMap();
    return map;
  }

  DonjonEntity.fromMap(this._entity, Map<String, dynamic> map)
  {
    _position = Position.fromMap(map["position"]);
    print("DonjonEntity.fromMap : $_position");
  }
}

class Salle
{
  final int id;
  final int i;
  final int j;

  Salle? w;
  Salle? e;
  Salle? s;
  Salle? n;

  late bool isStart;

  Salle(this.id, this.i, this.j, {bool isStart = false})
  {
    this.isStart = isStart;
  }

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["i"] = i;
    map["j"] = j;
    map["id"] = id;
    if(w != null)map["w"] = w!.id;
    if(n != null)map["n"] = n!.id;
    if(s != null)map["s"] = s!.id;
    if(e != null)map["e"] = e!.id;
    return map;
  }

  @override
  String toString()
  {
    return "[$id - $i - $j]";
  }
}

int countSalles(Salle? start, List<Salle> salles)
{
  if(start == null || salles.contains(start))
    return 0;

  salles.add(start);
  var nb = 1;
  nb += countSalles(start.e, salles);
  nb += countSalles(start.s, salles);
  nb += countSalles(start.w, salles);
  nb += countSalles(start.n, salles);
  return nb;  
}

int countLeaf(Salle? salle, List<Salle> salles)
{
  if(salle == null || salles.contains(salle))
    return 0;

  salles.add(salle);
  
  int nb = _isLeaf(salle) ? 1 : 0;
  nb += countLeaf(salle.e, salles);
  nb += countLeaf(salle.w, salles);
  nb += countLeaf(salle.s, salles);
  nb += countLeaf(salle.n, salles);
  return nb;
}

bool _isLeaf(Salle? salle)
{
  if(salle == null)
  {
    print("_isLeaf null");
    return false;
  }

  int count = 0;
  count += salle.e != null ? 1 : 0;
  count += salle.w != null ? 1 : 0;
  count += salle.s != null ? 1 : 0;
  count += salle.n != null ? 1 : 0;
  bool result = count == 1;
  return result;
}

class Generate
{
  static final minSalles = 15;
  static final maxSalles = 20;
  static final maxLeaf = 4;
  static final randomMax = .65;

  int idSalle = 1;
  late final Donjon donjon;
  final Random rnd = Random(3);
  final List<Salle> salles = [];

  final List<Salle> checked = [];
  int nbLeaf = 1;

  Donjon start()
  {
    donjon = Donjon.fromMap(null);
    donjon.start = Salle(idSalle++, 0, 0, isStart: true);

    int count = 0;
    int essai = 0;
    while(count < minSalles && essai < 50)
    {
      essai++;
      _generate(donjon.start);
      checked.clear();
      count = countSalles(donjon.start, []);
    }
    print("Generated $count $nbLeaf $essai");
    return donjon;
  }

  void _generate(Salle salle)
  {
    if(!salles.contains(salle))
      salles.add(salle);

    if(checked.contains(salle))
      return;
    
    checked.add(salle);

    // EST
    if(!stop())
    {
      if(!exists(salle.i + 1, salle.j))
      {
        if(rnd.nextDouble() > randomMax)
        {
          bool isLeaf = _isLeaf(salle);
          if(nbLeaf < maxLeaf || isLeaf)
          {
            if(!isLeaf)nbLeaf++;
            salle.e = Salle(idSalle++, salle.i + 1, salle.j);
            salle.e!.w = salle;
            print("Added ${salle.e} to ${salle} at E - $isLeaf");
            _generate(salle.e!);
          }
        }
      }
      else if(salle.e != null)
        _generate(salle.e!);
    }

    // WEST
    if(!stop())
    {
      if(!exists(salle.i - 1, salle.j))
      {
        if(rnd.nextDouble() > randomMax)
        {
          bool isLeaf = _isLeaf(salle);
          if(nbLeaf < maxLeaf || isLeaf)
          {
            if(!isLeaf)nbLeaf++;
            salle.w = Salle(idSalle++, salle.i - 1, salle.j);
            salle.w!.e = salle;
            print("Added ${salle.w} to ${salle} at W - $isLeaf");
            _generate(salle.w!);
          }
        }
      }
      else if(salle.w != null) 
        _generate(salle.w!);
    }

    //SOUTH
    if(!stop())
    {
      if(!exists(salle.i, salle.j - 1))
      {
        if(rnd.nextDouble() > randomMax)
        {
          bool isLeaf = _isLeaf(salle);
          if(nbLeaf < maxLeaf || isLeaf)
          {
            if(!isLeaf)nbLeaf++;
            salle.s = Salle(idSalle++, salle.i, salle.j - 1);
            salle.s!.n = salle;
            print("Added ${salle.s} to ${salle} at S - $isLeaf");
            _generate(salle.s!);
          }
        }
      }
      else if(salle.s != null)
        _generate(salle.s!);
    }

    //NORTH
    if(!stop())
    {
      if(!exists(salle.i, salle.j + 1))
      {
        if(rnd.nextDouble() > randomMax)
        {
          bool isLeaf = _isLeaf(salle);
          if(nbLeaf < maxLeaf || isLeaf)
          {
            if(!isLeaf)nbLeaf++;
            salle.n = Salle(idSalle++, salle.i, salle.j + 1);
            salle.n!.s = salle;
            print("Added ${salle.n} to ${salle} at N - $isLeaf");
            _generate(salle.n!);
          }
        }
      }
      else if(salle.n != null)
        _generate(salle.n!);
    }
  }

  bool stop()
  {
    int count = countSalles(donjon.start, []);
    return count >= maxSalles;
  }

  bool exists(int i, int j)
  {
    for(Salle salle in salles)
    {
      if(salle.i == i && salle.j == j)
      {
        return true;
      }  
    }
    return false;
  }
}