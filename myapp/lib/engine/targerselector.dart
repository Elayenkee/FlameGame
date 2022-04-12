import 'condition.dart';
import 'entity.dart';
import 'valuesolver.dart';
import 'trifunction.dart';

class TargetSelector implements ValueReader {
  TriFunction? tri;
  Condition condition = new TRUE();

  Entity? currentTargetChecked;

  void setTri() {}

  Entity? get(List<Entity> entities) 
  {
    currentTargetChecked = null;
    List<Entity> liste = List.from(entities);

    if (tri != null)
      liste = tri!.sort(liste);
    
    for (var i = 0; i < liste.length; i++) 
    {
      Entity entity = liste[i];
      if (!entity.isAlive()) 
        continue;

      currentTargetChecked = entity;
      if (!condition.check(entity)) 
      {
        //print("condition not checked $condition");
        currentTargetChecked = null;
        continue;
      }

      return entity;
    }
    return null;
  }

  @override
  Object? getValue(VALUE? value) 
  {
    if (currentTargetChecked != null)
    {
      Object? result = currentTargetChecked!.getValue(value!);
      return result;
    }
    return null;
  }
}
