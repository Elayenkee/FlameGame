import 'dart:convert';

import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/settings/settings.dart';
import 'package:flame/components.dart' as draggable;
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/worldScreen.dart';

import 'bdd.dart';

Future<void> main() async
{
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();

  BuilderServer builderServer = await buildServer();
  
  Map<String, WidgetBuilder> routes = {
    '/menu': (BuildContext context) {
      return HomeScreen(builderServer);
    },
    /*'/start': (BuildContext context) {
      return GameScreen(builderServer.build());
    },*/
    '/start': (BuildContext context) {
      return WorldScreen();
    },
    '/settings': (BuildContext context) {
      return SettingsScreen(builderServer);
    }
  };
  runApp(MaterialApp(home: HomeScreen(builderServer), routes: routes));
}

Future<BuilderServer> buildServer() async
{
  BuilderServer builderServer = BuilderServer();

  Map values = Map();
  values[VALUE.NAME] = "Entity 1";
  values[VALUE.HP_MAX] = 46;
  values[VALUE.ATK] = 23;
  values[VALUE.CLAN] = 1;

  Entity entity = Entity(values);
  BuilderEntity builderEntity = entity.builder;
  
  builderServer.addEntity(e: entity);
  builderEntity.entity.setValues(values);

  BuilderTotal builder = builderEntity.builderTotal;

  BuilderBehaviour builderBehaviour =
      builder.addBehaviour(name: "Poison if no poison");
  builderBehaviour.builderWork.work = Works.POISON;
  BuilderConditionGroup builderConditionGroup =
      builderBehaviour.builderTargetSelector.builderConditionGroup;
  BuilderTriFunction builderTriFunction =
      builderBehaviour.builderTargetSelector.builderTriFunction;
  builderTriFunction.tri = TriFunctions.LOWEST;
  builderTriFunction.value = VALUE.HP;
  BuilderCondition builderCondition = builderConditionGroup.addCondition();
  builderCondition.setCondition(Conditions.NOT_EQUALS);
  builderCondition.setParam(1, builderEntity);
  builderCondition.setParam(2, VALUE.CLAN);
  BuilderCondition builderCondition2 = builderConditionGroup.addCondition();
  builderCondition2.setCondition(Conditions.EQUALS);
  builderCondition2.setParam(1, ValueAtom(0));
  BuilderCount builderCount = BuilderCount();
  builderCount.setValue(VALUE.POISON);
  builderCondition2.setParam(2, builderCount);

  BuilderBehaviour builderBehaviourBleed =
      builder.addBehaviour(name: "Bleed if no bleed");
  builderBehaviourBleed.builderWork.work = Works.BLEED;
  BuilderConditionGroup builderConditionGroupBleed =
      builderBehaviourBleed.builderTargetSelector.builderConditionGroup;
  BuilderTriFunction builderTriFunctionBleed =
      builderBehaviourBleed.builderTargetSelector.builderTriFunction;
  builderTriFunctionBleed.tri = TriFunctions.LOWEST;
  builderTriFunctionBleed.value = VALUE.HP;
  BuilderCondition builderConditionBleed =
      builderConditionGroupBleed.addCondition();
  builderConditionBleed.setCondition(Conditions.NOT_EQUALS);
  builderConditionBleed.setParam(1, builderEntity);
  builderConditionBleed.setParam(2, VALUE.CLAN);
  BuilderCondition builderCondition2Bleed =
      builderConditionGroupBleed.addCondition();
  builderCondition2Bleed.setCondition(Conditions.EQUALS);
  builderCondition2Bleed.setParam(1, ValueAtom(0));
  BuilderCount builderCountBleed = BuilderCount();
  builderCountBleed.setValue(VALUE.BLEED);
  builderCondition2Bleed.setParam(2, builderCountBleed);

  BuilderBehaviour builderBehaviour2 =
      builder.addBehaviour(name: "Attack lowest HP");
  builderBehaviour2.builderWork.work = Works.ATTACK;
  BuilderConditionGroup builderConditionGroup2 =
      builderBehaviour2.builderTargetSelector.builderConditionGroup;
  BuilderTriFunction builderTriFunction2 =
      builderBehaviour2.builderTargetSelector.builderTriFunction;
  builderTriFunction2.tri = TriFunctions.LOWEST;
  builderTriFunction2.value = VALUE.HP;
  BuilderCondition builderCondition3 = builderConditionGroup2.addCondition();
  builderCondition3.setCondition(Conditions.NOT_EQUALS);
  builderCondition3.setParam(1, builderEntity);
  builderCondition3.setParam(2, VALUE.CLAN);

  await Storage.init();
  Storage.storeEntity(entity);
  //builderServer.build();
  builderServer.builderEntities = [];
  Utils.countBuild = 1;

  final e = Storage.getEntity();
  builderServer.addEntity(e : e);
  print("=====================================");
  print("=====================================");
  //builderServer.build();

  //================ ENTITY 3 ===========================
  final add = true;
  if(add)
  {
    values[VALUE.HP_MAX] = 100;
    values[VALUE.MP_MAX] = 0;
    values[VALUE.ATK] = 5;
    values[VALUE.NAME] = "Client 3";
    values[VALUE.CLAN] = 0;
    BuilderEntity entity3 = builderServer.addEntity();
    entity3.setValues(values);
    BuilderTotal builder3 = entity3.builderTotal;
    BuilderBehaviour builderBehaviour4 = builder3.addBehaviour();
    builderBehaviour4.builderWork.work = Works.ATTACK;

    BuilderConditionGroup builderConditionGroup4 =
        builderBehaviour4.builderTargetSelector.builderConditionGroup;
    BuilderCondition builderCondition5 = builderConditionGroup4.addCondition();
    builderCondition5.setCondition(Conditions.NOT_EQUALS);
    builderCondition5.setParam(1, entity3);
    builderCondition5.setParam(2, VALUE.CLAN);

    BuilderTriFunction builderTriFunction4 =
        builderBehaviour4.builderTargetSelector.builderTriFunction;
    builderTriFunction4.tri = TriFunctions.LOWEST;
    builderTriFunction4.value = VALUE.HP;
  }

  return builderServer;
}

class HomeScreen extends StatelessWidget 
{
  final BuilderServer builderServer;
  late final MainLayout mainLayout;

  HomeScreen(this.builderServer) {
    mainLayout = MainLayout();
  }

  @override
  Widget build(BuildContext context) {
    //return GameWidget(game: mainLayout);
    return Column(children: [
      Container(
        height: 120,
      ),
      BtnPlay(context),
      Container(
        height: 10,
      ),
      BtnSettings(context)
    ]);
  }

  Widget BtnPlay(BuildContext context) {
    var onPress = () {
      if (!builderServer.isValid(Validator(true))) {
        Utils.log("LE BUILDER N'EST PAS VALIDE");
        return;
      }

      Navigator.of(context).pushNamed('/start');
    };
    return Btn("Start", onPress);
  }

  Widget BtnSettings(BuildContext context) {
    var onPress = () {
      Navigator.of(context).pushNamed('/settings');
    };
    return Btn("Settings", onPress);
  }

  Widget Btn(String text, var onPress) {
    Widget child = Text(text, style: TextStyle(color: Colors.white));
    return Container(
        width: 150,
        height: 50,
        child: MaterialButton(
          onPressed: onPress,
          child: child,
          color: FirstTheme.buttonColor,
        ));
  }
}

class MainLayout extends AbstractLayout 
{
  MainLayout():super("Main");

  @override
  Future<void> onLoad() async {
    super.onLoad();
  }
}

class AbstractLayout extends BaseGame 
{
  String title;

  late final Vector2 size;
  late final Background background;
  final FocusNode focusNode = FocusNode();
  Keyboard? keyboard;

  AbstractLayout(this.title) 
  {
    size = Vector2(840, 500);
    background = Background(size);
  }

  void openKeyboard(Function onPressedEnter, String defaultValue) {
    keyboard = Keyboard(this, defaultValue, onPressedEnter);
  }

  void handleKeyEvent(RawKeyEvent event) {
    keyboard?.handleKeyEvent(event);
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();
    viewport = FixedResolutionViewport(size);
    add(background);

    final titleComponent = TextComponent(title);
    add(titleComponent);
  }

  @override
  Color backgroundColor() => Color.fromARGB(255, 0, 0, 0);
}

class Background extends SpriteComponent {
  late Rect rect;
  late final Paint paint;

  Background(Vector2 size) : super(size: size) {
    paint = Paint()..color = Colors.white;
    rect = Rect.fromLTWH(x, y, size.x, size.y);
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(rect, paint);
    super.render(canvas);
  }
}

class Keyboard {
  final AbstractLayout layout;
  String texte = "";
  Function? onPressedEnter = null;
  KeyboardComponent? keyboardComponent = null;

  Keyboard(this.layout, this.texte, Function onPressedEnter) {
    keyboardComponent = KeyboardComponent(texte, layout);
    layout.add(keyboardComponent!);
    FocusScope.of(layout.buildContext!).requestFocus(layout.focusNode);
    this.onPressedEnter = (newTexte) {
      reset();
      onPressedEnter(newTexte);
    };
    keyboardComponent!.onKey = onKey;
    keyboardComponent!.onBack = onBack;
    keyboardComponent!.onOk = () {
      String newTexte = texte;
      reset();
      onPressedEnter(newTexte);
    };
    keyboardComponent!.onCancel = () {
      reset();
    };
  }

  void handleKeyEvent(RawKeyEvent event) {
    if (event.isControlPressed) {
    } else if (event is RawKeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.backspace) {
        onBack();
      } else if (event.logicalKey == LogicalKeyboardKey.enter &&
          onPressedEnter != null) {
        onPressedEnter!(texte);
      } else if (event.character != null) {
        if (event.character!.length == 1) onKey(event.character!);
      }
    }
  }

  void onBack() {
    if (texte.length > 0) {
      texte = texte.substring(0, texte.length - 1);
      updateKeyboardComponent();
    }
  }

  void onKey(String key) {
    texte += key;
    updateKeyboardComponent();
  }

  void updateKeyboardComponent() {
    if (keyboardComponent != null) {
      keyboardComponent!.textComponent.text = texte;
      texte = keyboardComponent!.textComponent.text;
    }
  }

  void reset() {
    FocusScope.of(layout.buildContext!).unfocus();
    this.texte = "";
    this.onPressedEnter = null;
    this.keyboardComponent?.remove();
    this.keyboardComponent = null;
    layout.keyboard = null;
  }
}

class KeyboardComponent extends PositionComponent with Tappable {
  final AbstractLayout layout;
  late final Rect bgRect;
  late final Paint bgPaint;

  late Rect frameRect;
  late final Paint framePaint;

  late final AdvancedTextComponent textComponent;

  Function? onCancel = null;
  Function? onKey = null;
  Function? onBack = null;
  Function? onOk = null;

  KeyboardComponent(String defaultValue, this.layout) : super(priority: 1500) {
    size = layout.size;
    bgPaint = Paint()..color = Colors.white.withOpacity(.7);
    bgRect = Rect.fromLTWH(0, 0, width, height);
    framePaint = Paint()..color = Colors.grey;

    double _width = 300;
    double _height = 70;
    double _x = (width - _width) / 2;
    double _y = (isKeyboardVisible() ? height / 4 : height / 2) - (_height / 2);

    frameRect = Rect.fromLTWH(_x, _y, _width, _height);

    textComponent = AdvancedTextComponent(defaultValue);
    textComponent.anchor = Anchor.topCenter;
    textComponent.position = Vector2(width / 2, _y + 20);
    textComponent.onTextUpdated = () {
      double _w = textComponent.width + 10 < _width
          ? _width
          : (textComponent.width + 10);
      double _x = (width - _w) / 2;
      frameRect = Rect.fromLTWH(_x, _y, _w, _height);
    };
    textComponent.canAddText = () {
      return textComponent.text.length < 15;
    };
    addChild(textComponent);

    SoftKeyboard softKeyboard = SoftKeyboard(layout);
    softKeyboard.onKey = (key) => onKey?.call(key);
    softKeyboard.onBack = () => onBack?.call();
    softKeyboard.onOk = () => onOk?.call();
    addChild(softKeyboard);

    isHud = true;
  }

  @override
  Future<void> onLoad() async {
    return super.onLoad();
  }

  bool isKeyboardVisible() {
    return true;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(bgRect, bgPaint);
    canvas.drawRect(frameRect, framePaint);
    super.render(canvas);
  }

  @override
  bool onTapCancel() {
    return false;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    if (!frameRect.contains(info.raw.localPosition)) onCancel?.call();
    return false;
  }
}

class SoftKeyboard extends PositionComponent with Tappable {
  late Rect frameRect;
  late final Paint framePaint;

  late double targetY;

  Function? onKey;
  Function? onBack;
  Function? onOk;

  SoftKeyboard(BaseGame game) {
    size = Vector2(600, 250);
    position = Vector2((game.size.x - width) / 2, game.size.y);
    frameRect = Rect.fromLTWH(x, y, width, height);
    framePaint = Paint()..color = Colors.grey;
    targetY = position.y - size.y - 10;

    addKeys([1, 2, 3, 4, 5, 6, 7, 8, 9, 0], 0);
    addKeys(["a", "z", "e", "r", "t", "y", "u", "i", "o", "p"], 1);
    addKeys(["q", "s", "d", "f", "g", "h", "j", "k", "l", "m"], 2);
    addKeys(["w", "x", "c", "v", "b", "n"], 3);

    // Space
    KeyComponent space = KeyComponent(" ");
    space.size = Vector2(200, KeyComponent._height);
    space.position = Vector2((width - 200) / 2, KeyComponent._height * 4);
    space.onKey = (key) => onKey?.call(key);
    addChild(space);

    // Back
    KeyComponent back = KeyComponent("<=");
    back.size = Vector2(100, KeyComponent._height);
    back.position = Vector2(10, KeyComponent._height * 4 - 10);
    back.onKey = (key) {
      onBack?.call();
    };
    addChild(back);

    // Ok
    KeyComponent ok = KeyComponent("OK");
    ok.size = Vector2(70, KeyComponent._height);
    ok.position = Vector2(width - 80, KeyComponent._height * 4 - 10);
    ok.onKey = (key) {
      onOk?.call();
    };
    addChild(ok);
  }

  void addKeys(List keys, int line) {
    double marge = (width - (keys.length * KeyComponent._width)) / 2;
    for (int i = 0; i < keys.length; i++) {
      String key = keys[i].toString();
      KeyComponent K = KeyComponent(key);
      K.position =
          Vector2(marge + KeyComponent._width * i, KeyComponent._height * line);
      K.onKey = (key) => onKey?.call(key);
      addChild(K);
    }
  }

  @override
  void render(Canvas canvas) {
    //canvas.drawRect(frameRect, framePaint);
    super.render(canvas);
  }

  @override
  void update(double dt) {
    if (position.y > targetY) {
      position.moveToTarget(Vector2(x, targetY), 35);
      frameRect = Rect.fromLTWH(x, y, width, height);
    }
    super.update(dt);
  }

  @override
  bool onTapCancel() {
    return false;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    return false;
  }
}

class KeyComponent extends PositionComponent
    with Tappable, draggable.Draggable {
  static final double _width = 50;
  static final double _height = 50;

  final String key;
  late Rect rect;
  late final Paint normalPaint;
  late final Paint pressedPaint;
  bool pressed = false;

  Function? onKey;

  KeyComponent(this.key) {
    size = Vector2(_width, _height);
    position = Vector2.all(0);
    normalPaint = Paint()..color = Colors.brown;
    pressedPaint = Paint()..color = Colors.red;
    TextComponent textComponent = TextComponent(key);
    textComponent.anchor = Anchor.center;
    textComponent.position = size / 2;
    addChild(textComponent);
  }

  @override
  bool onTapCancel() {
    return false;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    pressed = true;
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    onKey?.call(key);
    pressed = false;
    return false;
  }

  @override
  bool onDragStart(int pointerId, DragStartInfo info) {
    pressed = true;
    return false;
  }

  @override
  bool onDragUpdate(int pointerId, DragUpdateInfo info) {
    if (pressed) pressed = toAbsoluteRect().contains(info.raw.localPosition);
    return false;
  }

  @override
  bool onDragEnd(int pointerId, DragEndInfo info) {
    if (pressed) {
      onKey?.call(key);
      pressed = false;
    }
    return false;
  }

  @override
  bool onDragCancel(int pointerId) {
    return false;
  }

  @override
  void render(Canvas canvas) {
    canvas.drawRect(rect, normalPaint);
    if (pressed) canvas.drawRect(rect, pressedPaint);
    super.render(canvas);
  }

  @override
  set position(Vector2 position) {
    super.position = position;
    rect = Rect.fromLTWH(x, y, width, height);
  }
}

class AdvancedTextComponent extends TextComponent with Tappable {
  Function? onTextUpdated;
  Function? canAddText;

  AdvancedTextComponent(String text) : super(text);

  set text(String text) {
    if (super.text.length > text.length ||
        canAddText == null ||
        canAddText?.call()) {
      super.text = text;
      onTextUpdated?.call();
    }
  }

  @override
  bool onTapCancel() {
    return false;
  }

  @override
  bool onTapDown(TapDownInfo info) {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) {
    return false;
  }
}
