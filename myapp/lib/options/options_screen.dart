import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flame/palette.dart';
import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
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

    _buttonClose = SpriteComponent(sprite: Sprite(await ImagesUtils.loadImage("button_close.png")), position: Vector2(cadre.size.x - 38, 0), size: Vector2.all(38));
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
    for(BuilderBehaviour behaviour in selectedEntity.builder.builderTotal.builderBehaviours)
      addBuilderBehaviour(behaviour);
  }

  void addBuilderBehaviour(BuilderBehaviour behaviour)
  {
    BuilderBehaviourItemComponent behaviourComponent = BuilderBehaviourItemComponent(gameRef, this, selectedEntity, behaviour, Vector2(cadre.size.x - 30, cadre.size.y / 7.2));
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
  bool onClick(Vector2 p) 
  {
    if(popupBuilderBehaviour != null)
    {
      popupBuilderBehaviour?.onClick(p);
      return true;
    }

    for(Player player in players)
    {
      if(player.containsPoint(p))
      {
        selectedEntity = player.entity;
        updateSelectedPlayer();
        return true;
      }
    }

    if(_buttonClose.containsPoint(p))
    {
      onClickClose?.call();
      return true;
    }

    for(BuilderBehaviourItemComponent b in behaviours)
    {
      if(b.onClick(p))
        return true;
    }

    if(draggingBehaviour == null)
    {
      for(BuilderBehaviourItemComponent b in behaviours)
      {
        if(b.containsPoint(p))
        {
          draggingBehaviour = b;
          gameRef.changePriority(draggingBehaviour!, 1000);
        }
        else
        {
          gameRef.changePriority(b, 900);
        }
      }
    }
    
    return true;
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
  final GameLayout gameRef;
  final OptionsScreen optionsScreen;
  final Entity entity;
  final BuilderBehaviour builderBehaviour;

  late Vector2 initialPosition;
  Vector2? targetPosition;

  late final TextComponent textName;

  late final Sprite torchActivated;
  late final Sprite torchDesactivated;
  late final SpriteComponent torch;

  late final SpriteComponent edit;

  final List<Paint> paints = [];

  BuilderBehaviourItemComponent(this.gameRef, this.optionsScreen, this.entity, this.builderBehaviour, size):super(size: size);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    Sprite spriteLeft = Sprite(await ImagesUtils.loadImage("cadre_1_left.png"));
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

    SpriteComponent middle = SpriteComponent(sprite: Sprite(await ImagesUtils.loadImage("cadre_1_middle.png")));
    middle.size = Vector2(size.x - right.size.x * 2 + 5, size.y);
    middle.position = Vector2(left.size.x, 0);
    middle.overridePaint = BasicPalette.white.paint();
    paints.add(middle.overridePaint!);
    await addChild(middle);

    torchActivated = Sprite(await ImagesUtils.loadImage("torch_activated.png"));
    torchDesactivated = Sprite(await ImagesUtils.loadImage("torch_desactivated.png"));

    torch = SpriteComponent();
    torch.size = Vector2(17, 43);
    torch.position = Vector2.all(size.y / 2);
    torch.anchor = Anchor.center;
    await addChild(torch);

    edit = SpriteComponent(sprite: Sprite(await ImagesUtils.loadImage("icon_edit.png")));
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

  bool onClick(Vector2 p) 
  {
    if(gameRef.tutorielScreen != null && gameRef.tutorielScreen!.onClick(p))
      return true;

    if(edit.containsPoint(p))
    {
      optionsScreen.addChild(PopupBuilderBehaviour(gameRef, entity, builderBehaviour), gameRef: gameRef);
      gameRef.tutorielScreen?.onEvent(TutorielSettings.EVENT_CLICK_OPEN_DETAILS);
      return true;
    }

    if(gameRef.tutorielScreen != null)
      return true;

    if(torch.containsPoint(p) && (builderBehaviour.activated || builderBehaviour.isValid(Validator(false))))
    {
      builderBehaviour.activated = !builderBehaviour.activated;
      updateActivated();
      Storage.storeEntities();
      return true;
    }
    return false;
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
  final GameLayout gameRef;
  final Entity entity;
  final BuilderBehaviour builderBehaviour;

  late final VerticalContainer container;
  late final SpriteComponent _buttonClose;

  late final CibleComponent cibleComponent;

  late final WorkComponent workComponent;
  PopupChooseCible? popupChooseCible;
  PopupChooseWork? popupChooseWork;

  PopupBuilderBehaviour(this.gameRef, this.entity, this.builderBehaviour):super(size: Vector2(730, 400), priority: 900)
  {
    gameRef.optionsScreen!.popupBuilderBehaviour = this;
    container = VerticalContainer(gameRef, marginBottom: 20);
    container.position = Vector2(30, 23);

    cibleComponent = CibleComponent(gameRef, builderBehaviour);
    container.add(cibleComponent);
    
    container.add(LineComponent(Vector2(size.x - 60, 4)));
    
    workComponent = WorkComponent(gameRef, builderBehaviour);
    container.add(workComponent);
    
    container.invalidate();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    //print("PopupBuilderBehaviour.onLoad.start");
    sprite = Sprite(await ImagesUtils.loadImage("cadre_behaviour.png"));
    anchor = Anchor.center;
    position = gameRef.size / 2;

    _buttonClose = SpriteComponent(sprite: Sprite(await ImagesUtils.loadImage("button_close.png")), position: Vector2(size.x - 32, -6), size: Vector2.all(38));
    await addChild(_buttonClose);
    
    await addChild(container);
    container.invalidate();

    //print("PopupBuilderBehaviour.onLoad.end");
  }

  bool onClick(Vector2 p) 
  {
    if(popupChooseWork != null && popupChooseWork!.onClick(p))
      return true;

    BuilderConditionComponent? conditionClicked = cibleComponent.onClick(p);
    if(conditionClicked != null)
    {
      if(popupChooseCible == null)
      {
        popupChooseWork?.remove();
        popupChooseWork = null;
        popupChooseCible = PopupChooseCible(gameRef, entity, (BuilderCondition b){
          int index = builderBehaviour.builderConditions.conditions.indexOf(conditionClicked.builderCondition);
          builderBehaviour.builderConditions.conditions[index] = b;
          cibleComponent.setCible(index, b);
          Storage.storeEntities();
        });
        popupChooseCible!.size = Vector2(size.x /4 - 15, size.y - 30);
        popupChooseCible!.position = Vector2(size.x /2, 15);
        addChild(popupChooseCible!, gameRef: gameRef);
      }
      else
      {
        popupChooseCible?.remove();
        popupChooseCible = null;
      }
      return true;
    }

    if(workComponent.onClick(p))
    {
      if(popupChooseWork == null)
      {
        popupChooseCible?.remove();
        popupChooseCible = null;
        popupChooseWork = PopupChooseWork(gameRef, entity, (Work newWork){
          if(newWork != builderBehaviour.builderWork.work)
          {
            builderBehaviour.builderWork.work = newWork;
            workComponent.setWork(newWork);
            Storage.storeEntities();
          }
        });
        popupChooseWork!.size = Vector2(size.x /4 - 15, size.y - 30);
        popupChooseWork!.position = Vector2(size.x /2, 15);
        addChild(popupChooseWork!, gameRef: gameRef);
      }
      else
      {
        popupChooseWork?.remove();
        popupChooseWork = null;
      }
      return true;
    }

    if(_buttonClose.containsPoint(p))
    {
      gameRef.tutorielScreen?.onEvent(TutorielSettings.EVENT_CLICK_CLOSE_POPUP_BEHAVIOUR);
      gameRef.optionsScreen!.popupBuilderBehaviour = null;
      remove();
    }

    if(gameRef.tutorielScreen != null)
      return true;
    
    return true;
  }
}

class ButtonBuilderCondition extends PositionComponent
{
  final GameLayout gameRef;

  BuilderCondition builderCondition;
  late final TextComponent textComponent;
  late final SpriteAlphaComponent button;

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
    textComponent.textRenderer = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white.withAlpha(alpha)));
    button.alpha = alpha;
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
  }

  Future<void> _updateButton() async
  {
    if(builderCondition is isEnnemy)
    {
      button = SpriteAlphaComponent();
      button.sprite = Sprite(await ImagesUtils.loadImage("button_ennemy.png"));
      button.size = size;
      TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
      textComponent = TextComponent("Ennemi", textRenderer: textPaint);
      textComponent.anchor = Anchor.center;
      textComponent.position = size / 2;
      await button.addChild(textComponent);
      await addChild(button, gameRef: gameRef);
      return;
    }

    if(builderCondition is isMe)
    {
      button = SpriteAlphaComponent();
      button.sprite = Sprite(await ImagesUtils.loadImage("button_me.png"));
      button.size = size;
      TextRenderer textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco", color: Colors.white));
      textComponent = TextComponent("Moi", textRenderer: textPaint);
      textComponent.anchor = Anchor.center;
      textComponent.position = size / 2;
      await button.addChild(textComponent);
      await addChild(button, gameRef: gameRef);
      return;
    }
  }
}

class BuilderConditionComponent extends PositionComponent
{
  final GameLayout gameRef;
  final BuilderCondition builderCondition;
  final List<Function> callbacks = [];
  late final ButtonBuilderCondition buttonBuilderCondition;

  BuilderConditionComponent(this.gameRef, this.builderCondition)
  {
    buttonBuilderCondition = ButtonBuilderCondition(gameRef, builderCondition);
    size = buttonBuilderCondition.size;
  }

  void setBuilderCondition(BuilderCondition builderCondition)
  {
    buttonBuilderCondition.setBuilderCondition(builderCondition);
    size = buttonBuilderCondition.size;
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    await addChild(buttonBuilderCondition);
    callbacks.add((Vector2 p){
      if(buttonBuilderCondition.containsPoint(p))
      {
        gameRef.tutorielScreen?.onEvent(TutorielSettings.EVENT_CLICK_BEHAVIOUR_PARAM, param: 0);
        return true;
      }
      return false;
    });
  }

  bool onClick(Vector2 p) 
  {
    for(Function f in callbacks)
    {
      if(f.call(p))
        return true;
    }
    return false;
  }
}

class CibleComponent extends VerticalContainer
{
  final BuilderBehaviour builderBehaviour;
  final List<BuilderConditionComponent> conditionsComponents = [];

  CibleComponent(GameLayout gameRef, this.builderBehaviour):super(gameRef)
  {
    add(TextSizedComponent("Cible", textRenderer: textPaint));
    for(int i = 0; i < builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length; i++)
    {
      BuilderCondition builderCondition = builderBehaviour.builderTargetSelector.builderConditionGroup.conditions[i];
      BuilderConditionComponent conditionComponent = BuilderConditionComponent(gameRef, builderCondition);
      conditionsComponents.add(conditionComponent);
      add(conditionComponent);
    }
  }

  void setCible(int index, BuilderCondition builderCondition)
  {
    conditionsComponents[index].setBuilderCondition(builderCondition);
    invalidate();
  }

  BuilderConditionComponent? onClick(Vector2 p) 
  {
    for(BuilderConditionComponent b in conditionsComponents)
    {
      if(b.onClick(p))
        return b;
    }
    return null;
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
    add(TextSizedComponent("Action", textRenderer: textPaint));
    BuilderWork builderWork = builderBehaviour.builderWork;
    builderWorkComponent = BuilderWorkComponent(gameRef, builderWork);
    add(builderWorkComponent);
  }

  void setWork(Work work)
  {
    builderWorkComponent.button.setWork(work);
  }

  bool onClick(Vector2 p) 
  {
    return builderWorkComponent.onClick(p);
  }
}

class PopupChooseCible extends PopupChoose
{
  final GameLayout gameRef;
  final Entity entity;
  final Function onChooseCible;
  final List<Function> callbacks = [];

  PopupChooseCible(this.gameRef, this.entity, this.onChooseCible):super("Cibles");

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    List<BuilderCondition> dispo = entity.availablesBuilderConditions();
    for(int i = 0; i < dispo.length; i++)
    {
      BuilderCondition c = dispo[i];
      ButtonBuilderCondition b = ButtonBuilderCondition(gameRef, c);
      await addChild(b);
      b.position = Vector2(.05 * size.x, startY + 2 + (5 + b.size.y) * i);
      b.size = Vector2(.9 * size.x / 2, b.size.y);
      b.alpha = gameRef.tutorielScreen != null && !(c is isEnnemy) ? 40 : 255;
      if(gameRef.tutorielScreen == null)
      {
        callbacks.add((Vector2 p){
          if(b.containsPoint(p))
          {
            onChooseCible(c);
            return true;
          }
          return false;
        });
      }
    }
  }
}

class PopupChooseWork extends PopupChoose
{
  final GameLayout gameRef;
  final Entity entity;
  final Function onChooseWork;
  final List<Function> callbacks = [];

  PopupChooseWork(this.gameRef, this.entity, this.onChooseWork):super("Actions");

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
      b.alpha = gameRef.tutorielScreen != null && w != Work.attaquer ? 40 : 255;
      if(gameRef.tutorielScreen == null)
      {
        callbacks.add((Vector2 p){
          if(b.containsPoint(p))
          {
            onChooseWork(w);
            return true;
          }
          return false;
        });
      }
    }
  }

  bool onClick(Vector2 p)
  {
    for(Function c in callbacks)
    {
      if(c.call(p))
        return true;
    }
    return false;
  }
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

  bool onClick(Vector2 p)
  {
    return false;
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
      _cornerTopLeft = GameLayout.gui.getSprite(0, 0);
      _cornerTopRight = GameLayout.gui.getSprite(0, 2);
      _cornerBottomLeft = GameLayout.gui.getSprite(2, 0);
      _cornerBottomRight = GameLayout.gui.getSprite(2, 2);
      _center = GameLayout.gui.getSprite(1, 1);
      _centerTop = GameLayout.gui.getSprite(0, 1);
      _centerBottom = GameLayout.gui.getSprite(2, 1);
      _centerLeft = GameLayout.gui.getSprite(1, 0);
      _centerRight = GameLayout.gui.getSprite(1, 2);
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
    textComponent.text = this.work.name;
    size = Vector2(textPaint.measureTextWidth(this.work.name) + 60, 40);
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
    spriteNone = Sprite(await ImagesUtils.loadImage("button_none.png"));
    spriteAction = Sprite(await ImagesUtils.loadImage("button_work.png"));
    spriteMagie = Sprite(await ImagesUtils.loadImage("button_magic.png"));
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

  bool onClick(Vector2 p) 
  {
    if(button.containsPoint(p))
    {
      gameRef.tutorielScreen?.onEvent(TutorielSettings.EVENT_CLICK_BEHAVIOUR_PARAM, param: 1);
      return true;
    }
    return false;
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
    player.sprite = Sprite(await ImagesUtils.loadImage("portrait.png"));
    player.size = Vector2(72, 72);
    player.anchor = Anchor.bottomCenter;
    player.position = Vector2(size.x / 2, size.y);
    player.overridePaint = BasicPalette.white.paint();
    playerPaint = player.overridePaint!;
    addChild(player);

    sprite = Sprite(await ImagesUtils.loadImage("cadre_player.png"));
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
      _cornerTopLeft = GameLayout.gui.getSprite(7, 0);
      _cornerTopRight = GameLayout.gui.getSprite(7, 3);
      _cornerBottomLeft = GameLayout.gui.getSprite(10, 0);
      _cornerBottomRight = GameLayout.gui.getSprite(10, 3);
      _center = GameLayout.gui.getSprite(1, 13);
      _centerTop = GameLayout.gui.getSprite(7, 1);
      _centerBottom = GameLayout.gui.getSprite(10, 1);
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

class VerticalContainer extends PositionComponent
{
  final GameLayout gameRef;
  final List<PositionComponent> items = [];
  int marginBottom = 0;

  VerticalContainer(this.gameRef, {this.marginBottom = 0});

  void add(PositionComponent component)
  {
    items.add(component);
    invalidate();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    items.forEach((element) async{await addChild(element, gameRef: gameRef);});
  }

  void invalidate()
  {
    for(int i = 1; i < items.length; i++)
    {
      PositionComponent last = items[i - 1];
      PositionComponent current = items[i];
      current.position = Vector2(0, last.position.y + last.size.y + marginBottom);
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
    return Vector2(maxW, items.last.position.y +  items.last.size.y + marginBottom);
  }
}

class HorizontalContainer extends PositionComponent
{
  final GameLayout gameRef;
  final List<PositionComponent> items = [];
  int divider = 0;

  HorizontalContainer(this.gameRef, {this.divider = 0});

  void add(PositionComponent component)
  {
    items.add(component);
    invalidate();
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    items.forEach((element) async{await addChild(element, gameRef: gameRef);});
  }

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
  SpriteAlphaComponent():super(overridePaint: BasicPalette.white.withAlpha(255).paint());

  set alpha(int alpha)
  {
    overridePaint = BasicPalette.white.withAlpha(alpha).paint();
  }
}