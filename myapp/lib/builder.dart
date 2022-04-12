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
  String getName();
  bool isValid(Validator validator);
  T build();

  Object? result;

  Object? get() 
  {
    return result;
  }

  @override
  String toString()
  {
    return getName();
  }
}

class Validator
{
  Map<Builder, bool> done = Map();

  bool log = true;
  int deep = 0;

  Validator(bool log)
  {
      this.log = log;
  }

  void Log(String message)
  {
    if(log)
        print(space() + message);
  }

  String space()
  {
    String s = "";
    for(int i = 0; i < deep; i++)
      s+= "  ";
    return s;
  }

  bool isValid(Builder builder)
  {
    if(done.containsKey(builder))
      return done[builder]!;
    
    Log(">>> " + builder.getName());
    deep++;
    done[builder] = true;
    bool result = builder.isValid(this);
    done[builder] = result;
    deep--;
    Log("<<< " + builder.getName() + " : " + result.toString());
    
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

  @override
  String getName()
  {
    return "Server";
  }

  void removeEntity(BuilderEntity builderEntity)
  {
    builderEntities.remove(builderEntity);
  }

  @override
  Server build() 
  {
    print("BuilderServer.build.start");
    server.entities = [];
    for(BuilderEntity builderEntity in builderEntities)
      server.addEntity(builderEntity.build());
    print("BuilderServer.build.end");
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

  @override
  String getName()
  {
    return entity.getName();
  }

  void setValues(Map map)
  {
    entity.setValues(map);
  }

  @override
  Entity build() 
  {
    print("BuilderEntity.build.start");
    entity.behaviours = builderTotal.build();
    print("BuilderEntity.build.end");
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

  @override
  String getName()
  {
    return "Total";
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
    print("BuilderTotal.build.start");
    List<Behaviour> liste = [];
    builderBehaviours.forEach((element) {
      liste.add(element.build());
    });
    print("BuilderTotal.build.end");
    return liste;
  }

  @override
  bool isValid(Validator validator) 
  {
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
    print("BuilderBehaviour.build.start : " + name + " [$builderConditions] [$builderTargetSelector] [$builderWork]");
    Behaviour behaviour = Behaviour.withName(name);
    behaviour.condition = builderConditions.build();
    behaviour.selector = builderTargetSelector.build();
    behaviour.work = builderWork.build();
    print("BuilderBehaviour.build.end");
    return behaviour;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool resultConditionGroup = validator.isValid(builderConditions);
    bool resultTargetSelector = validator.isValid(builderTargetSelector);
    bool resultWork = validator.isValid(builderWork);
    bool result = resultConditionGroup && resultTargetSelector && resultWork;
    return result;
  }

  @override
  String toString() => name;

  @override
  String getName() => name;
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
    print("BuilderConditionGroup.build.start");
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
    print("BuilderConditionGroup.build.end");
    return group;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = true;
    conditions.forEach((condition) 
    {
      if (!validator.isValid(condition)) 
      {
        result = false;
      }
    });
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

  @override
  String getName() => "BuilderConditionGroup";
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
    print("BuilderCondition::build $cond $params");
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
    bool result = cond != null;
    if (result) 
    {
      params.forEach((element) 
      {
        if (element == null) 
        {
          result = false;
        }
        else if(element is Builder && !(element is BuilderEntity))
        {
          if(!validator.isValid(element))
            result = false;
        }
      });
    }
    return result;
  }

  @override
  String getName() => "BuilderCondition";
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
    print("BuilderTargetSelector.build.start $result [$builderTriFunction] [$builderConditionGroup]");
    (result as TargetSelector).tri = builderTriFunction.build();
    (result as TargetSelector).condition = builderConditionGroup.build();
    print("BuilderTargetSelector.build.end");
    return (result as TargetSelector);
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = validator.isValid(builderTriFunction) && validator.isValid(builderConditionGroup);
    return result;
  }

  @override
  String getName() => "BuilderTargetSelector";
}

class BuilderTriFunction extends Builder<TriFunction?> 
{
  TriFunctions? tri;
  VALUE? value;

  @override
  TriFunction? build() 
  {
    print("BuilderTriFunction.build.start $tri [$value]");
    TriFunction? result = tri?.instanciate(value!);
    print("BuilderTriFunction.build.end $result");
    return result;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = true;
    if (tri != null) 
      result = value != null;
    return result;
  }

  @override
  String getName()
  {
    if(tri != null)
      return tri!.getName();
    return "BuilderTriFunction";
  }
}

class BuilderWork extends Builder<Work> 
{
  Works? work;

  @override
  Work build() 
  {
    print("BuilderWork.build.start $work");
    Work result = work!.instanciate();
    print("BuilderWork.build.end $result");
    return result;
  }

  @override
  bool isValid(Validator validator) 
  {
    //print("BuilderWork::isValid");
    bool result = work != null;
    return result;
  }

  @override
  String getName()
  {
    if(work != null)
      return work!.getName();
    return "BuilderWork";
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
    print("BuilderCount.build.start $result [$target]");
    print("BuilderCount.build.end");
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

  @override
  String getName()
  {
    return "Count" + (value != null ? "(${value!.getName()})" : "");
  }
}

abstract class TargetSelectorChild
{
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector);
}
