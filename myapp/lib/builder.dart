import 'package:flutter/material.dart';
import 'package:myapp/engine/condition.dart';
import 'package:myapp/engine/behaviour.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/targerselector.dart';
import 'package:myapp/engine/trifunction.dart';
import 'package:myapp/engine/work.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'bdd.dart';

abstract class Builder<T> 
{
  bool isValid(Validator validator);
  T build();

  Object? result;

  Object? get() 
  {
    return result;
  }
}

class Validator
{
  Builder? start;
  Map<Builder, bool> done = Map();

  bool isValid(Builder builder)
  {
    if(start == null)
    {
      print("{");
      start = builder;
    }

    if(done.containsKey(builder))
      return done[builder]!;
    
    print("Validator::isValid : $builder");
    done[builder] = true;
    bool result = builder.isValid(this);
    done[builder] = result;
    
    if(!result)
      print("Validator::isValid : $builder IS NOT VALID");
    else if(builder == start)
    
      print("Validator::isValid : SUCCESS");
    if(builder == start)
      print("}");
    
    return result;
  }
}

class BuilderServer extends Builder<Server>
{
  final Server server = Server();
  final List<BuilderEntity> builderEntities = [];

  BuilderEntity addEntity()
  {
    BuilderEntity builderEntity = BuilderEntity();
    builderEntity.entity.setValue(VALUE.NAME, "Entity ${builderEntities.length + 1}");
    builderEntities.add(builderEntity);
    return builderEntity;
  }

  void removeEntity(BuilderEntity builderEntity)
  {
    builderEntities.remove(builderEntity);
  }

  @override
  Server build() 
  {
    server.entities = [];
    for(BuilderEntity builderEntity in builderEntities)
      server.addEntity(builderEntity.build());
    return server;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderServer::isValid");
    for(BuilderEntity builderEntity in builderEntities)
    {
      if(!validator.isValid(builderEntity))
          return false;
    }
    return true;
  }
}

class BuilderEntity extends Builder<Entity>
{
  final Entity entity = Entity(Map());
  final BuilderTotal builderTotal = BuilderTotal();

  BuilderEntity()
  {
    result = entity;
  }

  void setValues(Map map)
  {
    entity.setValues(map);
  }

  @override
  Entity build() 
  {
    entity.behaviours = builderTotal.build();
    return entity;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderEntity::isValid");
    if(entity.getHPMax() <= 0)
    {
        print("HP of ${entity.getName()} is 0");
        return false;
    }
    return validator.isValid(builderTotal);
  }
  
}

class BuilderTotal extends Builder<List<Behaviour>> 
{
  List<BuilderBehaviour> builderBehaviours = [];

  BuilderBehaviour addBehaviour({Key? key, String name = ""}) 
  {
    BuilderBehaviour builder = BuilderBehaviour();
    builderBehaviours.add(builder);
    builder.name = name.length > 0 ? name : "[BuilderBehaviour ${builderBehaviours.length}]";
    return builder;
  }

  void removeBehaviour(BuilderBehaviour builderBehaviour)
  {
    builderBehaviours.remove(builderBehaviour);
  }

  void switchBehaviours(BuilderBehaviour A, BuilderBehaviour B)
  {
    int indexA = builderBehaviours.indexOf(A);
    int indexB = builderBehaviours.indexOf(B);
    builderBehaviours[indexA] = B;
    builderBehaviours[indexB] = A;
  }

  @override
  List<Behaviour> build() 
  {
    List<Behaviour> liste = [];
    builderBehaviours.forEach((element) {
      liste.add(element.build());
    });
    return liste;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderTotal::isValid");
    bool result = true;
    builderBehaviours.forEach((element) {
      if (!validator.isValid(element)) 
        result = false;
    });
    return result;
  }
}

class BuilderBehaviour extends Builder<Behaviour> 
{
  String name = "unnamed";

  BuilderConditionGroup builderConditions = BuilderConditionGroup();
  BuilderTargetSelector builderTargetSelector = BuilderTargetSelector();
  BuilderWork builderWork = BuilderWork();

  @override
  Behaviour build() 
  {
    Behaviour behaviour = Behaviour.withName(name);
    behaviour.condition = builderConditions.build();
    behaviour.selector = builderTargetSelector.build();
    behaviour.work = builderWork.build();
    return behaviour;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderBehaviour::isValid");
    bool result = validator.isValid(builderConditions) && validator.isValid(builderTargetSelector) && validator.isValid(builderWork);
    return result;
  }

  @override
  String toString() => name;
}

class BuilderConditionGroup extends Builder<ConditionGroup> implements TargetSelectorChild
{
  BuilderTargetSelector? builderTargetSelector;

  List<BuilderCondition> conditions = [];
  //List<ConditionLink> links = List.empty(growable: true);

  /*void addLink(ConditionLink link) {
    links.add(link);
  }*/

  BuilderCondition addCondition() 
  {
    print("BuilderConditionGroup::addCondition ($builderTargetSelector)");
    BuilderCondition builderCondition = BuilderCondition();
    conditions.add(builderCondition);
    if(builderTargetSelector != null)
      builderCondition.onAddedToTargetSelector(builderTargetSelector!);
    return builderCondition;
  }

  @override
  build() 
  {
    ConditionGroup group = ConditionGroup([TRUE(), TRUE(), ConditionLink.ET]);
    List<BuilderCondition> listeConditions = List.from(conditions);
    //List<ConditionLink> listeLinks = List.from(links);
    //ConditionLink link = ConditionLink.ET;
    while (listeConditions.length > 0) {
      BuilderCondition bCondition = listeConditions.removeAt(0);
      Condition condition = bCondition.build();
      group = ConditionGroup([group, condition, ConditionLink.ET]);
      //if (listeLinks.length > 0) link = listeLinks.removeAt(0);
    }
    return group;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderConditionGroup::isValid");
    bool result = true;
    conditions.forEach((condition) 
    {
      if (!validator.isValid(condition)) 
      {
        result = false;
      }
    });
    /*result = result &&
        (conditions.length == 0 /* || links.length == conditions.length - 1*/);*/
    return result;
  }

  @override
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector) 
  {
    print("$this added to TargetSelector ($builderTargetSelector)");
    this.builderTargetSelector = builderTargetSelector;
    for(BuilderCondition condition in conditions)
      condition.onAddedToTargetSelector(builderTargetSelector);
  }
}

class BuilderCondition extends Builder<Condition> implements TargetSelectorChild 
{
  BuilderTargetSelector? builderTargetSelector;

  Conditions? cond;
  List params = [];

  void setCondition(Conditions cond) 
  {
    if(this.cond == cond)
      return;

    print("$this::setCondition : $cond");
    this.cond = cond;
    this.params = [];
    for (int i = 0; i < cond.getParams().length; i++) 
      params.add(null);
    if (builderTargetSelector != null && cond.isBinary())
      setParam(0, builderTargetSelector!);
  }

  @override
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector)
  {
    this.builderTargetSelector = builderTargetSelector;
    print("$this added to TargetSelector");
    if (cond != null && cond!.isBinary())
      setParam(0, builderTargetSelector);    
  }

  void setParam(int index, Object param) 
  {
    print("setParam $index - $param");
    params[index] = param;
    if(index == 2 && param is BuilderCount)
    {
      params[0] = param;
    }
    else
    {
      params[0] = builderTargetSelector;
    }
    if(builderTargetSelector != null && param is TargetSelectorChild)
      param.onAddedToTargetSelector(builderTargetSelector!);
  }

  bool canSetParam(int index, Object? param) 
  {
    if(param == null || index != 1) 
      return false;
    if(param is Entity)
      return param.getClan() == 1;
    return param is ValueReader;
  }

  @override
  Condition build() 
  {
    print("BuilderCondition::build");
    for (int i = 0; i < params.length; i++) 
    {
      print("BuilderCondition::build - param $i : ${params[i]}");
      if (params[i] is Builder) 
      {
        Builder builder = params[i] as Builder;
        Object? p = builder.get();
        if (p != null)
          params[i] = p;
        else
          print("Getter of $builder is null");
      }
    }
    return cond!.instanciate(params);
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderCondition::isValid");
    bool result = cond != null;
    if (result) 
    {
      params.forEach((element) 
      {
        if (element == null) 
        {
          result = false;
        }
        else if(element is Builder)
        {
          if(!validator.isValid(element))
            result = false;
        }
      });
    }
    return result;
  }
}

class BuilderTargetSelector extends Builder<TargetSelector> 
{
  BuilderTriFunction builderTriFunction = BuilderTriFunction();
  BuilderConditionGroup builderConditionGroup = BuilderConditionGroup();

  BuilderTargetSelector() 
  {
    result = TargetSelector();
    builderConditionGroup.onAddedToTargetSelector(this);
  }

  @override
  TargetSelector build() 
  {
    (result as TargetSelector).tri = builderTriFunction.build();
    (result as TargetSelector).condition = builderConditionGroup.build();
    return (result as TargetSelector);
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderTargetSelector::isValid");
    bool result = validator.isValid(builderTriFunction) && validator.isValid(builderConditionGroup);
    return result;
  }
}

class BuilderTriFunction extends Builder<TriFunction?> 
{
  TriFunctions? tri;
  VALUE? value;

  @override
  TriFunction? build() 
  {
    return tri!.instanciate(value!);
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderTriFunction::isValid");
    bool result = true;
    if (tri != null) result = value != null;
    return result;
  }
}

class BuilderWork extends Builder<Work> 
{
  Works? work;

  @override
  Work build() 
  {
    return work!.instanciate();
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderWork::isValid");
    bool result = work != null;
    return result;
  }
}

class BuilderCount extends Builder<Count> implements TargetSelectorChild
{
  Object? target;
  VALUE? value;

  BuilderCount() 
  {
    result = this;
  }

  void setTarget(Object target)
  {
    print("BuilderCount::setTarget : $target");
    this.target = target;
    if(value != null)
      result = Count(getTarget(), this.value!);
  }

  void setValue(VALUE value)
  {
    print("BuilderCount::setValue : $value");
    this.value = value;
    if(target != null)
      result = Count(getTarget(), this.value!);
  }

  ValueReader getTarget()
  {
    if (target is Builder) 
    {
      Builder builder = target as Builder;
      Object? p = builder.get();
      if(p == null)
        print("Getter of $builder is null");
      else if(!(p is ValueReader))
        print("Value of $builder is not a ValueReader : $p");
      else
        target = p;
    }
    return target as ValueReader;
  }

  @override
  Count build() 
  {
    print("BuilderCount::build $target");
    return result as Count;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = value != null && target != null;
    return result;
  }

  @override
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector) 
  {
    print("$this onAddedToTargetSelector");
    setTarget(builderTargetSelector);
  }

  String getName()
  {
    return "Count" + (value != null ? "(${value!.getName()})" : "");
  }
}

abstract class TargetSelectorChild
{
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector);
}
