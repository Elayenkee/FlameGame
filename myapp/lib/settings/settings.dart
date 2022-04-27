import 'package:flame/components.dart';
import 'package:flame/components.dart' as draggable;
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/main.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/settings/popupBehaviour.dart';
import 'dart:math' as math;

class Images
{
  static String warrior = '${Utils.pathImages}entity_warrior.png';
  static String orc = '${Utils.pathImages}entity_orc.png';
}

class SettingsScreen extends StatelessWidget
{
  late final SettingsLayout layout;
  
  SettingsScreen(BuilderServer builderServer)
  {
    layout = SettingsLayout(builderServer);
  }

  Future<bool> _onBackPressed()
  {
    if(layout.popupBehaviour != null)
    {
      layout.popupBehaviour!.close();
      layout.popupBehaviour = null;
      return Future.value(false);  
    }
    return Future.value(true);
  }

  @override
  Widget build(BuildContext context) 
  {
    return RawKeyboardListener(focusNode: layout.focusNode, onKey: layout.handleKeyEvent, child: WillPopScope(child: GameWidget(game: layout), onWillPop: _onBackPressed));
  }
}

class SettingsLayout extends AbstractLayout with HasDraggableComponents
{
  final BuilderServer builderServer;
  final List<EntityComponent> entities = [];
  EntityComponent? selectedEntity = null;

  late final SpriteComponent btnAddEntity;
  EntityBuilderComponent? entityBuilder = null;
  
  //final List<IBouton> listeners = [];
  //Function? onNextTap = null;

  PopupBehaviour? popupBehaviour;

  SettingsLayout(this.builderServer):super();

  @override
  Future<void> onLoad() async
  {
    await images.load('button_plus.png');
    await images.load('button_play.png');
    await images.load('button_delete.png');
    await images.load('button_checked.png');
    await images.load('button_cancel.png');
    await images.load(Images.warrior);
    await images.load(Images.orc);

    btnAddEntity = BoutonSprite(this, (){
      BuilderEntity entity = builderServer.addEntity();
      entity.entity.setValue(VALUE.CLAN, 1);
      entity.entity.setValue(VALUE.HP_MAX, 1);
      selectEntity(addEntity(entity));
      if(entities.length >= 8)
        btnAddEntity.remove();
    }, Sprite(images.fromCache('button_plus.png')));
    btnAddEntity.anchor = Anchor.topLeft;
    btnAddEntity.position.y = 10;
    add(btnAddEntity);

    for(BuilderEntity entity in builderServer.builderEntities)
      addEntity(entity);
    if(entities.length > 0)
      selectEntity(entities[0]);

    return super.onLoad();
  }

  /*void updateBoutonsStatus(Function getStatus)
  {
    for(IBouton bouton in listeners)
    {
      Object o = bouton.getObject();
      bool? s = getStatus(o);
      bouton.setStatus(s);
    }
  }*/

  EntityComponent addEntity(BuilderEntity entity)
  {
    EntityComponent entityComponent = EntityComponent(this, entity);
    entities.add(entityComponent);
    add(entityComponent);
    updatePositions();
    return entityComponent;
  }

  void onEntityChanged()
  {
    if(entityBuilder != null)
      entityBuilder!.remove();
    entityBuilder = EntityBuilderComponent(this);
    add(entityBuilder!);
  }

  void deleteSelectedEntity()
  {
    if(selectedEntity != null)
    {
      entities.remove(selectedEntity);
      selectedEntity!.remove();
      builderServer.removeEntity(selectedEntity!.builder);
      updatePositions();
      entityBuilder!.remove();
      entityBuilder = null;
      selectedEntity = null;
      //if(entities.length > 0)
      //  selectEntity(entities[0]);
    }
  }

  /*bool onTap(Object object)
  {
    if(onNextTap != null)
    {
      if(onNextTap!(object))
        onNextTap = null;
      updateBoutonsStatus((o) => null);
      return true;
    }
    return false;
  }*/

  void selectEntity(EntityComponent entity)
  {
    selectedEntity = entity;
    onEntityChanged();
  }

  void updatePositions()
  {
    for(int i = 0; i < entities.length; i++)
      entities[i].position = Vector2(75.0 * (i + 1), entities[i].y);
    btnAddEntity.position.x = 75.0 * (entities.length + 1);
    /*for(int i = 0; i < entities.length; i++)
      entities[i].position.moveToTarget(Vector2(75.0 * (i + 1), entities[i].position.y), 20);
    btnAddEntity.position.moveToTarget(Vector2(75.0 * (entities.length + 1), btnAddEntity.position.y), 20);*/
  }
}

class EntityComponent extends SpriteComponent with Tappable
{
  final SettingsLayout layout;
  final BuilderEntity builder;

  late Rect selectedRect;
  late final Paint selectedPaint;

  late final Paint highlightPaint;
  bool? highlighted = null;

  late final Paint unclickablePaint;

  EntityComponent(this.layout, this.builder)
  {
    selectedPaint = Paint()..color = Colors.yellow.withOpacity(.7);
    highlightPaint = Paint()..color = Colors.green.withOpacity(.7);
    unclickablePaint = Paint()..color = Colors.white.withOpacity(.5);
    updateRect();
  }

  @override
  Future<void> onLoad() async
  {
    updateClan();
    size = Vector2(50, 50);
    anchor = Anchor.topLeft;
    return super.onLoad();
  }

  void updateClan()
  {
    int clan = builder.entity.getClan();
    sprite = Sprite(layout.images.fromCache(clan == 1 ? Images.warrior : Images.orc));
  }

  @override
  void render(Canvas canvas) 
  {
    if(layout.selectedEntity == this)
      canvas.drawRect(selectedRect, selectedPaint);

    if(highlighted != null)
      if(highlighted!)
        canvas.drawRect(selectedRect, highlightPaint);

    super.render(canvas);
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    /*if(!layout.onTap(getObject()))
    {
      layout.selectEntity(this);
    }*/
    layout.selectEntity(this);
    return true;
  }

  void updateRect()
  {
    selectedRect = Rect.fromLTWH(x, y, 50, 50);
  }

  @override
  set position(Vector2 position)
  {
    super.position = position;
    updateRect();
  }
}

class EntityBuilderComponent extends PositionComponent with Tappable
{
  late final Rect bgRect;
  late final Paint bgPaint;
  final SettingsLayout layout;

  final List<ValueModifier> valueModifiers = [];
  late final BuilderTotalComponent builderTotalComponent;
  late final EntityClanComponent entityClanComponent;
  //late final TextComponentTappable txtName;

  EntityBuilderComponent(this.layout)
  {
    size = Vector2(700, 400);
    position = Vector2((layout.size.x - size.x) / 2, 80);
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    bgPaint = Paint()..color = Colors.grey.shade400;
    builderTotalComponent = BuilderTotalComponent(layout);
  }

  @override
  Future<void> onLoad() async
  {
    BoutonSprite btnDeleteEntity = BoutonSprite(layout, (){layout.deleteSelectedEntity();}, Sprite(layout.images.fromCache('button_delete.png')));
    btnDeleteEntity.anchor = Anchor.topLeft;
    btnDeleteEntity.position = Vector2(size.x - 10 - btnDeleteEntity.size.x, 10);
    addChild(btnDeleteEntity);

    addValueModifier(VALUE.HP_MAX, "hp", 0);
    addValueModifier(VALUE.MP_MAX, "mp", 1);
    addValueModifier(VALUE.ATK, "atk", 2);
    addValueModifier(VALUE.DEF, "def", 3);
    addValueModifier(VALUE.POW, "pow", 4);
    addValueModifier(VALUE.MR, "mr", 5);

    entityClanComponent = EntityClanComponent(layout, layout.selectedEntity!.builder.entity);
    entityClanComponent.size = Vector2(40, 50);
    entityClanComponent.position = Vector2(25, 10);
    addChild(entityClanComponent);

    TextComponentTappable txtName = TextComponentTappable(layout.selectedEntity!.builder.entity.getName());
    txtName.position = Vector2(10, 60);
    txtName.textRenderer = TextPaint(config: TextPaintConfig(fontSize: 18));
    txtName.onTap = (){
      layout.openKeyboard((newName){
        layout.selectedEntity!.builder.entity.setValue(VALUE.NAME, newName);
        txtName.text = newName;
      }, layout.selectedEntity!.builder.entity.getName());
    };
    addChild(txtName);

    builderTotalComponent.x = 10;
    builderTotalComponent.y = 20 + ValueModifier._height;
    builderTotalComponent.init();
    addChild(builderTotalComponent);

    return super.onLoad();
  }

  void addValueModifier(VALUE value, String key, int index)
  {
    int min = value == VALUE.MP ? 0 : 1;
    ValueModifier v = ValueModifier(layout, layout.selectedEntity!.builder.entity.getValue(value) as int, key, min: min);
    v.onValueUpdated = (){
      layout.selectedEntity!.builder.entity.setValue(value, v.currentValue);
    };
    v.x = 100 + (index * (ValueModifier._width + 20)); v.y = 10;
    v.init();
    valueModifiers.add(v);
    addChild(v);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }

  @override
  bool onTapDown(TapDownInfo info) 
  {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    return false;
  }

  @override
  bool onTapCancel() 
  {
    return false;
  }
}

class EntityClanComponent extends SpriteComponent with Tappable
{
  final SettingsLayout layout;
  final Entity entity;
  late final Sprite spriteWarrior;
  late final Sprite spriteOrc;
  
  EntityClanComponent(this.layout, this.entity);

  @override
  Future<void> onLoad() async
  {
    spriteOrc = Sprite(layout.images.fromCache(Images.orc));
    spriteWarrior = Sprite(layout.images.fromCache(Images.warrior));
    updateClan();
    return super.onLoad();
  }

  void updateClan()
  {
    sprite = entity.getClan() == 1 ? spriteWarrior : spriteOrc;
  }

  @override
  bool onTapDown(TapDownInfo info) 
  {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    entity.setValue(VALUE.CLAN, 1 - entity.getClan());
    layout.selectedEntity?.updateClan();
    updateClan();
    return false;
  }

  @override
  bool onTapCancel() 
  {
    return false;
  }
}

class BuilderTotalComponent extends PositionComponent
{
  final SettingsLayout layout;
  late final Rect bgRect;
  late final Paint bgPaint;
  late final BoutonSprite btnAddBehaviour;
  
  List<BuilderBehaviourComponent> behaviours = [];
  BuilderBehaviourComponent? draggingBehaviour;
  double draggingOffsetY = 0;

  BuilderTotalComponent(this.layout);

  void init()
  {
    size = Vector2(layout.entityBuilder!.size.x - 20, layout.entityBuilder!.size.y - 30 - ValueModifier._height);
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    bgPaint = Paint()..color = Colors.grey.shade100;
  }

  @override
  Future<void> onLoad() async
  {
    for(BuilderBehaviour behaviour in layout.selectedEntity!.builder.builderTotal.builderBehaviours)
      addBuilderBehaviour(behaviour);
    
    btnAddBehaviour = BoutonSprite(layout, (){
        layout.selectedEntity!.builder.builderTotal.addBehaviour();
        layout.onEntityChanged();
      }, Sprite(layout.images.fromCache('button_plus.png')));
    if(behaviours.length < 5)
    {
      btnAddBehaviour.anchor = Anchor.topCenter;
      btnAddBehaviour.position = Vector2(size.x / 2, 10 + (behaviours.length * (10 + BuilderBehaviourComponent._height)));
      addChild(btnAddBehaviour); 
    }

    return super.onLoad();
  }

  void addBuilderBehaviour(BuilderBehaviour behaviour)
  {
    BuilderBehaviourComponent behaviourComponent = BuilderBehaviourComponent(layout, size.x - 20, behaviour);
    behaviourComponent.position = Vector2(10, 5 + ((10 + behaviourComponent.size.y) * behaviours.length));
    behaviourComponent.init();
    behaviours.add(behaviourComponent);
    addChild(behaviourComponent);
  }

  void onBehaviourDragging(BuilderBehaviourComponent builderBehaviour)
  {
    if(behaviours.length <= 1)
      return;

    for(int i = 0; i < behaviours.length; i++)
    {
      BuilderBehaviourComponent b = behaviours[i];
      if(b != builderBehaviour)
      {
        if(builderBehaviour.y >= b.initialPosition.y && builderBehaviour.y < b.initialPosition.y + b.size.y)
        {
          behaviours[behaviours.indexOf(builderBehaviour)] = b;
          behaviours[i] = builderBehaviour;
          Vector2 tmp = Vector2.copy(b.initialPosition);
          b.initialPosition = builderBehaviour.initialPosition;
          b.targetPosition = Vector2.copy(b.initialPosition);
          builderBehaviour.initialPosition = tmp;
          layout.selectedEntity!.builder.builderTotal.switchBehaviours(builderBehaviour.builderBehaviour, b.builderBehaviour);
          return;
        }
      }
    }
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }
}

class BuilderBehaviourComponent extends PositionComponent with draggable.Draggable
{
  static final double _height = 49;

  final SettingsLayout layout;
  final BuilderBehaviour builderBehaviour;
  late Rect bgRect;
  late final Paint bgPaint;
  late final BoutonSprite btnDelete;
  late final BuilderTotalComponent builderTotal;
  late final TextComponent textName;

  late final Sprite spriteChecked;
  late final Sprite spriteCancel;
  late final SpriteComponent componentValid;

  late Vector2 initialPosition;
  Vector2? targetPosition;

  bool moving = false;

  BuilderBehaviourComponent(this.layout, width, this.builderBehaviour)
  {
    size = Vector2(width, _height);
    builderTotal = layout.entityBuilder!.builderTotalComponent;
    textName = TextComponent(builderBehaviour.name);
  }

  void init()
  {
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    bgPaint = Paint()..color = Colors.grey.shade500;
    initialPosition = Vector2.copy(position);
  }

  @override
  Future<void> onLoad() async
  {
    btnDelete = BoutonSprite(layout, (){
      layout.selectedEntity!.builder.builderTotal.removeBehaviour(builderBehaviour);
      layout.onEntityChanged();
    }, Sprite(layout.images.fromCache('button_delete.png')));
    btnDelete.anchor = Anchor.topRight;
    btnDelete.position = Vector2(size.x - 5, 5);
    addChild(btnDelete);

    addChild(textName);

    Function onTapRename = () {
      layout.openKeyboard((newName){
        builderBehaviour.name = newName;
        textName.text = newName;
      }, builderBehaviour.name);
    };
    addChild(Bouton(layout, onTapRename, "Renommer", Vector2(100, 30), Vector2(300, 10)));

    Function onTapModifier = (){
      layout.add(PopupBehaviour(layout, this));
    };
    addChild(Bouton(layout, onTapModifier, "Modifier", Vector2(100, 30), Vector2(410, 10)));

    spriteChecked = Sprite(layout.images.fromCache('button_checked.png'));
    spriteCancel = Sprite(layout.images.fromCache('button_cancel.png'));
    componentValid = SpriteComponent();
    componentValid.size = Vector2.all(35);
    componentValid.position = Vector2(size.x - 35 - 50, 8);
    addChild(componentValid);
    updateComponentValid();

    return super.onLoad();
  }

  void updateComponentValid()
  {
    componentValid.sprite = builderBehaviour.isValid(Validator(true)) ? spriteChecked : spriteCancel;
  }

  @override
  void render(Canvas canvas) 
  {
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }

  @override
  bool onDragStart(int pointerId, DragStartInfo info) 
  {
    return true;
  }

  @override
  bool onDragUpdate(int pointerId, DragUpdateInfo info) 
  {
    y += info.delta.game.y;
    builderTotal.onBehaviourDragging(this);
    return true;
  }

  @override
  bool onDragEnd(int pointerId, DragEndInfo info) 
  {
    targetPosition = initialPosition;
    return true;
  }

  @override
  bool onDragCancel(int pointerId) 
  {
    targetPosition = initialPosition;
    return true;
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    if(targetPosition != null)
    {
        position.moveToTarget(targetPosition!, 30);
        if(position.distanceTo(targetPosition!) < 1)
          targetPosition = null;
    }
  }
}

class ValueModifier extends PositionComponent
{
  static final double _width = 63;
  static final double _height = 66;

  final SettingsLayout layout;
  //final VALUE value;

  late final Rect bgRect;
  late final Paint bgPaint;
  late final TextComponent textKey;
  late final TextComponent textValue;

  late int currentValue;
  int min = 0;
  int max = 999999;
  Function onValueUpdated = (){};

  ValueModifier(this.layout, this.currentValue, String txt, {Key? key, int min = 0, int max = 999999})//, this.value, String key)
  {
    textKey = TextComponent(txt);
    textValue = TextComponent(currentValue.toString());
  }

  void init()
  {
    size = Vector2(_width, _height);
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    bgPaint = Paint()..color = Colors.white;
  }

  @override
  Future<void> onLoad() async
  {
    BoutonValue btnPlus = BoutonValue(layout, onClickPlus);
    btnPlus.angle = math.pi -.5;
    btnPlus.x = 45;
    btnPlus.y = 10;
    addChild(btnPlus);

    BoutonValue btnMoins = BoutonValue(layout, onClickMoins);
    btnMoins.angle = math.pi * .5;
    btnMoins.x = 45;
    btnMoins.y = 55;
    addChild(btnMoins);

    textKey.textRenderer = TextPaint(config: TextPaintConfig(fontSize: 18));
    addChild(textKey);

    textValue.anchor = Anchor.topCenter;
    textValue.x = 43;
    textValue.y = 18;
    addChild(textValue);

    return super.onLoad();
  }

  void updateValue()
  {
    textValue.text = currentValue.toString();
  }

  void onClickPlus()
  {
    if(currentValue >= max)
      return;

    currentValue++;
    onValueUpdated();
    updateValue();
  }

  void onClickMoins()
  {
    if(currentValue <= min)
      return;
    currentValue--;
    onValueUpdated();
    updateValue();
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }
}

class BoutonValue extends SpriteComponent with Tappable
{
  final SettingsLayout layout;
  final Function onTap;

  double timer = -1;
  double delay = .5;

  BoutonValue(this.layout, this.onTap);

  @override
  Future<void> onLoad() async
  {
    sprite = Sprite(layout.images.fromCache('button_play.png'));
    anchor = Anchor.center;
    size = Vector2(18, 17);
    return super.onLoad();
  }

  @override
  bool onTapDown(TapDownInfo info) 
  {
    /*if(!layout.onTap(this))
    {
      timer = 0;
      delay = .5;
      onTap();
    }*/
    timer = 0;
    delay = .5;
    onTap();
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    timer = -1;
    return false;
  }

  @override
  bool onTapCancel() 
  {
    timer = -1;
    return false;
  }

  @override
  void update(double dt) 
  {
    super.update(dt);

    if(timer >= 0)
    {
      timer += dt;
      delay -= dt;
      if(delay <= 0)
      {
        onTap();
        delay *= .85; 
      }
    }
  }
}

class BoutonSprite extends SpriteComponent with Tappable
{
  final SettingsLayout layout;
  final Function onTap;

  BoutonSprite(this.layout, this.onTap, Sprite sprite):super(sprite:sprite)
  {
    size = Vector2(30, 30);
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    onTap();
    return true;
  }
}

class Bouton extends PositionComponent with Tappable
{
  final SettingsLayout layout;
  Function? onTap;
  late Rect bgRect;
  late Paint bgPaint;
  late final TextComponent txt;
  
  Bouton(this.layout, this.onTap, String text, Vector2 size, Vector2 position):super(size : size, position: position)
  {
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
    bgPaint = Paint()..color = FirstTheme.buttonColor;
    txt = TextComponent(text);
    txt.anchor = Anchor.center;
    txt.position = size / 2;
    txt.textRenderer = TextPaint(config: TextPaintConfig(fontSize: 18));
    addChild(txt);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    if(onTap != null)
      onTap!();
    return false;
  }

  @override
  set position(Vector2 position)
  {
    super.position = position;
    updateRect();
  }

  void updateRect()
  {
    bgRect = Rect.fromLTWH(x, y, size.x, size.y);
  }
}

class TextComponentTappable extends TextComponent with Tappable
{
  Function? onTap;

  TextComponentTappable(String text) : super(text);

  @override
  bool onTapUp(TapUpInfo info) 
  {
    onTap?.call();
    return false;
  }
}

Vector2 getGlobalPosition(PositionComponent component)
{
  if(component.parent != null)
    return getGlobalPosition(component.parent as PositionComponent) + component.position;
  return component.position;
}

String getNameForButton(Object o)
{
  if(o is TriFunctions)
    return o.getName();
  if(o is VALUE)
    return o.getName();
  if(o is Conditions)
    return o.getName();
  if(o is BuilderEntity)
    return o.entity.getName();
  if(o is Entity)
    return o.getName();
  if(o is Works)
    return o.getName();
  if(o is ValueAtom)
    return o.getName();
  if(o is BuilderCount)
    return o.getName();
  return o.toString();
}