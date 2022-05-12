import 'package:myapp/engine/condition.dart';
import 'package:myapp/engine/behaviour.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/server.dart';
import 'package:myapp/engine/targerselector.dart';
import 'package:myapp/engine/trifunction.dart';
import 'package:myapp/engine/work';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/works/work.dart';

abstract class UUIDHolder
{
  String getUUID();

  Map<String, dynamic> toMap()
  {
    final map = Map<String, dynamic>();
    map["uuid"] = getUUID();
    addToMap(map);
    return map;
  }

  void addToMap(Map<String, dynamic> map);
}

/*abstract class Param
{
  Map<String, dynamic> toParam();
}*/

abstract class Builder<T> extends UUIDHolder//, Param
{
  String uuid = Utils.generateUUID();
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

  @override
  String getUUID()
  {
    return uuid;
  }

  Object asParam()
  {
    return {"type":"uuid", "value":getUUID()};
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
        Utils.log(space() + message);
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
  List<BuilderEntity> builderEntities = [];

  BuilderEntity addEntity({Entity? e = null})
  {
    if(e == null)
    {
      BuilderEntity builderEntity = Entity(Map()).builder;
      builderEntity.entity.setValue(VALUE.NAME, "Entity ${builderEntities.length + 1}");
      builderEntities.add(builderEntity);
      return builderEntity;
    }
    else
    {
        builderEntities.add(e.builder);
        return e.builder;
    }
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
    try
    {
      Utils.logBuild("BuilderServer.build.start");
      server.entities = [];
      for(BuilderEntity builderEntity in builderEntities)
        server.addEntity(builderEntity.build());
      Utils.logBuild("BuilderServer.build.end");
    }
    catch(e)
    {
      print(e);
    }
    return server;
  }

  @override
  bool isValid(Validator validator) 
  {
    if(myTeamEntities().length == builderEntities.length)
    {
      return false;
    }

    for(BuilderEntity builderEntity in builderEntities)
    {
      if(!validator.isValid(builderEntity))
          return false;
    }
    return true;
  }

  List<BuilderEntity> myTeamEntities()
  {
    List<BuilderEntity> entities = [];
    for(BuilderEntity builderEntity in builderEntities)
    {
      if(builderEntity.entity.getClan() == 1)
        entities.add(builderEntity);
    }
    return entities;
  }

  @override
  addToMap(Map<String, dynamic> map)
  {
    
  }
}

class BuilderEntity extends Builder<Entity>
{
  late Entity entity;
  late BuilderTotal builderTotal;

  BuilderEntity(this.entity)
  {
    result = entity;
    builderTotal = BuilderTotal();
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
    Utils.logBuild("BuilderEntity.build.start $builderTotal");
    entity.behaviours = builderTotal.build();
    Utils.logBuild("BuilderEntity.build.end");
    return entity;
  }

  @override
  bool isValid(Validator validator) 
  {
    if(entity.getHPMax() <= 0)
    {
        Utils.log("HP of ${entity.getName()} is 0");
        return false;
    }
    return validator.isValid(builderTotal);
  }
  
  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderEntity.toMap.start");
    map["builderTotal"] = builderTotal.toMap();
    Utils.logToMap("BuilderEntity.toMap.end");
  }

  BuilderEntity.fromJson(Entity e, Map<String, dynamic> map, Map<String, dynamic> uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderEntity.fromJson $uuid");
    entity = e;
    result = entity;
    builderTotal = BuilderTotal.fromJson(map["builderTotal"], uuids);
    Utils.logFromJson("BuilderEntity.fromJson.end");
  }
}

class BuilderTotal extends Builder<List<Behaviour>> 
{
  List<BuilderBehaviour> builderBehaviours = [];

  BuilderTotal(){}

  BuilderBehaviour addBehaviour({String name = ""}) 
  {
    BuilderBehaviour builder = BuilderBehaviour();
    builderBehaviours.add(builder);
    builder.name = name;
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
    Utils.logBuild("BuilderTotal.build.start $builderBehaviours");
    List<Behaviour> liste = [];
    builderBehaviours.forEach((element) {
      liste.add(element.build());
    });
    Utils.logBuild("BuilderTotal.build.end $liste");
    return liste;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = true;
    builderBehaviours.forEach((element) {
      if (element.activated && !validator.isValid(element)) 
        result = false;
    });
    return result;
  }

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderTotal.toMap.start");
    final liste = [];
    builderBehaviours.forEach((element) {
      liste.add(element.toMap());
    });
    map["builderBehaviours"] = liste;
    Utils.logToMap("BuilderTotal.toMap.end");
  }

  BuilderTotal.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderTotal.fromJson $uuid");
    List liste = map["builderBehaviours"];
    liste.forEach((element) { 
      builderBehaviours.add(BuilderBehaviour.fromJson(element, uuids));
    });
    Utils.logFromJson("BuilderTotal.fromJson.end");
  }
}

class BuilderBehaviour extends Builder<Behaviour> 
{
  String name = "unnamed";

  BuilderConditionGroup builderConditions = BuilderConditionGroup();
  BuilderTargetSelector builderTargetSelector = BuilderTargetSelector();
  BuilderWork builderWork = BuilderWork();

  bool activated = false;

  BuilderBehaviour(){}

  @override
  Behaviour build() 
  {
    Utils.logBuild("BuilderBehaviour.build.start : " + name + " [$builderConditions] [$builderTargetSelector] [$builderWork]");
    Behaviour behaviour = Behaviour.withName(name);
    if(activated)
    {
      behaviour.condition = builderConditions.build();
      behaviour.selector = builderTargetSelector.build();
      behaviour.work = builderWork.build();
    }
    Utils.logBuild("BuilderBehaviour.build.end");
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

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderBehaviour.toMap.start $name");
    //map["builderConditions"] = builderConditions.toMap();
    map["builderTargetSelector"] = builderTargetSelector.toMap();
    map["builderWork"] = builderWork.toMap();
    map["name"] = name;
    map["activated"] = activated;
    Utils.logToMap("BuilderBehaviour.toMap.end");
  }

  BuilderBehaviour.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderBehaviour.fromJson $uuid");
    builderConditions = BuilderConditionGroup();
    builderTargetSelector = BuilderTargetSelector.fromJson(map["builderTargetSelector"], uuids);
    builderWork = BuilderWork.fromJson(map["builderWork"], uuids);
    name = map["name"];
    activated = !map.containsKey("activated") || map["activated"];
    Utils.logFromJson("BuilderBehaviour.fromJson.end");
  }
}

class BuilderConditionGroup extends Builder<ConditionGroup> implements TargetSelectorChild
{
  BuilderTargetSelector? builderTargetSelector;

  List<BuilderCondition> conditions = [];
  //List<ConditionLink> links = List.empty(growable: true);

  /*void addLink(ConditionLink link) {
    links.add(link);
  }*/

  BuilderConditionGroup(){}

  BuilderCondition addCondition({BuilderCondition? b = null}) 
  {
    //Utils.log("BuilderConditionGroup::addCondition ($builderTargetSelector)");
    BuilderCondition builderCondition = b??BuilderCondition();
    conditions.add(builderCondition);
    if(b == null && builderTargetSelector != null)
      builderCondition.onAddedToTargetSelector(builderTargetSelector!);
    return builderCondition;
  }

  @override
  build() 
  {
    Utils.logBuild("BuilderConditionGroup.build.start $conditions");
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
    Utils.logBuild("BuilderConditionGroup.build.end $group");
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
    //Utils.log("$this added to TargetSelector ($builderTargetSelector)");
    this.builderTargetSelector = builderTargetSelector;
    for(BuilderCondition condition in conditions)
      condition.onAddedToTargetSelector(builderTargetSelector);
  }

  @override
  String getName() => "BuilderConditionGroup";

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderConditionGroup.toMap.start");
    map["builderTargetSelectorUUID"] = builderTargetSelector?.uuid;
    final liste = [];
    conditions.forEach((element) {
      liste.add(element.toMap());
    });
    map["conditions"] = liste;
    Utils.logToMap("BuilderConditionGroup.toMap.end");
  }

  BuilderConditionGroup.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderConditionGroup.fromJson $uuid");
    String builderTargetSelectorUUID = map["builderTargetSelectorUUID"];
    builderTargetSelector = uuids[builderTargetSelectorUUID];
    List liste = map["conditions"];
    liste.forEach((element) { 
      addCondition(b: BuilderCondition.fromJson(element, uuids));
    });
    Utils.logFromJson("BuilderConditionGroup.fromJson.end");
  }
}

class BuilderCondition extends Builder<Condition> implements TargetSelectorChild 
{
  BuilderTargetSelector? builderTargetSelector;

  Conditions? cond;
  List params = [];

  BuilderCondition(){}

  void setCondition(Conditions? cond) 
  {
    if(cond == null)
      return;

    if(this.cond == cond)
      return;

    //Utils.log("$this::setCondition : $cond");
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
    if (cond != null && cond!.isBinary())
      setParam(0, builderTargetSelector);    
  }

  void setParam(int index, Object? param) 
  {
    //Utils.log("setParam $index - $param");
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

  bool canSetParam(int index, UUIDHolder? param) 
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
    Utils.logBuild("BuilderCondition.build.start $params $cond");
    List liste = [];
    for (int i = 0; i < params.length; i++) 
    {
      liste.add(params[i]);
      if (params[i] is Builder) 
      {
        Builder builder = params[i] as Builder;
        Object? p = builder.get();
        if (p != null)
          liste[i] = p;
      }
    }
    result = cond!.instanciate(liste);
    Utils.logBuild("BuilderCondition.build.end $result");
    return result as Condition;
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

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderCondition.toMap.start");
    map["builderTargetSelectorUUID"] = builderTargetSelector?.uuid;
    map["conditions"] = cond != null ? cond!.name : "";
    final liste = [];

    for(var i = 0; i <= 2; i++)
    {
      var element = params[i];
      if(element == null)
      {
        liste.add({"type":null});
      }
      else if(element is Builder)
      {
        if(i == 0)
        {
          liste.add({"type":"uuid", "value":element.getUUID()});
        }
        else
        {
          liste.add(element.asParam());
        }
      }
      else
      {
        liste.add(toParam(element));
      }
    }
    map["params"] = liste;
    Utils.logToMap("BuilderCondition.toMap.end $cond $liste");
  }

  Object toParam(Object param)
  {
    if(param is VALUE)
      return param.asParam();
    
    if(param is ValueAtom)
      return {"type":"ValueAtom", "value":param.value};

    if(param is Entity)
      return {"type":"uuid", "value":param.getUUID()};

    return param;
  }

  static BuilderCondition fromJson(Map<String, dynamic> map, Map uuids)
  {
    Utils.logFromJson("BuilderCondition.fromJson.start params ${map["params"]}");
    final BuilderCondition builderCondition = create(map);
    builderCondition.uuid = map["uuid"];
    map[builderCondition.uuid] = builderCondition;
    String builderTargetSelectorUUID = map["builderTargetSelectorUUID"];
    builderCondition.builderTargetSelector = uuids[builderTargetSelectorUUID];
    
    builderCondition.setCondition(ConditionsExtension.get(map["conditions"]));

    Object? param1 = builderCondition.paramFromMap(map["params"][1], uuids);
    Object? param2 = builderCondition.paramFromMap(map["params"][2], uuids);
    Object? param0 = builderCondition.paramFromMap(map["params"][0], uuids);
    builderCondition.setParam(0, param0);
    builderCondition.setParam(1, param1);
    builderCondition.setParam(2, param2);

    Utils.logFromJson("BuilderCondition.fromJson.end");
    return builderCondition;
  }

  static BuilderCondition create(Map<String, dynamic> map)
  {
    if(map.containsKey("predefinedType"))
    {
      String type = map["predefinedType"];
      if(type == "isEnnemy")
        return isEnnemy.fromMap();
    }
    return BuilderCondition();
  }

  Object? paramFromMap(Map<String, dynamic> p, Map uuids)
  {
    final String type = p["type"];
    switch(type)
    {
      case "uuid":return uuids[p["value"]];
      case "ValueAtom":return ValueAtom(p["value"]);
      case "BuilderCount":return BuilderCount.fromJson(p, uuids);
      case "VALUE": return ValueExtension.get(p["name"]);
    }
    return null;
  }
}

abstract class PredefinedBuilderCondition extends BuilderCondition
{
  String get name;

  static PredefinedBuilderCondition getFromName(String name, BuilderEntity builderEntity)
  {
    if(name == "isEnnemy")
      return isEnnemy(builderEntity);
    if(name == "isMe")
      return isMe(builderEntity);
    return isEnnemy(builderEntity);
  }

  addToMap(Map<String, dynamic> map)
  {
    super.addToMap(map);
    map["predefinedType"] = name;
  }
}

class isEnnemy extends PredefinedBuilderCondition
{
  isEnnemy(BuilderEntity builderEntity):super()
  {
    setCondition(Conditions.NOT_EQUALS);
    setParam(1, builderEntity);
    setParam(2, VALUE.CLAN);
  }

  isEnnemy.fromMap();

  String get name => "isEnnemy";
}

class isMe extends PredefinedBuilderCondition
{
  isMe(BuilderEntity builderEntity):super()
  {
    setCondition(Conditions.EQUALS);
    setParam(1, builderEntity);
    setParam(2, VALUE.NAME);
  }

  isMe.fromMap();

  String get name => "isMe";
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
    Utils.logBuild("BuilderTargetSelector.build.start $result [$builderTriFunction] [$builderConditionGroup]");
    (result as TargetSelector).tri = builderTriFunction.build();
    (result as TargetSelector).condition = builderConditionGroup.build();
    Utils.logBuild("BuilderTargetSelector.build.end");
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

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderTargetSelector.toMap.start");
    map["builderTriFunction"] = builderTriFunction.toMap();
    map["builderConditionGroup"] = builderConditionGroup.toMap();
    Utils.logToMap("BuilderTargetSelector.toMap.end");
  }

  BuilderTargetSelector.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderTargetSelector.fromJson $uuid");
    result = TargetSelector();
    builderTriFunction = BuilderTriFunction.fromJson(map["builderTriFunction"], uuids);
    builderConditionGroup = BuilderConditionGroup.fromJson(map["builderConditionGroup"], uuids);
    Utils.logFromJson("BuilderTargetSelector.fromJson.end");
  }
}

class BuilderTriFunction extends Builder<TriFunction?> 
{
  TriFunctions? tri;
  VALUE? value;

  BuilderTriFunction(){}

  @override
  TriFunction? build() 
  {
    Utils.logBuild("BuilderTriFunction.build.start $tri $value");
    TriFunction? result = tri?.instanciate(value!);
    Utils.logBuild("BuilderTriFunction.build.end $result");
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

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderTriFunction.toMap.start $tri $value");
    map["tri"] = tri != null ? tri!.name : "";
    map["value"] = value != null ? value!.name : "";
    Utils.logToMap("BuilderTriFunction.toMap.end");
  }

  BuilderTriFunction.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderTriFunction.fromJson $uuid");
    tri = TriFunctionsExtension.get(map["tri"]);
    value = ValueExtension.get(map["value"]);
    Utils.logFromJson("BuilderTriFunction.fromJson.end");
  }
}

class BuilderWork extends Builder<Work> 
{
  Work? work;

  BuilderWork(){}

  @override
  Work build() 
  {
    Utils.logBuild("BuilderWork.build.start $work");
    result = work!;
    Utils.logBuild("BuilderWork.build.end $result");
    return result as Work;
  }

  @override
  bool isValid(Validator validator) 
  {
    bool result = work != null;
    return result;
  }

  @override
  String getName()
  {
    if(work != null)
      return work!.name;
    return "BuilderWork";
  }

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderWork.toMap.start $work");
    map["work"] = work != null ? work!.name : "";
    Utils.logToMap("BuilderCount.toMap.end");
  }

  BuilderWork.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderWork.fromJson $uuid");
    work = Work.getFromName(map["work"]);
    Utils.logFromJson("BuilderWork.fromJson.end");
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

  void setValue(VALUE? value)
  {
    if(value == null)
      return;
    //Utils.log("BuilderCount::setValue : $value");
    this.value = value;
    if(target != null)
      result = Count(getTarget(), this.value!);
  }

  ValueReader getTarget()
  {
    var t = target;
    if (target is Builder) 
    {
      Builder builder = target as Builder;
      Object? p = builder.get();
      if(p == null)
        Utils.log("Getter of $builder is null");
      else if(!(p is ValueReader))
        Utils.log("Value of $builder is not a ValueReader : $p");
      else
        t = p;
    }
    return t as ValueReader;
  }

  @override
  Count build() 
  {
    Utils.logBuild("BuilderCount.build.start $result [$target]");
    Utils.logBuild("BuilderCount.build.end");
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
    //Utils.log("BuilderCount $this onAddedToTargetSelector");
    setTarget(builderTargetSelector);
  }

  @override
  String getName()
  {
    return "Count" + (value != null ? "(${value!.getName()})" : "");
  }

  @override
  Object asParam()
  {
    return toMap();
  }

  addToMap(Map<String, dynamic> map)
  {
    Utils.logToMap("BuilderCount.toMap.start $target $value $uuid");
    map["type"] = "BuilderCount";

    if(target is Builder)
    {
      map["target"] = (target! as Builder).getUUID();
    }
    else
    {
      map["target"] = target?.toString();
    }
    
    map["value"] = value != null ? value!.name : "";
    Utils.logToMap("BuilderCount.toMap.end");
  }

  BuilderCount.fromJson(Map<String, dynamic> map, Map uuids)
  {
    uuid = map["uuid"];
    uuids[uuid] = this;
    Utils.logFromJson("BuilderCount.fromJson $uuid");
    result = this;
    setTarget(uuids[map["target"]]);
    setValue(ValueExtension.get(map["value"]));
    Utils.logFromJson("BuilderCount.fromJson.end");
  }
}

abstract class TargetSelectorChild implements UUIDHolder
{
  void onAddedToTargetSelector(BuilderTargetSelector builderTargetSelector);
}
