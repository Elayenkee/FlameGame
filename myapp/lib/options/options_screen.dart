import 'dart:math';

import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flame/palette.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/tutoriel/tutoriel_screen.dart';
import 'package:myapp/utils/images.dart';
import 'package:myapp/works/work.dart';

class OptionsScreen extends AbstractScreen
{
  late final VoidCallback? onClickClose;

  late Entity selectedEntity;
  final List<Player> players = [];
  final List<BuilderBehaviourItemComponent> behaviours = [];
  BuilderBehaviourItemComponent? draggingBehaviour;
  double draggingOffsetY = 0;

  late final PositionComponent cadre;
  late final SpriteComponent _buttonClose;

  PopupBuilderBehaviour? popupBuilderBehaviour;

  OptionsScreen(GameLayout gameRef, Vector2 size, {VoidCallback? this.onClickClose}):super(gameRef, "D", size, priority: 500);

  @override
  Future<void> onLoad() async 
  {
    //print("OptionsScreen.onLoad");
    await super.onLoad();

    selectedEntity = Storage.entity;

    final b = Background(gameRef.size);
    b.setColor(Color.fromARGB(129, 0, 0, 0));
    add(b);

    final marge = 120.0;
    cadre = SpriteComponent(size: gameRef.size - Vector2.all(marge));
    cadre.position = Vector2.all(marge / 2);
    add(cadre);

    for(int i = 0; i < Storage.entities.length; i++)
    {
      final player = Player(Storage.entities[i]);
      player.position = cadre.position + Vector2(38 + ((player.size.x + 10) * i), -30);
      players.add(player);
      await addChild(player);
    }

    _buttonClose = SpriteComponent(sprite: Sprite(ImagesUtils.getImage("button_close.png")), position: Vector2(cadre.size.x - 38, 0), size: Vector2.all(38));
    if(Storage.entity.nbCombat > 0)
      await cadre.addChild(_buttonClose);

    updateSelectedPlayer();
    
    //print("OptionsScreen.onLoaded");
  }

  void updateSelectedPlayer()
  {
    players.forEach((element) { element.updateSelected(element.entity == selectedEntity);});

    behaviours.forEach((element) {element.remove();});
    behaviours.clear();

    int index = 0;
    for(BuilderBehaviour behaviour in selectedEntity.builder.builderTotal.builderBehaviours)
      addBuilderBehaviour(behaviour, index++);
  }

  void addBuilderBehaviour(BuilderBehaviour behaviour, int index)
  {
    BuilderBehaviourItemComponent behaviourComponent = BuilderBehaviourItemComponent(this, selectedEntity, index, behaviour, Vector2(cadre.size.x - 30, cadre.size.y / 7.2));
    behaviourComponent.position = Vector2(10, 65 + ((10 + behaviourComponent.size.y) * behaviours.length));
    behaviourComponent.init();
    behaviours.add(behaviourComponent);
    cadre.addChild(behaviourComponent, gameRef: gameRef);
  }

  void onBehaviourDragging(DragUpdateInfo info)
  {
    if(behaviours.length <= 1 || draggingBehaviour == null)
      return;

    draggingBehaviour!.y += info.delta.game.y;
    for(int i = 0; i < behaviours.length; i++)
    {
      BuilderBehaviourItemComponent b = behaviours[i];
      if(b != draggingBehaviour)
      {
        if(draggingBehaviour!.y >= b.initialPosition.y - 10 && draggingBehaviour!.y < b.initialPosition.y + b.size.y)
        {
          behaviours[behaviours.indexOf(draggingBehaviour!)] = b;
          behaviours[i] = draggingBehaviour!;
          Vector2 tmp = Vector2.copy(b.initialPosition);
          b.initialPosition = draggingBehaviour!.initialPosition;
          b.targetPosition = Vector2.copy(b.initialPosition);
          draggingBehaviour!.initialPosition = tmp;
          selectedEntity.builder.builderTotal.switchBehaviours(draggingBehaviour!.builderBehaviour, b.builderBehaviour);
          Storage.storeEntities();
          return;
        }
      }
    }
  }

  @override
  List<ObjectClicked> onClick(Vector2 p) 
  {
    List<ObjectClicked> objects = [];

    if(popupBuilderBehaviour != null)
      objects.addAll(popupBuilderBehaviour!.onClick(p));
    
    for(Player player in players)
    {
      if(player.containsPoint(p))
      {
        Function call = (){
          selectedEntity = player.entity;
          updateSelectedPlayer();
        };
        ObjectClicked objectClicked = ObjectClicked("Options.Portrait.${player.entity.getName()}", "", call, null);
        objects.add(objectClicked);
      }
    }

    if(_buttonClose.containsPoint(p))
    {
      Function call = (){onClickClose?.call();};
      ObjectClicked object = ObjectClicked("Options.Close", "", call, null);
      objects.add(object);
    }

    for(BuilderBehaviourItemComponent b in behaviours)
      objects.addAll(b.onClick(p));
    
    if(draggingBehaviour == null)
    {
      for(BuilderBehaviourItemComponent b in behaviours)
      {
        if(b.containsPoint(p))
        {
          Function call = (){
            draggingBehaviour = b;
            gameRef.changePriority(draggingBehaviour!, 1000);
          };
          ObjectClicked object = ObjectClicked("Options.Behaviours.StartDrag.${b.builderBehaviour.name}", "", call, null);
          objects.add(object);
        }
        else
        {
          gameRef.changePriority(b, 900);
        }
      }
    }
    
    return objects;
  }

  void onPanUpdate(DragUpdateInfo info)
  {
    onBehaviourDragging(info);
  }

  void onPanEnd()
  {
    draggingBehaviour?.targetPosition = draggingBehaviour?.initialPosition;
    draggingBehaviour = null;
  }
}

class BuilderBehaviourItemComponent extends SpriteComponent
{
  final OptionsScreen optionsScreen;
  final Entity entity;
  final int index;
  final BuilderBehaviour builderBehaviour;

  late Vector2 initialPosition;
  Vector2? targetPosition;

  late final TextComponent textName;

  late final Sprite torchActivated;
  late final Sprite torchDesactivated;
  late final SpriteComponent torch;

  late final SpriteComponent edit;

  final List<Paint> paints = [];

  BuilderBehaviourItemComponent(this.optionsScreen, this.entity, this.index, this.builderBehaviour, size):super(size: size);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    Sprite spriteLeft = Sprite(ImagesUtils.getImage("cadre_1_left.png"));
    SpriteComponent left = SpriteComponent(sprite: spriteLeft);
    left.size = Vector2(size.y * .3, size.y);
    left.overridePaint = BasicPalette.white.paint();
    paints.add(left.overridePaint!);
    await addChild(left);

    SpriteComponent right = SpriteComponent(sprite: spriteLeft);
    right.size = Vector2(size.y * .3, size.y);
    right.position = Vector2(size.x - right.size.x + 5, 0);
    right.renderFlipX = true;
    right.overridePaint = BasicPalette.white.paint();
    paints.add(right.overridePaint!);
    await addChild(right);

    SpriteComponent middle = SpriteComponent(sprite: Sprite(ImagesUtils.getImage("cadre_1_middle.png")));
    middle.size = Vector2(size.x - right.size.x * 2 + 7, size.y);
    middle.position = Vector2(left.size.x - 1, 0);
    middle.overridePaint = BasicPalette.white.paint();
    paints.add(middle.overridePaint!);
    await addChild(middle);

    torchActivated = Sprite(ImagesUtils.getImage("torch_activated.png"));
    torchDesactivated = Sprite(ImagesUtils.getImage("torch_desactivated.png"));

    torch = SpriteComponent();
    torch.size = Vector2(17, 43);
    torch.position = Vector2.all(size.y / 2);
    torch.anchor = Anchor.center;
    await addChild(torch);

    edit = SpriteComponent(sprite: Sprite(ImagesUtils.getImage("icon_edit.png")));
    edit.size = Vector2.all(30);
    edit.anchor = Anchor.center;
    edit.position = Vector2(size.x - 20, size.y / 2);
    await addChild(edit);

    textName = TextComponent(builderBehaviour.name, textRenderer: textPaint);
    textName.position = Vector2(50, 13);
    //print("TEXT : ${textName.textRenderer}");
    //paints.add(left.overridePaint!);
    await addChild(textName);

    updateActivated();
  }

  void init()
  {
    initialPosition = Vector2.copy(position);
  }

  void updateActivated()
  {
    torch.sprite = builderBehaviour.activated ? torchActivated : torchDesactivated;
    paints.forEach((element) { 
      element.color = element.color.withAlpha(builderBehaviour.activated ? 255 : 150);
    });
  }

  List<ObjectClicked> onClick(Vector2 p) 
  {
    List<ObjectClicked> objects = [];

    if(edit.containsPoint(p))
    {
      Function call = (){optionsScreen.addToHud(PopupBuilderBehaviour(optionsScreen, entity, builderBehaviour), gameRef: optionsScreen.gameRef);};
      ObjectClicked object = ObjectClicked("Options.Behaviour.Edit.${builderBehaviour.name}", TutorielSettings.EVENT_CLICK_OPEN_DETAILS, call, index);
      objects.add(object);
    }

    if(torch.containsPoint(p) && (builderBehaviour.activated || builderBehaviour.isValid(Validator(false))))
    {
      Function call = (){
        builderBehaviour.activated = !builderBehaviour.activated;
        updateActivated();
        Storage.storeEntities();
      };
      ObjectClicked object = ObjectClicked("Options.Behaviour.Torch.${builderBehaviour.name}", "", call, null);
      objects.add(object);
    }
    return objects;
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

class PopupBuilderBehaviour extends SpriteComponent
{
  final AbstractScreen screen;
  final Entity entity;
  final BuilderBehaviour builderBehaviour;

  late final VerticalContainer container;
  late final SpriteComponent _buttonClose;

  late final CibleComponent cibleComponent;
  PopupChooseCible? popupChooseCible;

  late final WorkComponent workComponent;
  PopupChooseWork? popupChooseWork;

  TriComponent? triComponent;

  PopupBuilderBehaviour(this.screen, this.entity, this.builderBehaviour):super(size: Vector2(730, 400), priority: 900)
  {
    screen.gameRef.optionsScreen!.popupBuilderBehaviour = this;
    container = VerticalContainer(screen.gameRef, divider: 20);
    container.position = Vector2(30, 23);

    if(Storage.entity.addTri)
    {
      triComponent = TriComponent(screen.gameRef, builderBehaviour.builderTargetSelector);
      container.add(triComponent!);
      container.add(LineComponent(Vector2(size.x - 60, 4)));
    }

    cibleComponent = CibleComponent(screen.gameRef, builderBehaviour);
    container.add(cibleComponent);
    
    container.add(LineComponent(Vector2(size.x - 60, 4)));
    
    workComponent = WorkComponent(screen.gameRef, builderBehaviour);
    container.add(workComponent);
    
    container.invalidate();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    //print("PopupBuilderBehaviour.onLoad.start");
    sprite = Sprite(ImagesUtils.getImage("cadre_behaviour.png"));
    anchor = Anchor.center;
    position = screen.gameRef.size / 2;

    _buttonClose = SpriteComponent(sprite: Sprite(ImagesUtils.getImage("button_close.png")), position: Vector2(size.x - 32, -6), size: Vector2.all(38));
    await addChild(_buttonClose);
    
    await addChild(container);
    container.invalidate();

    //print("PopupBuilderBehaviour.onLoad.end");
  }

  List<ObjectClicked> onClick(Vector2 p) 
  {
    List<ObjectClicked> objects = [];

    if(popupChooseCible != null)
      objects.addAll(popupChooseCible!.onClick(p));

    if(popupChooseWork != null)
      objects.addAll(popupChooseWork!.onClick(p));
    
    List<ConditionClicked> conditionClicked = cibleComponent.onClick(p);
    for(ConditionClicked o in conditionClicked)
    {
      o.call = (){
        if(popupChooseCible == null)
        {
          popupChooseWork?.remove();
          popupChooseWork = null;
          popupChooseCible = PopupChooseCible(screen, entity, (BuilderCondition b){
            print("SET CONDITION ${o.index} ${b.runtimeType}");
            if(o.index >= builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length)
              builderBehaviour.builderTargetSelector.builderConditionGroup.addCondition();
            builderBehaviour.builderTargetSelector.builderConditionGroup.conditions[o.index] = b;
            cibleComponent.setCible(o.index, b);
            cibleComponent.updateButtonPlus();
            Storage.storeEntities();
            popupChooseCible?.remove();
            popupChooseCible = null;
          });
          popupChooseCible!.size = Vector2(size.x /4 - 15, size.y - 30);
          popupChooseCible!.position = Vector2(size.x /2, 15);
          addChild(popupChooseCible!, gameRef: screen.gameRef);
        }
        else
        {
          popupChooseCible?.remove();
          popupChooseCible = null;
        }  
      };
    }
    objects.addAll(conditionClicked);

    List<WorkClicked> workClicked = workComponent.onClick(p);
    for(WorkClicked w in workClicked)
    {
      w.call = (){
        if(popupChooseWork == null)
        {
          popupChooseCible?.remove();
          popupChooseCible = null;
          popupChooseWork = PopupChooseWork(screen.gameRef, entity, (Work newWork){
            if(newWork != builderBehaviour.builderWork.work)
            {
              builderBehaviour.builderWork.work = newWork;
              workComponent.setWork(newWork);
              Storage.storeEntities();
              popupChooseWork?.remove();
              popupChooseWork = null;
            }
          });
          popupChooseWork!.size = Vector2(size.x /4 - 15, size.y - 30);
          popupChooseWork!.position = Vector2(size.x /2, 15);
          addChild(popupChooseWork!, gameRef: screen.gameRef);
        }
        else
        {
          popupChooseWork?.remove();
          popupChooseWork = null;
        }
      };
    }
    objects.addAll(workClicked);

    if(_buttonClose.containsPoint(p))
    {
      Function call = (){
        screen.gameRef.optionsScreen!.popupBuilderBehaviour = null;
        remove();
      };
      ObjectClicked object = ObjectClicked("Options.PopupBehaviour.Close", TutorielSettings.EVENT_CLICK_CLOSE_POPUP_BEHAVIOUR, call, null);
      objects.add(object);
    }
    
    return objects;
  }
}

class TriComponent extends VerticalContainer
{
  final GameLayout gameRef;
  final BuilderTargetSelector targetSelector;
  late final HorizontalContainer container;

  TriComponent(this.gameRef, this.targetSelector):super(gameRef, divider: 8)
  {
    add(TextSizedComponent(Language.tri.str, textRenderer: textPaint));
    container = HorizontalContainer(gameRef, divider: 10);

    PopupBuildItemComponent item = PopupBuildItemComponent(gameRef, 35, targetSelector.builderTriFunction.value);
    container.add(item);

    add(container);
  }
}

class ButtonBuilderCondition extends PositionComponent
{
  final GameLayout gameRef;

  BuilderCondition builderCondition;
  TextComponent? textComponent;
  SpriteAlphaComponent? button;
  bool editable = false;

  ButtonBuilderCondition(this.gameRef, this.builderCondition)
  {
    _updateSize();
  }

  void setBuilderCondition(BuilderCondition builderCondition)
  {
    children.forEach((element) {element.remove();});
    this.builderCondition = builderCondition;
    _updateSize();
    _updateButton();
  }

  set alpha(int alpha)
  {
    textComponent?.textRenderer = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white.withAlpha(alpha)));
    button?.alpha = alpha;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    await _updateButton();
  }

  void _updateSize()
  {
    if(builderCondition is isEnnemy)
    {
      size = Vector2(150, 40);
      return;
    }

    if(builderCondition is isMe)
    {
      size = Vector2(150, 40);
      return;
    }

    size = Vector2(150, 40);
  }

  Future<void> _updateButton() async
  {
    print("_updateButton $builderCondition");
    
    editable = false;

    if(button != null)
    {
      if(button!.parent != null)
        button!.remove();
      button = null;
    }

    if(textComponent != null)
    {
      if(textComponent!.parent != null)
        textComponent!.remove();
      textComponent = null;
    }

    if(builderCondition is isEnnemy)
    {
      button = SpriteAlphaComponent();
      button!.sprite = Sprite(ImagesUtils.getImage("button_ennemy.png"));
      button!.size = size;
      TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
      textComponent = TextComponent(Language.ennemi.str, textRenderer: textPaint);
      textComponent!.anchor = Anchor.center;
      textComponent!.position = size / 2;
      await button!.addChild(textComponent!);
      await addChild(button!, gameRef: gameRef);
      return;
    }

    if(builderCondition is isMe)
    {
      button = SpriteAlphaComponent();
      button!.sprite = Sprite(ImagesUtils.getImage("button_me.png"));
      button!.size = size;
      TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
      textComponent = TextComponent(Language.moi.str, textRenderer: textPaint);
      textComponent!.anchor = Anchor.center;
      textComponent!.position = size / 2;
      await button!.addChild(textComponent!);
      await addChild(button!, gameRef: gameRef);
      return;
    }

    editable = true;

    button = SpriteAlphaComponent();
    button!.sprite = Sprite(ImagesUtils.getImage("button_large.png"));
    button!.size = size;
    await addChild(button!, gameRef: gameRef);

    HorizontalContainer container = HorizontalContainer(gameRef, divider: 8);
    container.anchor = Anchor.center;
    container.position = button!.size / 2;
    await button!.addChild(container, gameRef: gameRef);

    PopupBuildItemComponent item0 = PopupBuildItemComponent(gameRef, 35, builderCondition.params[2]);
    container.add(item0);
    
    PopupBuildItemComponent itemCond = PopupBuildItemComponent(gameRef, 35, builderCondition.cond);
    container.add(itemCond);

    PopupBuildItemComponent item2 = PopupBuildItemComponent(gameRef, 35, builderCondition.params[1]);
    container.add(item2);

    await container.loadChildren();
  }
}

class BuilderConditionComponent extends HorizontalContainer
{
  final GameLayout gameRef;
  final int index;
  final BuilderCondition builderCondition;
  final List<ClickableObject> objects = [];
  late final ButtonBuilderCondition buttonBuilderCondition;

  BuilderConditionComponent(this.gameRef, this.index, this.builderCondition):super(gameRef)
  {
    buttonBuilderCondition = ButtonBuilderCondition(gameRef, builderCondition);
    add(buttonBuilderCondition);
    size = buttonBuilderCondition.size;
  }

  void setBuilderCondition(BuilderCondition builderCondition)
  {
    buttonBuilderCondition.setBuilderCondition(builderCondition);
    size = buttonBuilderCondition.size;
    invalidate();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    ConditionClicked objectClicked = ConditionClicked(index, "Options.Condition.${builderCondition.toMap()}", TutorielSettings.EVENT_CLICK_BEHAVIOUR_PARAM, null, 0);
    ClickableObject object = ClickableObject(objectClicked, buttonBuilderCondition);
    objects.add(object);
  }

  List<ConditionClicked> onClick(Vector2 p) 
  {
    List<ConditionClicked> result = [];
    for(ClickableObject c in objects)
    {
      if(c.contains(p))
        result.add(c.object as ConditionClicked);
    }
    return result;
  }
}

class ConditionClicked extends ObjectClicked
{
  final int index;

  ConditionClicked(this.index, String name, String event, Function? call, dynamic params):super(name, event, call, params);
}

class CibleComponent extends VerticalContainer
{
  final BuilderBehaviour builderBehaviour;
  final List<BuilderConditionComponent> conditionsComponents = [];
  late final HorizontalContainer conditionsContainer;
  late final HorizontalContainer container;
  SpriteAlphaComponent? buttonPlus;

  CibleComponent(GameLayout gameRef, this.builderBehaviour):super(gameRef)
  {
    add(TextSizedComponent(Language.target.str, textRenderer: textPaint));
    container = HorizontalContainer(gameRef, divider: 10);
    conditionsContainer = HorizontalContainer(gameRef, divider: 10);
    int nbConditions = builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length;
    for(int i = 0; i < nbConditions; i++)
    {
      _addCondition(i);
    }

    container.add(conditionsContainer);
    updateButtonPlus();

    add(container);
  }

  BuilderConditionComponent _addCondition(int i)
  {
    print("_addCondition $i");
    BuilderCondition builderCondition = builderBehaviour.builderTargetSelector.builderConditionGroup.conditions[i];
    BuilderConditionComponent conditionComponent = BuilderConditionComponent(gameRef, i, builderCondition);
    conditionsComponents.add(conditionComponent);
    conditionsContainer.add(conditionComponent);
    return conditionComponent;
  }

  void updateButtonPlus()
  {
    int nbConditions = builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length;
    if(nbConditions < 4 && Storage.entity.addCondition)
    {
      if(buttonPlus == null)
      {
        buttonPlus = SpriteAlphaComponent();
        buttonPlus!.sprite = Sprite(ImagesUtils.getImage("button_plus.png"));
        buttonPlus!.size = Vector2.all(40);
        container.add(buttonPlus!);
      }
      buttonPlus!.alpha = Storage.entity.nbCombat > 1 || nbConditions <= 1 ? 255 : 40;
    }
    else if(buttonPlus != null)
    {
      buttonPlus!.remove();
      buttonPlus = null;
    }
  }

  void setCible(int index, BuilderCondition builderCondition)
  {
    print("setCible $index $builderCondition");
    if(index >= conditionsComponents.length)
    {
      BuilderConditionComponent element = _addCondition(index);
      container.onAddedElement(element);
    }
    else
    {
      conditionsComponents[index].setBuilderCondition(builderCondition);
    }
    conditionsContainer.invalidate();
    container.invalidate();
  }

  List<ConditionClicked> onClick(Vector2 p) 
  {
    List<ConditionClicked> objects = [];
    for(BuilderConditionComponent b in conditionsComponents)
      objects.addAll(b.onClick(p));
    if(buttonPlus != null && buttonPlus!.containsPoint(p))
    {
      Function call = (){

      };
      ConditionClicked object = ConditionClicked(builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length, "PopupBehaviour.Conditions.Plus", TutorielManyEnnemies.EVENT_CLICK_CONDITIONS_PLUS, call, builderBehaviour.builderTargetSelector.builderConditionGroup.conditions);
      objects.add(object);
    }

    return objects;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    invalidate();
  }
}

class WorkComponent extends VerticalContainer
{
  final BuilderBehaviour builderBehaviour;
  late final BuilderWorkComponent builderWorkComponent;

  WorkComponent(GameLayout gameRef, this.builderBehaviour):super(gameRef)
  {
    add(TextSizedComponent(Language.action.str, textRenderer: textPaint));
    BuilderWork builderWork = builderBehaviour.builderWork;
    builderWorkComponent = BuilderWorkComponent(gameRef, builderWork);
    add(builderWorkComponent);
  }

  void setWork(Work work)
  {
    builderWorkComponent.button.setWork(work);
  }

  List<WorkClicked> onClick(Vector2 p) 
  {
    return builderWorkComponent.onClick(p);
  }
}

class WorkClicked extends ObjectClicked
{
  WorkClicked(String name, String event, Function? call, dynamic params):super(name, event, call, params);
}

class PopupChooseCible extends PopupChoose
{
  final AbstractScreen screen;
  final Entity entity;
  final Function onChooseCible;
  final List<ClickableObject> objects = [];

  PopupBuild? popupBuild;

  PopupChooseCible(this.screen, this.entity, this.onChooseCible):super(Language.targets.str);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    List<BuilderCondition> dispo = entity.availablesBuilderConditions();
    int i;
    late ButtonBuilderCondition b;
    for(i = 0; i < dispo.length; i++)
    {
      BuilderCondition c = dispo[i];
      b = ButtonBuilderCondition(screen.gameRef, c);
      await addChild(b);
      b.position = Vector2(.05 * size.x, startY + 2 + (5 + b.size.y) * i);
      b.size = Vector2(.9 * size.x / 2, b.size.y);
      bool isAvailable = true;
      if(c is isEnnemy)
      {
        isAvailable = !Storage.entity.addCondition || Storage.entity.nbCombat > 1;
      } 
      if(c is isMe)
      {
        isAvailable = Storage.entity.nbCombat > 1 || (!Storage.entity.buildButton && Storage.entity.addCondition && Storage.entity.nbCombat >= 1);
      }
      b.alpha = isAvailable ? 255 : 40;
      if(isAvailable)
      {
        Function call = (){onChooseCible(c);};
        ObjectClicked objectClicked = ObjectClicked("PopupChooseCible.Cible.${c.cond.toString()}", "", call, c);
        ClickableObject object = ClickableObject(objectClicked, b);
        objects.add(object);
      }
    }

    ButtonBuild buttonBuild = ButtonBuild(screen.gameRef, Vector2(.9 * size.x, b.size.y), Language.nouveau.str, "icon_build.png");
    buttonBuild.position = Vector2(.05 * size.x, startY + 2 + (5 + b.size.y) * i);
    bool isAvailable = Storage.entity.nbCombat > 2 || Storage.entity.buildButton;
    buttonBuild.alpha = isAvailable ? 255 : 40;
    if(isAvailable)
    {
      Function call = ()async{
        popupBuild = PopupBuildCondition(entity, null, screen.gameRef, Vector2(300, 400), (BuilderCondition builderCondition){
          onChooseCible(builderCondition);
        });
        await screen.addToHud(popupBuild!, gameRef: screen.gameRef);
      };
      ObjectClicked objectClicked = ObjectClicked("PopupChooseCible.Cible.Build", TutorielManyEnnemies.EVENT_CLICK_CONDITIONS_NOUVEAU, call, "build");
      ClickableObject object = ClickableObject(objectClicked, buttonBuild);
      objects.add(object);
    }
    await addChild(buttonBuild);
  }

  @override
  List<ObjectClicked> onClick(Vector2 p)
  {
    List<ObjectClicked> result = [];
    result.addAll(popupBuild?.onClick(p)??[]);
    for(ClickableObject c in objects)
    {
      if(c.contains(p))
        result.add(c.object);
    }
    return result;
  }
}

class ButtonBuild extends SpriteAlphaComponent
{
  late final HorizontalContainer container;
  late final TextSizedComponent text;
  SpriteAlphaComponent? icon = null;
  
  ButtonBuild(GameLayout gameRef, Vector2 size, String str, String? strIcon):super(size: size)
  {
    sprite = Sprite(ImagesUtils.getImage("button_large.png"));

    container = HorizontalContainer(gameRef, divider: 5);
    text = TextSizedComponent(str, textRenderer: textPaintWhite);
    container.add(text);
    if(strIcon != null)
    {
      icon = SpriteAlphaComponent();
      icon!.sprite = Sprite(ImagesUtils.getImage(strIcon));
      icon!.size = Vector2.all(size.y - 12);
      container.add(icon!);  
    }
    container.anchor = Anchor.center;
    container.position = size / 2;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    await addChild(container);
  }

  set alpha(int alpha)
  {
    super.alpha = alpha;
    text.textRenderer = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white.withAlpha(alpha)));
    icon?.alpha = alpha;
  }
}

class PopupChooseWork extends PopupChoose
{
  final GameLayout gameRef;
  final Entity entity;
  final Function onChooseWork;
  final List<ClickableObject> objects = [];

  PopupChooseWork(this.gameRef, this.entity, this.onChooseWork):super(Language.actions.str);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    List<Work> dispo = entity.availablesWorks();
    for(int i = 0; i < dispo.length; i++)
    {
      Work w = dispo[i];
      ButtonWork b = ButtonWork(w);
      await addChild(b);
      b.position = Vector2(.05 * size.x, startY + 2 + (5 + b.size.y) * i);
      b.size = Vector2(.9 * size.x, b.size.y);
      bool isAvailable = Storage.entity.nbCombat > 1;
      if(Storage.entity.nbCombat == 0 && w == Work.attaquer)
        isAvailable = true;
      if(Storage.entity.nbCombat == 1 && w == Work.bandage)
        isAvailable = true; 
      b.alpha = isAvailable ? 255 : 40;
      if(isAvailable)
      {
        Function call = (){onChooseWork(w);};
        ObjectClicked clicked = ObjectClicked("PopupChooseWork.Work.${w.name}", "", call, null);
        ClickableObject object = ClickableObject(clicked, b);
        objects.add(object);
      }
    }
  }

  @override
  List<ObjectClicked> onClick(Vector2 p)
  {
    List<ObjectClicked> result = [];
    for(ClickableObject c in objects)
    {
      if(c.contains(p))
        result.add(c.object);
    }
    return result;
  }
}

class ClickableObject
{
  ObjectClicked object;
  PositionComponent component;

  ClickableObject(this.object, this.component);

  bool contains(Vector2 p) => component.containsPoint(p);
}

class PopupChoose extends PositionComponent
{
  final String title;
  late final double startY;

  PopupChoose(this.title);

  @override
  Future<void> onLoad() async 
  {
    await init();
    await super.onLoad();
    Paint paint = BasicPalette.white.withAlpha(255).paint();
    addChild(SpriteComponent(overridePaint: paint, sprite: _centerTop, size: Vector2(size.x - square2 +2, square), position: Vector2(square -1, 0)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _centerBottom, size: Vector2(size.x - square2 +2, square), position: Vector2(square-1, size.y - square)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _centerLeft, size: Vector2(square, size.y - square2 + 2), position: Vector2(0, square-1)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _centerRight, size: Vector2(square, size.y - square2 + 2), position: Vector2(size.x-square, square-1)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _cornerTopLeft, size: Vector2.all(square)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _cornerTopRight, size: Vector2.all(square), position: Vector2(size.x - square, 0)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _cornerBottomLeft, size: Vector2.all(square), position: Vector2(0, size.y - square)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _cornerBottomRight, size: Vector2.all(square), position: Vector2(size.x - square, size.y - square)));
    addChild(SpriteComponent(overridePaint: paint, sprite: _center, size: size - Vector2.all(square2 -2), position: Vector2.all(square -1)));

    TextComponent txt = TextComponent(title, textRenderer: TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white)));
    txt.anchor = Anchor.topCenter;
    txt.position = Vector2(size.x / 2, 5);
    await addChild(txt);

    LineComponent line = LineComponent(Vector2(size.x - 8, 3), color: Colors.white);
    line.position = Vector2(4, txt.textRenderer.measureTextHeight(title) + 8);
    await addChild(line);

    startY = line.position.y + line.size.y + 5;
  }

  List<ObjectClicked> onClick(Vector2 p)
  {
    return [];
  }

  static bool inited = false;
  static late final Sprite _cornerTopLeft;
  static late final Sprite _cornerTopRight;
  static late final Sprite _cornerBottomLeft;
  static late final Sprite _cornerBottomRight;
  static late final Sprite _center;
  static late final Sprite _centerTop;
  static late final Sprite _centerBottom;
  static late final Sprite _centerLeft;
  static late final Sprite _centerRight;
  static final double square = 19;
  static final double square2 = square * 2;
  static init() async
  {
    if(inited)
      return;

    inited = true;
    //print("Popup.init.start");
    try
    {
      //print("Popup.init.sheet.ok");
      SpriteSheet gui = ImagesUtils.getGUI("gui.png");
      _cornerTopLeft = gui.getSprite(0, 0);
      _cornerTopRight = gui.getSprite(0, 2);
      _cornerBottomLeft = gui.getSprite(2, 0);
      _cornerBottomRight = gui.getSprite(2, 2);
      _center = gui.getSprite(1, 1);
      _centerTop = gui.getSprite(0, 1);
      _centerBottom = gui.getSprite(2, 1);
      _centerLeft = gui.getSprite(1, 0);
      _centerRight = gui.getSprite(1, 2);
    }
    catch(e)
    {
      print(e);
    }
    //print("Popup.init.end");
  }
}

class ButtonWork extends PositionComponent
{
  late final TextComponent textComponent;
  late final SpriteAlphaComponent button;
  late Work work;

  ButtonWork(this.work)
  {
    button = SpriteAlphaComponent();
    TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
    textComponent = TextComponent("", textRenderer: textPaint);
    textComponent.anchor = Anchor.center;
    size = Vector2(textPaint.measureTextWidth(this.work.name) + 60, 40);  
  }

  set alpha(int alpha)
  {
    textComponent.textRenderer = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white.withAlpha(alpha)));
    button.alpha = alpha;
  }

  void setWork(Work work)
  {
    print("setWork $work");
    textComponent.text = work.name;
    size = Vector2(textPaint.measureTextWidth(work.name) + 60, 40);
    textComponent.position = size / 2;
    if(work is Aucun)
      button.sprite = spriteNone;
    else if(work is MagicWork)
      button.sprite = spriteMagie;
    else
      button.sprite = spriteAction;
    button.size = size;
  }

  @override
  set size(Vector2 size) 
  {
    super.size = size;
    button.size = size;
    textComponent.position = size / 2;
  }

  @override
  Future<void> onLoad() async 
  {
    await init();
    await super.onLoad();
    setWork(work);
    await addChild(button);
    await button.addChild(textComponent);
  }

  static late final Sprite spriteNone;
  static late final Sprite spriteAction;
  static late final Sprite spriteMagie;
  static bool inited = false;
  static Future<void> init() async
  {
    if(inited)
      return;

    inited = true;
    spriteNone = Sprite(ImagesUtils.getImage("button_none.png"));
    spriteAction = Sprite(ImagesUtils.getImage("button_work.png"));
    spriteMagie = Sprite(ImagesUtils.getImage("button_magic.png"));
  }
}

class BuilderWorkComponent extends PositionComponent
{
  final GameLayout gameRef;
  final BuilderWork builderWork;
  late final ButtonWork button;

  BuilderWorkComponent(this.gameRef, this.builderWork)
  {
    button = ButtonWork(builderWork.work ?? Work.aucun);
    size = button.size;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    await addChild(button);
    size = button.size;
  }

  List<WorkClicked> onClick(Vector2 p) 
  {
    if(button.containsPoint(p))
    {
      return [WorkClicked("BuilderWork.Work", TutorielSettings.EVENT_CLICK_BEHAVIOUR_PARAM, null, 1)];
    }
    return [];
  }
}

class LineComponent extends PositionComponent
{
  late Rect rect;
  late final Paint paint;

  LineComponent(Vector2 size, {Color color = Colors.black}):super(size: size)
  {
    rect = Rect.fromLTWH(0, 0, size.x, size.y);
    paint = Paint()..color = color;
  }

  @override
  set position(Vector2 p)
  {
    super.position = p;
    rect = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  @override
  void render(Canvas canvas)
  {
    super.render(canvas);
    canvas.drawRect(rect, paint);
  }
}

class Player extends SpriteComponent
{
  final Entity entity;
  late final Paint playerPaint;

  Player(this.entity):super(size: Vector2(70, 80));
  
  @override
  Future<void> onLoad() async 
  {
    //print("Player.onLoad");
    await super.onLoad();
    final SpriteComponent player = SpriteComponent();
    player.sprite = Sprite(ImagesUtils.getImage("portrait.png"));
    player.size = Vector2(72, 72);
    player.anchor = Anchor.bottomCenter;
    player.position = Vector2(size.x / 2, size.y);
    player.overridePaint = BasicPalette.white.paint();
    playerPaint = player.overridePaint!;
    addChild(player);

    sprite = Sprite(ImagesUtils.getImage("cadre_player.png"));
    overridePaint = BasicPalette.white.paint();
    //print("Player.onLoaded");
  }

  void updateSelected(bool selected)
  {
    overridePaint!.color = overridePaint!.color.withAlpha(selected ? 255 : 150);
    playerPaint.color = playerPaint.color.withAlpha(selected ? 255 : 150);
  }
}

class Popup extends SpriteComponent
{
  static bool inited = false;
  static late final Sprite _cornerTopLeft;
  static late final Sprite _cornerTopRight;
  static late final Sprite _cornerBottomLeft;
  static late final Sprite _cornerBottomRight;
  static late final Sprite _center;
  static late final Sprite _centerTop;
  static late final Sprite _centerBottom;

  static final double square = 19;
  static final double square2 = square * 2;

  static init() async
  {
    if(inited)
      return;

    inited = true;
    //print("Popup.init.start");
    try
    {
      //print("Popup.init.sheet.ok");
      SpriteSheet gui = ImagesUtils.getGUI("gui.png");
      _cornerTopLeft = gui.getSprite(7, 0);
      _cornerTopRight = gui.getSprite(7, 3);
      _cornerBottomLeft = gui.getSprite(10, 0);
      _cornerBottomRight = gui.getSprite(10, 3);
      _center = gui.getSprite(1, 13);
      _centerTop = gui.getSprite(7, 1);
      _centerBottom = gui.getSprite(10, 1);
    }
    catch(e)
    {
      print(e);
    }
    //print("Popup.init.end");
  }

  Popup(Vector2 size):super(size: size);

  @override
  Future<void> onLoad() async 
  {
    //print("Popup.onLoad.start");
    await init();
    await super.onLoad();

    addChild(SpriteComponent(sprite: _centerTop, size: Vector2(size.x - square2, square), position: Vector2(square, 0)));
    addChild(SpriteComponent(sprite: _centerBottom, size: Vector2(size.x - square2, square), position: Vector2(square, size.y - square)));

    final left = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(square, square));
    left.angle = degrees2Radians * 90;
    addChild(left);

    final right = SpriteComponent(sprite: _centerBottom, size: Vector2(size.y - square2, square), position: Vector2(size.x, square));
    right.angle = degrees2Radians * 90;
    right.renderFlipY = true;
    addChild(right);

    addChild(SpriteComponent(sprite: _cornerTopLeft, size: Vector2.all(square)));
    addChild(SpriteComponent(sprite: _cornerTopRight, size: Vector2.all(square), position: size - Vector2(square, size.y)));
    addChild(SpriteComponent(sprite: _cornerBottomLeft, size: Vector2.all(square), position: size - Vector2(size.x, square)));
    addChild(SpriteComponent(sprite: _cornerBottomRight, size: Vector2.all(square), position: size - Vector2(square, square)));
    addChild(SpriteComponent(sprite: _center, size: size - Vector2.all(square2), position: Vector2(square, square)));
    //print("Popup.onLoad.end");
  }
}

abstract class LinedContainer extends PositionComponent
{
  final GameLayout gameRef;
  final List<PositionComponent> items = [];
  final int divider;

  LinedContainer(this.gameRef, this.divider);

  void add(PositionComponent component)
  {
    items.add(component);
    invalidate();
  }

  void removeAllChidren()
  {
    items.clear();
    children.forEach((element) {element.remove();});
  }

  void onAddedElement(PositionComponent element) async
  {
    await addChild(element, gameRef: gameRef);
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    await loadChildren();
  }

  Future<void> loadChildren() async
  {
    for(PositionComponent item in items)
      await addChild(item, gameRef: gameRef);
  }

  void invalidate();
}

class VerticalContainer extends LinedContainer
{
  VerticalContainer(GameLayout gameRef, {int divider = 0}):super(gameRef, divider);

  @override
  void invalidate()
  {
    for(int i = 1; i < items.length; i++)
    {
      PositionComponent last = items[i - 1];
      PositionComponent current = items[i];
      current.position = Vector2(0, last.position.y + last.size.y + divider);
    }
  }

  @override
  Vector2 get size
  {
    if(items.isEmpty)
      return Vector2.all(0);

    double maxW = 0;
    items.forEach((element) { 
      if(element.size.x > maxW)
        maxW = element.size.x;
    });
    return Vector2(maxW, items.last.position.y +  items.last.size.y + divider);
  }
}

class HorizontalContainer extends LinedContainer
{
  HorizontalContainer(GameLayout gameRef, {int divider = 0}):super(gameRef, divider);

  @override
  void invalidate()
  {
    for(int i = 1; i < items.length; i++)
    {
      PositionComponent last = items[i - 1];
      PositionComponent current = items[i];
      current.position = Vector2(last.position.x + last.size.x + divider, 0);
    }
  }

  @override
  Vector2 get size
  {
    if(items.isEmpty)
      return Vector2.all(0);

    double maxH = 0;
    items.forEach((element) { 
      if(element.size.y > maxH)
        maxH = element.size.y;
    });
    return Vector2(items.last.position.x + items.last.size.x, maxH);
  }
}

class TextSizedComponent extends TextComponent
{
  TextSizedComponent(String text, {TextRenderer? textRenderer}):super(text, textRenderer: textRenderer)
  {
    if(textRenderer != null)
      size = Vector2(textRenderer.measureTextWidth(text), textRenderer.measureTextHeight(text));
  }
}

class SpriteAlphaComponent extends SpriteComponent
{
  SpriteAlphaComponent({Vector2? size}):super(overridePaint: BasicPalette.white.withAlpha(255).paint(), size: size);

  set alpha(int alpha)
  {
    overridePaint = BasicPalette.white.withAlpha(alpha).paint();
  }

  int get alpha{
    return overridePaint!.color.alpha;
  }
}

class PopupBuildItemComponent extends SpriteAlphaComponent
{
  late final TextComponent text;
  final GameLayout gameRef;
  
  PopupBuildItemComponent(this.gameRef, double size, dynamic pItem):super(size: Vector2.all(size))
  {
    text = TextSizedComponent("", textRenderer: textPaintWhite);
    text.anchor = Anchor.center;
    text.position = this.size / 2;
    item = pItem;
    addChild(text, gameRef: gameRef);
  }

  set item(dynamic item)
  {
    print("Update Item $item");
    sprite = null;
    text.text = "";
    if(item is VALUE)
      sprite = Sprite(ImagesUtils.getImage(item.image));

    else if(item is Conditions)
      sprite = Sprite(ImagesUtils.getImage(item.image));

    else if(item is ValueAtom)
      text.text = item.value.toString();
  }

  set alpha(int alpha)
  {
    super.alpha = alpha;
    text.textRenderer = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white.withAlpha(alpha)));
  }
} 

class PopupBuildCondition extends PopupBuild
{
  final Entity entity;
  late final BuilderCondition builderCondition;

  final List<SpriteAlphaComponent> containers = [];
  final List<PopupBuildItemComponent> items = [];
  final List<ClickableObject> objects = [];

  late final GridContainer grid;
  late final ButtonBuild btnValider;

  final Function onEnd;

  int selectedIndex = 0;

  PopupBuildCondition(this.entity, BuilderCondition? builderCondition, GameLayout gameRef, Vector2 popupSize, this.onEnd):super(gameRef, popupSize)
  {
    if(builderCondition == null)
      builderCondition = BuilderCondition();
    this.builderCondition = builderCondition;

    grid = GridContainer(gameRef, 4, divider: 5);
    grid.anchor = Anchor.topCenter;
    grid.position = Vector2(size.x / 2, 170);
    _updateGrid(isReload: false);

    //builderCondition.setCondition(Conditions.LOWER);
    //builderCondition.setParam(1, ValueAtom(25));
    //builderCondition.setParam(2, VALUE.HP_PERCENT);
    //builderCondition.setParam(0, entity.builder);
  }

  void _updateGrid({bool isReload = true})
  {
    objects.clear();
    grid.removeAllChidren();

    Function addItem = (dynamic item, int alpha, Function setParam){
      PopupBuildItemComponent s = PopupBuildItemComponent(gameRef, 60, item);
      s.alpha = alpha;
      if(alpha == 255){
        Function call = (){
          setParam.call();
          int prevIndex = selectedIndex;
          selectedIndex = min(selectedIndex + 1, 2);
          _update();
          if(prevIndex < 2)
            _updateGrid();
        };
        ObjectClicked object = ObjectClicked(item.runtimeType.toString(), "", call, null);
        ClickableObject clickable = ClickableObject(object, s);
        objects.add(clickable);
      }
      grid.add(s);
    };

    if(selectedIndex == 0)
    {
      addItem(VALUE.HP, 150, (){builderCondition.setParam(2, VALUE.HP);});
      addItem(VALUE.HP_PERCENT, 255, (){builderCondition.setParam(2, VALUE.HP_PERCENT);});
    }
    
    if(selectedIndex == 1)
    {
      addItem(Conditions.LOWER, 255, (){builderCondition.setCondition(Conditions.LOWER);});
      addItem(Conditions.HIGHER, 150, (){builderCondition.setCondition(Conditions.HIGHER);});
    }

    if(selectedIndex == 2)
    {
      addItem(ValueAtom(10), 150, (){builderCondition.setParam(1, ValueAtom(10));});
      addItem(ValueAtom(20), 255, (){builderCondition.setParam(1, ValueAtom(20));});
      addItem(ValueAtom(30), 150, (){builderCondition.setParam(1, ValueAtom(30));});
      addItem(ValueAtom(40), 150, (){builderCondition.setParam(1, ValueAtom(40));});
      addItem(ValueAtom(50), 150, (){builderCondition.setParam(1, ValueAtom(50));});
      addItem(ValueAtom(60), 150, (){builderCondition.setParam(1, ValueAtom(60));});
      addItem(ValueAtom(70), 150, (){builderCondition.setParam(1, ValueAtom(70));});
      addItem(ValueAtom(80), 150, (){builderCondition.setParam(1, ValueAtom(80));});
      addItem(ValueAtom(90), 150, (){builderCondition.setParam(1, ValueAtom(90));});
      addItem(ValueAtom(100), 150, (){builderCondition.setParam(1, ValueAtom(100));});
    }

    if(isReload)
      grid.loadChildren();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    await createContainer()..position = Vector2(size.x / 2 - 64 - 5, 90);
    await createContainer()..position = Vector2(size.x / 2, 90);
    await createContainer()..position = Vector2(size.x / 2 + 64 + 5, 90);
    await addChild(grid);

    btnValider = ButtonBuild(gameRef, Vector2(150, 40), Language.valider.str, null);
    btnValider.position = Vector2(size.x / 2, 440);
    btnValider.anchor = Anchor.center;
    btnValider.alpha = 150;
    await addChild(btnValider);
  }

  void _update()
  {
    _updateIndex(0);
    _updateIndex(1);
    _updateIndex(2);
    btnValider.alpha = _getParam(0) != null && _getParam(1) != null && _getParam(2) != null ? 255 : 150;
  }

  void _updateIndex(int index)
  {
    late dynamic param = _getParam(index);
    items[index].item = param;
    if(index == selectedIndex)
    {
      containers[index].alpha = 255;
    }
    else if(param == null)
    {
      containers[index].alpha = 150;
    }
    print(param.runtimeType);
  }

  dynamic _getParam(int index)
  {
    print("_getParam $index : ${builderCondition.params.length}");
    if(index == 0 && builderCondition.params.length == 3)
      return builderCondition.params[2];
    if(index == 2 && builderCondition.params.length >= 2)
      return builderCondition.params[1];
    return builderCondition.cond;
  }

  Future<SpriteComponent> createContainer() async
  {
    SpriteAlphaComponent container = SpriteAlphaComponent();
    container.sprite = Sprite(ImagesUtils.getImage("icon_builder_container.png"));
    container.size = Vector2.all(64);
    container.anchor = Anchor.topCenter;
    await addChild(container);
    containers.add(container);
    PopupBuildItemComponent item = PopupBuildItemComponent(gameRef, container.size.x - 16, null);
    item.anchor = Anchor.center;
    item.position = container.size / 2;
    await container.addChild(item);
    items.add(item);
    _updateIndex(containers.length - 1);
    return container;
  }

  List<ObjectClicked> onClick(Vector2 p)
  {
    List<ObjectClicked> result = [];

    if(selectedIndex != 0)
    {
      if(containers[0].containsPoint(p))
      {
        Function callParam0 = (){
          print("callParam0");
          selectedIndex = 0;
          _update();
          _updateGrid();
        };
        ObjectClicked param0 = ObjectClicked("PopupBuildCondition.Param0", "", callParam0, null);
        result.add(param0);
      }
    }
    
    if(selectedIndex != 1 && _getParam(0) != null)
    {
      if(containers[1].containsPoint(p))
      {
        Function callParam1 = (){
          print("callParam1");
          selectedIndex = 1;
          _update();
          _updateGrid();
        };
        ObjectClicked param1 = ObjectClicked("PopupBuildCondition.Param1", "", callParam1, null);
        result.add(param1);
      }
    }

    if(selectedIndex != 2 && _getParam(1) != null)
    {
      if(containers[2].containsPoint(p))
      {
        Function callParam2 = (){
          print("callParam2");
          selectedIndex = 2;
          _update();
          _updateGrid();
        };
        ObjectClicked param2 = ObjectClicked("PopupBuildCondition.Param2", "", callParam2, null);
        result.add(param2);
      }
    }

    objects.forEach((element) {
      if(element.component.containsPoint(p))
        result.add(element.object);
    });

    if(btnValider.alpha == 255)
    {
      Function call = (){
        remove();
        Storage.entity.addTri = true;
        onEnd(builderCondition);
      };
      ObjectClicked object = ObjectClicked("ButtonValider", "", call, null);
      result.add(object);
    }

    result.addAll(super.onClick(p));
    return result;
  }
}

class PopupBuild extends PositionComponent
{
  final GameLayout gameRef;
  late final Rect bgRect;
  late final Paint bgPaint;
  final Vector2 popupSize;

  PopupBuild(this.gameRef, this.popupSize):super(size: gameRef.size, priority: 901)
  {
    bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
    bgPaint = BasicPalette.black.withAlpha(150).paint();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    SpriteComponent popup = SpriteComponent.fromImage(ImagesUtils.getImage("popup_build_vertical.png"));
    popup.size = popupSize;
    popup.anchor = Anchor.center;
    popup.position = size / 2;
    await addChild(popup);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    super.render(canvas);
  }

  List<ObjectClicked> onClick(Vector2 p)
  {
    List<ObjectClicked> objects = [];

    objects.add(ObjectClicked("PopupBuild", "", null, null));
    return objects;
  }
}

class GridContainer extends VerticalContainer
{
  final int columns;
  
  GridContainer(GameLayout gameRef, this.columns, {int divider = 0}):super(gameRef, divider:divider);

  @override
  void add(PositionComponent component)
  {
    if(items.length == 0 || (items[items.length -1] as LinedContainer).items.length >= columns)
    {
      HorizontalContainer container = HorizontalContainer(gameRef, divider: divider);
      super.add(container);
    }
    LinedContainer lastContainer = (items[items.length - 1] as LinedContainer);
    lastContainer.add(component);
  }
}