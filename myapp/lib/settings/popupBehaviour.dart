import 'package:flame/components.dart';
import 'package:flame/gestures.dart';
import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/engine/valuesolver.dart';
import 'package:myapp/engine/work.dart';
import 'package:myapp/settings/settings.dart';

import 'settings.dart';

class PopupBehaviour extends PositionComponent with Tappable
{
  final SettingsLayout layout;
  final BuilderBehaviourComponent builderComponent;

  late final Rect bgRect;
  late final Paint bgPaint;

  late final Rect frameRect;
  late final Paint framePaint;

  late final BoutonSprite btnClose;
  late final Sprite spriteChecked;
  late final Sprite spriteCancel;
  late final SpriteComponent componentValid;
  late final TextComponent txtName;
  late final Bouton btnTri;
  late final Bouton btnTriValue;
  late final Bouton btnWork;
  late final BoutonSprite btnAddCondition;

  final List<BuilderConditionComponent> conditionsComponents = [];
  
  PopupBehaviour(this.layout, this.builderComponent):super(priority: 500)
  {
    size = layout.size;
    bgPaint= Paint()..color = Colors.white.withOpacity(.7);
    bgRect = Rect.fromLTWH(0, 0, width, height);
    framePaint= Paint()..color = Colors.grey;
    frameRect = Rect.fromLTWH(10, 10, width - 20, height - 20);
    isHud = true;
    //resetOnNextTap();
  }

  /*void resetOnNextTap()
  {
    layout.onNextTap = (Object o)
    {
      print(o.toString());
      return false;
    };
  }*/

  @mustCallSuper
  @override
  void onMount() 
  {
    layout.popupBehaviour = this;
    super.onMount();
  }

  void close()
  {
    layout.popupBehaviour = null;
    layout.components.remove(this); 
    //layout.onNextTap = null;
  }

  @override
  Future<void> onLoad() async
  { 
    // CLOSE
    btnClose = BoutonSprite(layout, close, Sprite(layout.images.fromCache('button_cancel.png')));
    btnClose.anchor = Anchor.topRight;
    btnClose.position = Vector2(size.x - 15, 15);
    //btnClose.listen = false;
    addChild(btnClose);

    // VALID
    spriteChecked = Sprite(layout.images.fromCache('button_checked.png'));
    spriteCancel = Sprite(layout.images.fromCache('button_cancel.png'));
    componentValid = SpriteComponent();
    componentValid.size = Vector2.all(30);
    componentValid.position = Vector2(15, 15);
    updateComponentValid();
    addChild(componentValid);

    // NAME
    txtName = new TextComponent(builderComponent.builderBehaviour.name);
    txtName.position = Vector2(55, 15);
    addChild(txtName);

    // TRI FUNCTION
    String txtTri = builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.tri != null ? getNameForButton(builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.tri!) : "Aucun";
    btnTri = Bouton(layout, (){
      PopupChoose(layout, btnTri.position + position + Vector2(btnTri.size.x, 0), TriFunctions.values, (TriFunctions chosen){
        builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.tri = chosen;
        builderComponent.updateComponentValid();
        btnTri.txt.text = getNameForButton(chosen);
      }).show();
    }, txtTri, Vector2(130, 40), Vector2(15, 60));
    addChild(btnTri);

    // TRI VALUE
    String txtTriValue = builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.value != null ? getNameForButton(builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.value!) : "Aucun";
    btnTriValue = Bouton(layout, (){
      PopupChoose(layout, btnTriValue.position + position + Vector2(btnTriValue.size.x, 0), VALUE.values, (VALUE chosen){
        builderComponent.builderBehaviour.builderTargetSelector.builderTriFunction.value = chosen;
        builderComponent.updateComponentValid();
        btnTriValue.txt.text = getNameForButton(chosen);
      }).show();
    }, txtTriValue, Vector2(130, 40), Vector2(155, 60));
    addChild(btnTriValue, gameRef: layout);

    // CONDITIONS
    for(int i = 0; i < builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length; i++)
    {
      BuilderCondition builderCondition = builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.conditions[i];
      BuilderConditionComponent conditionComponent = BuilderConditionComponent(layout, this, builderComponent, builderCondition, Vector2(15, 110 + (BuilderConditionComponent._height + 10) * i), size.x - 40);
      conditionsComponents.add(conditionComponent);
      addChild(conditionComponent);
    }
    btnAddCondition = BoutonSprite(layout, (){
      BuilderCondition builderCondition = builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.addCondition();
      BuilderConditionComponent conditionComponent = BuilderConditionComponent(layout, this, builderComponent, builderCondition, Vector2(15, 110 + (BuilderConditionComponent._height + 10) * (builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length - 1)), size.x - 40);
      conditionsComponents.add(conditionComponent);
      addChild(conditionComponent, gameRef: layout);
      updateConditionsPositions();
      updateComponentValid();
    }, Sprite(layout.images.fromCache('button_plus.png')));
    //btnAddCondition.listen = false;
    btnAddCondition.anchor = Anchor.topCenter;
    addChild(btnAddCondition);
    updateConditionsPositions();

    // WORK
    String txtWork = builderComponent.builderBehaviour.builderWork.work != null ? getNameForButton(builderComponent.builderBehaviour.builderWork.work!) : "Aucun";
    btnWork = Bouton(layout, (){
      PopupChoose(layout, btnWork.position + position + Vector2(btnWork.size.x, 0), Works.values, (Works chosen){
        builderComponent.builderBehaviour.builderWork.work = chosen;
        builderComponent.updateComponentValid();
        updateComponentValid();
        btnWork.txt.text = getNameForButton(chosen);
      }).show();
    }, txtWork, Vector2(130, 40), Vector2(15, size.y - 55));
    addChild(btnWork);

    return super.onLoad();
  }

  void updateComponentValid()
  {
    bool resultValid = builderComponent.builderBehaviour.isValid(Validator(true));
    componentValid.sprite = resultValid ? spriteChecked : spriteCancel;
  }

  void updateConditionsPositions()
  {
    for(int i = 0; i < conditionsComponents.length; i++)
    {
      conditionsComponents[i].position.y = 108 + (BuilderConditionComponent._height + 7) * i;
      conditionsComponents[i].updateRect();
    }
    
    int nbConditions = builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.length;
    if(nbConditions >= 5)
      btnAddCondition.position.x = -1000;
    else
      btnAddCondition.position = Vector2(size.x / 2, 110 + ((BuilderConditionComponent._height + 9) * nbConditions));
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    canvas.drawRect(frameRect, framePaint);
    super.render(canvas);
  }

  @override
  bool onTapCancel() 
  {
    return true;
  }

  @override
  bool onTapDown(TapDownInfo info) 
  {
    return true;
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    print("PopupBehaviour::onTapUp");
    return false;
  }

  double test = 0;
  @override
  void update(double dt) 
  {
    super.update(dt);
  }
}

class BuilderConditionComponent extends PositionComponent
{
  static const double _height = 60;

  final SettingsLayout layout;
  final PopupBehaviour popup;
  final BuilderBehaviourComponent builderComponent;
  final BuilderCondition builderCondition;
  late Rect frameRect;
  late final Paint framePaint;

  late final List<Bouton> boutons = [];

  BuilderConditionComponent(this.layout, this.popup, this.builderComponent, this.builderCondition, Vector2 position, double _width):super(position: position)
  {
    size.x = _width;
    size.y = _height;
    framePaint= Paint()..color = Colors.grey.shade200;
    frameRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
  }

  @override
  Future<void> onLoad() async
  {
    BoutonSprite btnDelete = BoutonSprite(layout, (){
      builderComponent.builderBehaviour.builderTargetSelector.builderConditionGroup.conditions.remove(builderCondition);
      popup.conditionsComponents.remove(this);
      popup.updateConditionsPositions();
      popup.updateComponentValid();
      remove();
    }, Sprite(layout.images.fromCache('button_delete.png')));
    btnDelete.anchor = Anchor.centerRight;
    btnDelete.position = Vector2(size.x - 5, size.y / 2);
    //btnDelete.listen = false;
    addChild(btnDelete);

    // Boutons
    buildBoutons();

    return super.onLoad();
  }

  void buildBoutons()
  {
    for(Bouton bouton in boutons)
      bouton.remove();
    boutons.clear();

    final double btnY = 10;
    Conditions? cond = builderCondition.cond;
    Bouton btnCondition = Bouton(layout, (){}, cond != null ? getNameForButton(cond) : "Choisir", Vector2(130, 40), Vector2(10, btnY));
    btnCondition.onTap = (){
      Vector2 popupPosition = getGlobalPosition(btnCondition) + Vector2(130, 0);
      PopupChoose(layout, popupPosition, Conditions.values, (Conditions chosen){
        builderCondition.setCondition(chosen);
        popup.updateComponentValid();
        buildBoutons();
      }).show();
    };
    
    if (cond != null) 
    {
      List<ParamTypes> params = cond.getParams();
      if (cond.isBinary()) 
      {
        String txtValue = builderCondition.params[2] == null ? "Choisir" : getNameForButton(builderCondition.params[2]);
        Bouton btnValue = Bouton(layout, (){}, txtValue, Vector2(130, 40), Vector2(10, btnY));
        btnValue.onTap = (){
          List values = List.from(VALUE.values);
          values.add(BuilderCount());
          Vector2 positionPopup = getGlobalPosition(btnValue) + Vector2(btnValue.size.x, 0);
          PopupChoose(layout, positionPopup, values, (value){
            Function onChoose = (value){
              print("onChosen $value");
              builderCondition.setParam(2, value);
              builderComponent.updateComponentValid();
              popup.updateComponentValid();
              btnValue.txt.text = getNameForButton(value);
            };
            onChoose(value);
            if(value is BuilderCount)
              onChooseCount(value, positionPopup, onChoose);
          }).show();
        };
        boutons.add(btnValue);
        addChild(btnValue, gameRef: layout);
        
        btnCondition.position = Vector2(150, btnY);
        boutons.add(btnCondition);
        addChild(btnCondition, gameRef: layout);
        
        String txtParam1 = builderCondition.params[1] == null ? "Choisir" : getNameForButton(builderCondition.params[1]);
        Bouton boutonParam1 = Bouton(layout, (){}, txtParam1, Vector2(130, 40), Vector2(290, btnY));
        boutonParam1.onTap = (){
          int defaultValue = builderCondition.params[1] is ValueAtom ? builderCondition.params[1].getIntValue() : 0;
          PopupValueInt popupValue = PopupValueInt(layout, getGlobalPosition(boutonParam1) + Vector2(boutonParam1.width, 0), defaultValue)..show();
          popupValue.onChoose = (value){
            builderCondition.setParam(1, value);
            boutonParam1.txt.text = getNameForButton(value);
            builderComponent.updateComponentValid();
            popup.updateComponentValid();
          };
        };
        boutons.add(boutonParam1); 
        addChild(boutonParam1, gameRef: layout);
      }
      else
      {
        boutons.add(btnCondition);
        addChild(btnCondition, gameRef: layout);
        for (int i = 1; i < params.length; i++) 
        {
          String txtParam = builderCondition.params[i] == null ? "Choisir" : getNameForButton(builderCondition.params[i]);
          Bouton boutonParam = Bouton(layout, (){}, txtParam, Vector2(130, 40), Vector2(10 + (i * 140), btnY));
          boutonParam.onTap = (){
            //TODO
            
          };
          boutons.add(boutonParam); 
          addChild(boutonParam, gameRef: layout);
        }
      }
    } 
    else 
    {
      boutons.add(btnCondition);
      addChild(btnCondition, gameRef: layout);
    }
  }

  void onChooseCount(BuilderCount builderCount, Vector2 positionPopup, Function onChoose)
  {
    print("onChooseCount");
    PopupChoose(layout, positionPopup, VALUE.values, (value){
      builderCount.setValue(value);
      onChoose(builderCount);
    }).show();
  }

  void updateRect()
  {
    frameRect = Rect.fromLTWH(position.x, position.y, size.x, size.y);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(frameRect, framePaint);
    super.render(canvas);
  }
}

class Popup extends PositionComponent with Tappable
{
  final SettingsLayout layout;
  
  late final Rect bgRect;
  late final Paint bgPaint;

  late final Paint framePaint;
  late final Rect frameRect;

  late Vector2 _position;
  late final Vector2 _size;
  
  Popup(this.layout, Vector2 position):super(priority: 1000)
  {
    size = layout.size;
    _position = position + Vector2(10, 0);
    bgPaint= Paint()..color = Colors.white.withOpacity(.8);
    framePaint= Paint()..color = Colors.brown;
  }

  void updatePosition()
  {
    double offset = _position.y + _size.y - size.y;
    if(offset > 0)
      _position -= Vector2(0, offset + 10);
    frameRect = Rect.fromLTWH(_position.x, _position.y, _size.x, _size.y);
    bgRect = Rect.fromLTWH(0, 0, size.x, size.y);
  }

  void show()
  {
    layout.add(this);
  }

  @override
  void render(Canvas canvas) 
  {
    canvas.drawRect(bgRect, bgPaint);
    canvas.drawRect(frameRect, framePaint);
    super.render(canvas);
  }

  void close()
  {
    layout.components.remove(this);
  }

  @override
  bool onTapCancel() 
  {
    return false;
  }

  @override
  bool onTapDown(TapDownInfo info) 
  {
    return false;
  }

  @override
  bool onTapUp(TapUpInfo info) 
  {
    close();
    return false;
  }
}

class PopupValueInt extends Popup
{
  Function onChoose = (v){};

  PopupValueInt(SettingsLayout layout, Vector2 position, int defaultValue):super(layout, position)  
  {
    ValueModifier valueModifier = ValueModifier(layout, defaultValue, "");
    valueModifier.position = _position + Vector2.all(5);
    valueModifier.init();
    addChild(valueModifier);

    Grid grid = Grid(layout, layout.builderServer.builderEntities, onClick: (item){
      onClickOK(item);
    });
    grid.position = _position + Vector2(valueModifier.width + 15, 5);
    addChild(grid);

    Bouton btnOK = Bouton(layout, (){
      ValueAtom valueAtom = ValueAtom(valueModifier.currentValue);
      onClickOK(valueAtom);
    }, "OK", Vector2.all(valueModifier.height - 20), _position + Vector2(15, valueModifier.height + 10));
    addChild(btnOK);

    _size = Vector2.all(10) + Vector2(10 + valueModifier.width + grid.height, grid.height);
    updatePosition();
  }

  void onClickOK(Object value)
  {
    close();
    onChoose(value);
  }
}

class PopupChoose extends Popup
{
  PopupChoose(SettingsLayout layout, Vector2 position, List items, Function onChoose):super(layout, position)  
  {
    Grid grid = Grid(layout, items, onClick: (item){
        onChoose(item);
        close();
    });
    addChild(grid);    
    _size = grid.size + Vector2.all(5);

    updatePosition();
    grid.position = _position + Vector2.all(5);
  }
}

class Grid extends PositionComponent
{
  static const double _buttonWidth = 130;
  static const double _buttonHeight = 40;

  Grid(SettingsLayout layout, List items, {int lines = 6, Function? onClick,}):super()
  {
    int nbColumns = 1 + ((items.length - 1) ~/ lines);
    int nbLines = items.length < lines ? items.length : lines;
    size = Vector2((5 + _buttonWidth) * nbColumns, (5 + _buttonHeight) * nbLines);

    int index = 0;
    Vector2 _size = Vector2(_buttonWidth, _buttonHeight);
    for(Object item in items)
    {
      int i = index ~/ nbLines;
      int j = index % nbLines;
      Vector2 _position = Vector2(i * (_buttonWidth + 5), j * (_buttonHeight + 5));
      
      Bouton bouton = Bouton(layout, (){
        if(onClick != null)
          onClick(item);
      }, getNameForButton(item), _size,  _position);
      addChild(bouton);
      index++;
    }
  }
}