import 'dart:math';

import 'package:flame/components.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/my_text_box_component.dart';
import 'package:myapp/language/language.dart';
import 'package:myapp/main.dart';
import 'package:myapp/options/options_screen.dart';
import 'package:myapp/storage/storage.dart';
import 'package:myapp/utils.dart';
import 'package:myapp/utils/images.dart';

abstract class TutorielScreen extends AbstractScreen
{
  late final Popup cadre;
  late final SpriteComponent portrait;

  MyTextBoxComponent? txtPhrase = null;
  String phrase = "";

  List<Pointer?> pointers = [];
  VoidCallback? onEnd;

  TutorielScreen(GameLayout gameRef, Vector2 size, this.onEnd):super(gameRef, "T", size, priority: 6500);

  @override
  Future<void> onLoad() async 
  {
    await super.onLoad();

    cadre = Popup(Vector2(gameRef.size.x, 150));
    cadre.position = Vector2(0, gameRef.size.y - cadre.size.y);
    await addChild(cadre);

    portrait = SpriteComponent();
    portrait.sprite = Sprite(ImagesUtils.getImage("portrait.png"));
    portrait.size = Vector2.all(150);
    await cadre.addChild(portrait);
  }

  void startPhrase(dynamic phrase) async
  {
    if(cadre.parent == null)
      await addWithGameRef(cadre);
    if(portrait.parent == null)
      await addWithGameRef(portrait);

    print("startPhrase.start");
    this.phrase = phrase.toString();

    txtPhrase?.remove();
    txtPhrase = null;

    txtPhrase = MyTextBoxComponent(this.phrase, textRenderer: textPaint, priority: 2500, boxConfig: TextBoxConfig(maxWidth: cadre.size.x - 200, timePerChar: .02));
    txtPhrase!.position = Vector2(150, 25);
    txtPhrase!.size = Vector2(1000, 1000);
    cadre.addChild(txtPhrase!, gameRef: gameRef);
    print("startPhrase.end");
  }

  @override
  List<ObjectClicked> onClick(Vector2 p) 
  {
    return [];
  }

  void removePointers()
  {
    pointers.forEach((element) {element?.remove();});
    pointers.clear();
  }

  bool onEvent(String event, {dynamic param})
  {
    return false;
  }
}

class TutorielSettings extends TutorielScreen
{
  static final String EVENT_CLICK_OPEN_SETTINGS = Utils.generateUUID();
  static final String EVENT_CLICK_OPEN_DETAILS = Utils.generateUUID();
  static final String EVENT_CLICK_BEHAVIOUR_PARAM = Utils.generateUUID();
  static final String EVENT_CLICK_CLOSE_POPUP_BEHAVIOUR = Utils.generateUUID();
  
  final SpriteComponent buttonSettings;

  int step = 1;

  TutorielSettings(GameLayout gameRef, this.buttonSettings, VoidCallback onEnd):super(gameRef, gameRef.size, onEnd);

  @override
  Future<void> onLoad() async 
  {
    print("TutorielSettings.onLoad.start");
    await super.onLoad();

    startPhrase(Language.tutoriel1_phrase1);
    txtPhrase?.onEnd = (){
      buttonSettings.position = Vector2(gameRef.size.x - 80, 5);
      pointers.add(Pointer(Language.tutoriel1_pointer1.str, 1, Vector2(buttonSettings.position.x - 10, buttonSettings.position.y)));
      addChild(pointers.last!);
    };
    print("TutorielSettings.onLoad.end");
  }

  @override
  bool onEvent(String event, {dynamic param})
  {
    if(step == 1 && event == EVENT_CLICK_OPEN_SETTINGS)
    {
      removePointers();
      startPhrase(Language.tutoriel1_phrase2);
      txtPhrase?.onEnd = (){
        Vector2 editPosition = gameRef.optionsScreen!.behaviours[0].edit.absolutePosition - Vector2(25, 80);
        pointers.add(Pointer(Language.tutoriel1_pointer2.str, 1, Vector2(editPosition.x - 10, editPosition.y + 60)));
        addChild(pointers.last!);
      };
      step = 2;
      return true;
    }
    else if(step == 2 && event == EVENT_CLICK_OPEN_DETAILS)
    {
      removePointers();
      startPhrase(Language.tutoriel1_phrase3);
      step = 3;

      PositionComponent cibleComponent = gameRef.optionsScreen!.popupBuilderBehaviour!.container.items[0]; 
      Vector2 positionPointerCible = Vector2(cibleComponent.absolutePosition.x + cibleComponent.size.x / 2, cibleComponent.absoluteCenter.y) + Vector2(200, 65);
      pointers.add(Pointer(Language.tutoriel1_pointer3_1.str, 2, positionPointerCible));
      addChild(pointers.last!);

      PositionComponent workComponent = gameRef.optionsScreen!.popupBuilderBehaviour!.container.items[2]; 
      Vector2 positionPointerWork = Vector2(workComponent.absolutePosition.x + workComponent.size.x / 2, workComponent.absoluteCenter.y) + Vector2(200, 65);
      pointers.add(Pointer(Language.tutoriel1_pointer3_2.str, 2, positionPointerWork));
      addChild(pointers.last!);
      return true;
    }
    else if(step == 3 && event == EVENT_CLICK_BEHAVIOUR_PARAM)
    {
      removePointers();
      startPhrase(Language.tutoriel1_phrase4);
      step = 4;
      return true;
    }
    else if((step == 3 || step == 4) && event == EVENT_CLICK_CLOSE_POPUP_BEHAVIOUR)
    {
      removePointers();
      gameRef.stopTutoriel();
      Future.delayed(Duration(milliseconds: 200), gameRef.closeOptions);
      Future.delayed(Duration(milliseconds: 500), onEnd);
      return true;
    }
    return false;
  }
}

class TutorielManyEnnemies extends TutorielScreen
{
  static final String EVENT_CLICK_CONDITIONS_PLUS = Utils.generateUUID();
  static final String EVENT_CLICK_CONDITIONS_NOUVEAU = Utils.generateUUID();

  final SpriteComponent buttonSettings;

  int step = 1;

  TutorielManyEnnemies(GameLayout gameRef, this.buttonSettings, VoidCallback onEnd):super(gameRef, gameRef.size, onEnd);

  @override
  Future<void> onLoad() async 
  {
    Storage.entity.builder.builderTotal.addBehaviour(name: Language.nouveau.str);

    await super.onLoad();
    startPhrase(Language.tutoriel2_phrase1);
    buttonSettings.position = Vector2(gameRef.size.x - 80, 5);
    pointers.add(Pointer(Language.tutoriel1_pointer1.str, 1, Vector2(buttonSettings.position.x - 10, buttonSettings.position.y)));
    addChild(pointers.last!, gameRef: gameRef);
  }

  @override
  bool onEvent(String event, {dynamic param})
  {
    if(step == 1 && event == TutorielSettings.EVENT_CLICK_OPEN_SETTINGS)
    {
      removePointers();
      startPhrase(Language.tutoriel2_phrase2);
      txtPhrase!.onEnd = (){
        Vector2 editPosition = gameRef.optionsScreen!.behaviours[1].edit.absolutePosition - Vector2(25, 80);
        pointers.add(Pointer(Language.tutoriel1_pointer2.str, 1, Vector2(editPosition.x - 10, editPosition.y + 60)));
        addChild(pointers.last!, gameRef: gameRef);
      };
      step = 2;
      return true;
    }
    else if(step == 2 && event == TutorielSettings.EVENT_CLICK_OPEN_DETAILS)
    {
      if(param == 1)
      {
        Storage.entity.addCondition = true;
        removePointers();
        startPhrase(Language.tutoriel2_phrase3);
        step = 3;
        return true;
      }
    }
    else if(step == 3 && event == EVENT_CLICK_CONDITIONS_PLUS && (param as List).length == 0)
    {
      step = 4;
      return true;
    }
    else if(step == 4 && param is isMe)
    {
      step = 5;
      Storage.entity.buildButton = true;
      return true;
    }
    else if(step == 5 && event == EVENT_CLICK_CONDITIONS_PLUS)
    {
      step = 6;
      return true;
    }
    else if(step == 6 && event == EVENT_CLICK_CONDITIONS_NOUVEAU)
    {
      step = 7;
      cadre.remove();
      portrait.remove();
      return true;
    }
    return true;
  }
}

class Pointer extends PositionComponent
{
  String text;
  int dir;

  late final txt;
  late final Paint paint;
  late final Offset offsetLeft;
  late final Offset offsetRight;
  late final Rect rect;
  late final Path path;

  late final Vector2 txtInitialPosition;
  double offsetX = 0;
  double speed = -30;
  double target = -20;

  Pointer(this.text, this.dir, Vector2 position):super(position: position);

  @override
  Future<void> onLoad() async 
  {
    //print("Pointer.onLoad.start");
    await super.onLoad();
    paint = Paint()..color = Color.fromARGB(255, 224, 255, 21);

    txt = TextComponent(text, textRenderer: textPaint);
    txt.position = Vector2(5, 5);
    addChild(txt);
    
    double width = txt.textRenderer.measureTextWidth(text) + 10;
    double height = txt.textRenderer.measureTextHeight(text) + 10;
    
    if(dir == 1)
    {
      anchor = Anchor.topRight;
      offsetLeft = Offset(position.x - width - 15, position.y + height / 2);
      offsetRight = Offset(position.x - 15, position.y + height / 2);
      rect = Rect.fromLTWH(offsetLeft.dx, position.y, width, height);
      txt.position -= Vector2(10, 0);
      path = Path();
      path.moveTo(offsetRight.dx + 12, position.y + 5);
      path.lineTo(offsetRight.dx + 27, position.y + height / 2);
      path.lineTo(offsetRight.dx + 12, position.y + height - 5);
      path.lineTo(offsetRight.dx + 12, position.y + 5);
    }
    if(dir == 2)
    {
      offsetRight = Offset(position.x + width -15, position.y + height / 2);
      offsetLeft = Offset(position.x - 15, position.y + height / 2);
      rect = Rect.fromLTWH(offsetLeft.dx, position.y, width, height);
      txt.position -= Vector2(15, 0);
      path = Path();
      path.moveTo(offsetLeft.dx - 12, position.y + 5);
      path.lineTo(offsetLeft.dx - 27, position.y + height / 2);
      path.lineTo(offsetLeft.dx - 12, position.y + height - 5);
      path.lineTo(offsetLeft.dx - 12, position.y + 5);
      target = 20;
      speed = -speed;
    }

    txtInitialPosition = Vector2.copy(txt.position);
    size = Vector2(width, height);
    //print("Pointer.onLoad.end");
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.save();
    canvas.translate(offsetX, 0);
    canvas.drawCircle(offsetLeft, height / 2, paint);
    canvas.drawCircle(offsetRight, height / 2, paint);
    canvas.drawRect(rect, paint);
    canvas.drawPath(path, paint);
    canvas.restore();
    super.render(canvas);
  }

  @override
  void update(double dt) 
  {
    super.update(dt);
    offsetX += dt * speed;
    if(offsetX < min(0, target))
    {
      offsetX = min(0, target);
      speed = speed.abs();
    }
    if(offsetX > max(0, target))
    {
      offsetX = max(0, target);
      speed = -(speed.abs());
    }
    txt.position = txtInitialPosition + Vector2(offsetX, 0);
  }
}