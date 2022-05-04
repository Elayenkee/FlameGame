import 'dart:math';

import 'package:flame/components.dart';

class Topology
{
  List<Vector2> vertices = [];
  List<Triangle> triangles = [];

  List<Vector2> closed = [];
  List<Vector2> opened = [];
  Map<Vector2, double> g = {};
  Map<Vector2, double> h = {};
  Map<Vector2, Vector2> parents = {};

  /*Topology.fromExample()
  {
    _addVertex(0, 0);
    _addVertex(50, 0);
    _addVertex(0, 300);
    _addVertex(50, 200);
    _addVertex(800, 300);
    _addVertex(850, 200);
    _addVertex(800, 500);
    _addVertex(850, 500);

    _addTriangle(0, 1, 3);
    _addTriangle(0, 3, 2);
    _addTriangle(2, 3, 4);
    _addTriangle(3, 5, 4);
    _addTriangle(4, 5, 7);
    _addTriangle(4, 7, 6);
  }*/

  List<Vector2> pathTo(Vector2 start, Vector2 goal)
  {
    g = {};
    h = {};
    parents = {};
    g[start] = 0;
    h[start] = _distance(start, goal);
    parents[start] = start;
    closed = [];
    opened = [];
    
    Vector2 newStart = Vector2.copy(start);
    while(newStart != goal)
    {
      //print("==================");
      //print("Traitement Closed $newStart - $closed");
      closed.add(newStart);
      List<Vector2> adjacents = adjacentPoints(newStart);
      for(Vector2 a in adjacents)
      {
        if(closed.contains(a))
          continue;

        //print("     >>>>>>>>>>>>>>>>>>");
        //print("     Traitement Adjacent $a");
        double newG = g[newStart]! + _distance(newStart, a);
        if(opened.contains(a))
        {
          if(newG < g[a]!)
          {
            g[a] = newG;
            h[a] = _distance(a, goal);  
            parents[a] = newStart;
            //print("     G is now $newG");
            //print("     Parent is now ${parents[a]}");
          }
          else
          {
            //print("     Deja fait $newG < ${g[a]}");
            continue;
          }
        }
        else
        {
          opened.add(a);
          g[a] = newG;
          h[a] = _distance(a, goal);  
          parents[a] = newStart;
          //print("     Add $a to opened with G = ${g[a]} and parent = $newStart");
        }
        //print("     <<<<<<<<<<<<<<<<<<");
      }
      
      double fMin = 10000;
      for(Vector2 p in opened)
      {
        final f = g[p]! + h[p]!;
        if(f < fMin)
        {
          newStart = p;
          fMin = f;
        }
      }

      //print("NewStart is $newStart");
      opened.remove(newStart);
    }
    
    List<Vector2> result = [];
    while(newStart != start)
    {
      result.add(newStart);
      newStart = parents[newStart]!;
    }
    result.add(start);
    return new List.from(result.reversed);
  }

  List<Vector2> adjacentPoints(Vector2 point)
  {
    for(Triangle triangle in triangles)
    {
      if(pointInTriangle(point, triangle))
      {
        if(point == triangle.a || point == triangle.b || point == triangle.c)
        {
          List<Vector2> all = [];
          for(Triangle t in triangles)
          {
            if(t.a == point || t.b == point || t.c == point)
            {
              if(!all.contains(t.a))
                all.add(t.a);
              if(!all.contains(t.b))
                all.add(t.b);
              if(!all.contains(t.c))
                all.add(t.c);
            }
          }
          all.remove(point);
          return all;
        }
        return [triangle.a, triangle.b, triangle.c];
      }
    }
    return [];
  }

  bool pointInTriangle (Vector2 point, Triangle triangle)
  {
    final det = (triangle.b.x - triangle.a.x) * (triangle.c.y - triangle.a.y) - (triangle.b.y - triangle.a.y) - (triangle.c.x - triangle.a.x);
    final A = det * ((triangle.b.x - triangle.a.x) * (point.y - triangle.a.y) - (triangle.b.y - triangle.a.y) * (point.x - triangle.a.x)) >= 0;
    final B = det * ((triangle.c.x - triangle.b.x) * (point.y - triangle.b.y) - (triangle.c.y - triangle.b.y) * (point.x - triangle.b.x)) >= 0;
    final C = det * ((triangle.a.x - triangle.c.x) * (point.y - triangle.c.y) - (triangle.a.y - triangle.c.y) * (point.x - triangle.c.x)) >= 0;
    return A && B && C;
  }

  void _addVertex(double x, double y)
  {
    vertices.add(Vector2(x, y));
  }

  void _addTriangle(int i, int j, int k)
  {
    triangles.add(Triangle(vertices[i], vertices[j], vertices[k]));
  }

  double _distance(Vector2 a, Vector2 b)
  {
    final dx = b.x - a.x;
    final dy = b.y - a.y;
    return sqrt(pow(dx, 2) + pow(dy, 2));
  }
}

class Triangle
{
  Vector2 a;
  Vector2 b;
  Vector2 c;

  Triangle(this.a, this.b, this.c);
}