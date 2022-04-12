import 'condition.dart';
import 'entity.dart';
import 'server.dart';
import 'targerselector.dart';
import 'valuesolver.dart';
import 'work.dart';

class Behaviour implements ValueReader {
  String name = "unnamed";

  Condition condition = TRUE();
  TargetSelector selector = TargetSelector();
  Work work = Work();
  Entity? target;

  Behaviour();

  Behaviour.withName(this.name);

  bool check(Server server) 
  {
    target = null;
    bool result = false;
    if (condition.check(server)) 
    {
      target = selector.get(server.entities);
      result = target != null;
    }
    return result;
  }

  bool execute(Entity caller, Story story) 
  {
    return work.execute(caller, target!, story);
  }

  @override
  Object? getValue(VALUE? value) 
  {
    return target?.getValue(value!);
  }
}
