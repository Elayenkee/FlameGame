/*import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/engine/work.dart';

class DotList implements Countable 
{
  List<DOT> dots = [];

  DotList();

  DotList.from(DotList copy)
  {
    dots = List.from(copy.dots);
  }

  DotList.withValue(VALUE value, DotList parent)
  {
    for(DOT d in parent.dots)
    {
      if(d.source == value)
        dots.add(d);
    }
  }

  void add(DOT dot)
  {
    dots.add(dot);
  }

  @override
  int count()
  {
    return dots.length;
  }
}*/