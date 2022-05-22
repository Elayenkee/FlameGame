import 'package:firebase_core/firebase_core.dart';
import 'package:flame/assets.dart';
import 'package:flame/components.dart';
import 'package:flame/flame.dart';
import 'package:flame/game.dart';
import 'package:flame/gestures.dart';
import 'package:flame/sprite.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart' as draggable;
import 'package:myapp/donjon/donjon_screen.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/fight/fight_screen.dart';
import 'package:myapp/google/google_signin.dart';
import 'package:myapp/options/options_screen.dart';
import 'package:myapp/start/start_screen.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/tutoriel/tutoriel_screen.dart';
import 'package:myapp/utils/images.dart';
import 'package:myapp/world/world_screen.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

final TextComponent txtDebug = TextComponent("", textRenderer: TextPaint(config:TextPaintConfig(color: Colors.red)));
void logDebug(String message)
{
  if(txtDebug.text.length > 300)
  {
    txtDebug.text = "";
  }
  txtDebug.text += "$message\n"; 
}

final TextPaint textPaint = TextPaint(config:TextPaintConfig(fontFamily: "Disco"));
late final SpriteSheet gui;

Future<void> main() async
{
  print("============ RESTART APPLICATION ===========");
  WidgetsFlutterBinding.ensureInitialized();
  await Flame.device.fullScreen();
  await Flame.device.setLandscape();
  //await Firebase.initializeApp();
  print("Settings.ok");
  runApp(MaterialApp(theme: ThemeData(fontFamily: 'Disco'),home: GameScreen()));
}

class GameScreen extends StatelessWidget
{
  late final GameLayout gameLayout;

  GameScreen()
  {
    gameLayout = GameLayout();
  }

  @override
  Widget build(BuildContext context)
  {
    return GameWidget(game: gameLayout);
  }
}

class GameLayout extends AbstractLayout with PanDetector
{
  StartScreen? _startScreen;
  WorldScreen? _worldScreen;
  FightScreen? _fightScreen;
  DonjonScreen? _donjonScreen;
  OptionsScreen? optionsScreen;
  TutorielScreen? tutorielScreen;
  
  GameLayout():super();

  Images createImages()
  {
    return Images();
  }

  @override
  Future<void> onLoad() async 
  {
    print("GameLayout.onLoad");
    await super.onLoad();
    _startScreen = StartScreen(this, size);
    await add(_startScreen!);
    //await add(txtDebug);
    print("GameLayout.onLoaded");
  }

  void startWorld() async
  {
    //print("GameLayout.startWorld");
    _fightScreen?.remove();
    _fightScreen = null;
    _donjonScreen?.remove();
    _donjonScreen = null;
    _worldScreen = WorldScreen(this, size);
    await add(_worldScreen!);
  }

  void startFight()
  {
    //print("GameLayout.startFight");
    /*_worldScreen?.remove();
    _worldScreen = null;
    _donjonScreen?.remove();
    _donjonScreen = null;
    _fightScreen = FightScreen(this, size);
    add(_fightScreen!);*/
  }

  void startDonjon() async 
  {
    //print("GameLayout.startDonjon");
    _startScreen?.remove();
    _startScreen = null;
    _worldScreen?.remove();
    _worldScreen = null;
    _fightScreen?.remove();
    _fightScreen = null;
    _donjonScreen = DonjonScreen(this, size);
    await add(_donjonScreen!);
  }

  void startTutoriel(TutorielScreen screen) async
  {
    //print("GameLayout.startTutoriel");
    tutorielScreen = screen;
    await add(tutorielScreen!);
  }

  void stopTutoriel()
  {
    //print("GameLayout.stopTutoriel");
    tutorielScreen?.remove();
    tutorielScreen = null;
  }

  void startOptions() async 
  {
    optionsScreen = OptionsScreen(this, size, onClickClose: closeOptions);
    await add(optionsScreen!);
  }

  void closeOptions()
  {
    //print("GameLayout.closeOptions");
    optionsScreen?.remove();
    optionsScreen = null;
  }
  
  @override
  void update(double dt) 
  {
    super.update(dt);
  }

  @override
  void onPanDown(DragDownInfo info) 
  {
    super.onPanDown(info);

    if(tutorielScreen != null)
    {
      if(tutorielScreen!.onClick(info.eventPosition.game))
        return;
    }

    if(_startScreen != null)
    {
      _startScreen?.onClick(info.eventPosition.game);
      return;
    }

    if(optionsScreen != null)
    {
      optionsScreen?.onClick(info.eventPosition.game);
      return;
    }
    
    _worldScreen?.onClick(info.eventPosition.game);
    _donjonScreen?.onClick(info.eventPosition.game);
  }

  @override
  void onPanUpdate(DragUpdateInfo info) 
  {
    super.onPanUpdate(info);
    optionsScreen?.onPanUpdate(info);
  }
  
  @override
  void onPanEnd(DragEndInfo info) 
  {
    super.onPanEnd(info);
    optionsScreen?.onPanEnd();
  }
}

abstract class AbstractScreen extends BaseComponent with HasGameRef<GameLayout>
{
  final GameLayout gameRef;
  late final String _title;

  final BaseComponent layout = Layer();
  final BaseComponent hud = Layer();
  final BaseComponent debug = Layer();

  AbstractScreen(this.gameRef, this._title, Vector2 size, {int priority = 0}):super(priority: priority);

  @override
  Future<void> onLoad() async 
  {
    //print("AbstractScreen.onLoad");
    await super.onLoad();
    addChild(layout);
    addChild(hud);

    final title = TextComponent(_title);
    
    //debug.addChild(txtDebug);
    addChild(debug);
    //print("AbstractScreen.onLoaded");
  }

  Future<void> add(Component c) async
  {
    await layout.addChild(c);
  }

  Future<void> addWithGameRef(Component c) async
  {
    await layout.addChild(c, gameRef: gameRef);
  }

  bool onClick(Vector2 p);

  get isWeb => kIsWeb;
}

class Layer extends PositionComponent
{

}

class AbstractLayout extends BaseGame
{
  bool rendering = true;
  late final Vector2 size;
  late final Background background;
  
  final FocusNode focusNode = FocusNode();
  Keyboard? keyboard;

  AbstractLayout() 
  {
    size = Vector2(850, 500);
    background = Background(size);
  }

  void openKeyboard(Function onPressedEnter, String defaultValue) 
  {
    keyboard = Keyboard(this, defaultValue, onPressedEnter);
  }

  void handleKeyEvent(RawKeyEvent event) 
  {
    keyboard?.handleKeyEvent(event);
  }

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();
    viewport = FixedResolutionViewport(size);
    add(background);
  }

  @override
  void render(Canvas canvas) 
  {
    if(rendering)
      super.render(canvas);
  }

  void setBackgroundColor(Color color)
  {
    background.setColor(color);
  }

  @override
  Color backgroundColor() => Color.fromARGB(255, 0, 0, 0);
}

class Background extends SpriteComponent 
{
  late final Rect rect;
  late Paint paint;

  Background(Vector2 size) : super(size: size) 
  {
    paint = Paint()..color = Colors.white;
    rect = Rect.fromLTWH(x, y, size.x, size.y);
  }

  void setColor(Color color)
  {
    paint.color = color;
  }

  @override
  void render(Canvas canvas) 
  {
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

class KeyComponent extends PositionComponent with Tappable, draggable.Draggable {
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
