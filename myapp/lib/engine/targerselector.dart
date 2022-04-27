import 'package:myapp/builder.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/engine/condition.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/engine/trifunction.dart';

class TargetSelector extends UUIDHolder implements ValueReader 
{
  String uuid = Utils.generateUUID();
  TriFunction? tri;
  Condition condition = new TRUE();

  Entity? currentTargetChecked;

  void setTri() {}

  Entity? get(List<Entity> entities) 
  {
    Utils.logRun("TargetSelector.run.get.start $tri $condition");
    currentTargetChecked = null;
    List<Entity> liste = List.from(entities);

    if (tri != null)
      liste = tri!.sort(liste);
    
    Utils.logRun("TargetSelector.run.get entities $liste");
    for (var i = 0; i < liste.length; i++) 
    {
      Entity entity = liste[i];
      if (!entity.isAlive()) 
        continue;

      currentTargetChecked = entity;
      Utils.logRun("TargetSelector.run.get check [$condition] on [$entity]");
      if (!condition.check(entity)) 
      {
        Utils.logRun("TargetSelector.run.get currentTargerChecked null");
        currentTargetChecked = null;
        continue;
      }
      Utils.logRun("TargetSelector.run.get.end result : $entity");
      return entity;
    }
    Utils.logRun("TargetSelector.run.get.end result : null");
    return null;
  }

  @override
  Object? getValue(VALUE? value) 
  {
    Utils.logRun("TargetSelector.run.getValue.start $value $currentTargetChecked");
    Object? result = null;
    if (currentTargetChecked != null)
    {
      result = currentTargetChecked!.getValue(value!);
    }
    Utils.logRun("TargetSelector.run.getValue.end $result");
    return result;
  }

  @override
  String getUUID()
  {
    return uuid;
  }

  @override
  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("TargetSelector.toMap.start");
    Utils.logToMap("TargetSelector.toMap.end"); 
  }
}
