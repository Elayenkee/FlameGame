import 'dart:math';

import 'package:myapp/utils.dart';

import 'entity.dart';

class Server 
{
  List<Story> stories = [];
  List<Entity> entities = [];
  bool finished = false;

  int tour = 1;

  void addEntity(Entity entity) 
  {
    entities.add(entity);
  }

  void init()
  {
    tour = 1;
    finished = false;
    for(Entity entity in entities)
      entity.init();
  }

  Story? next()
  {
    if(finished)
    {
      Utils.log("END");
      return null;
    }

    Story story = Story();
    run(story);

    finished = true;
    int clan = 0;
    for(Entity entity in entities)
    {
      if(entity.isAlive())
      {
        if(clan == 0)
          clan = entity.getClan();
        else if(clan != entity.getClan())
          finished = false;
      }
    }
    
    if(!finished)
      tour++;

    return story;  
  }

  void run(Story story) 
  {
    Entity nextEntity = getNextEntity();
    int ellapse = nextEntity.timer;
    for(Entity entity in entities)
      entity.ellapse(ellapse);
    nextEntity.run(this, story);
  }

  Entity getNextEntity()
  {
    Entity? entity;
    for(Entity e in entities)
    {
      if(e.isAlive())
      {
        if(entity == null)
        {
          entity = e;
        }
        
        else 
        {
          if(e.timer < entity.timer)
            entity = e;
        }
      }
    }
    return entity!;
  }

  List<Entity> getAllies() 
  {
    List<Entity> allies = [];
    entities.forEach((element) 
    {
      if (element.getClan() == 1) 
        allies.add(element);
    });
    return allies;
  }

  List<Entity> getEnnemies() 
  {
    List<Entity> ennemies = [];
    entities.forEach((element) 
    {
      if (element.getClan() != 1) 
        ennemies.add(element);
    });
    return ennemies;
  }
}

class StoryEvent
{
  String log = "";
  Map values = Map();

  void set(Object key, Object value)
  {
    values[key] = value;
  }

  void setCaller(Entity entity)
  {
    set("caller", entity.toMap());
  }

  void setTarget(Entity entity)
  {
    set("target", entity.toMap());
  }

  Object? get(Object key)
  {
    return values[key];
  }

  bool has(Object key)
  {
    return values.containsKey(key);
  }
}

class Story
{
  final List<StoryEvent> events = [];

  void addStoryEvent(StoryEvent event)
  {
    events.add(event);
  }
}
