import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderTriFunctionWidget.dart';
import 'package:myapp/graphics/builderWidgets/widgets/builderButton.dart';
import 'package:myapp/graphics/builderWidgets/widgets/buttonChangeNotifier.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/graphics/themes/popup.dart';
import 'package:provider/provider.dart';

class BuilderConditionWidget extends StatefulWidget 
{
  late final BuilderCondition builderCondition;
  late final BuilderBehaviourTotalWidget builderTotal;

  BuilderConditionWidget(BuilderBehaviourTotalWidget builderTotal, BuilderCondition builderCondition) 
  {
    this.builderTotal = builderTotal;
    this.builderCondition = builderCondition;
  }

  _BuilderCondition createState() => _BuilderCondition();
}

class _BuilderCondition extends State<BuilderConditionWidget> 
{
  @override
  Widget build(BuildContext context) 
  {
    Widget child = Container(decoration: FirstTheme.borderDecoration(), padding: EdgeInsets.all(10), child: getChild(context),); 
    return Card(elevation: 8, child: child);
  }

  Widget getChild(BuildContext context) 
  {
    List<Widget> liste = [];

    Conditions? cond = widget.builderCondition.cond;
    if (cond != null) 
    {
      List<ParamTypes> params = cond.getParams();
      if (cond.isBinary()) 
      {
        liste.add(ParamButton(context, 2, params[2]));
        liste.add(Container(width: 10,));
        liste.add(ConditionButton(context));
        liste.add(Container(width: 10,));
        liste.add(ParamButton(context, 1, params[1]));
      } 
      else 
      {
        liste.add(ConditionButton(context));
        for (int i = 1; i < params.length; i++) 
        {
          liste.add(Container(width: 10,));
          liste.add(ParamButton(context, i, params[i]));
        }
      }
    } 
    else 
    {
      liste.add(ConditionButton(context));
    }

    return Row(children: liste);
  }

  Widget ParamButton(BuildContext context, int index, ParamTypes type) 
  {
    if (type == ParamTypes.Value)
    {
      Function onChosen = (v)
      {
        print("triFunction onChosen from popup");
        widget.builderCondition.setParam(index, v);
        widget.builderTotal.onChanged();
        setState(() {});
      };

      return BuilderTriFunctionWidget.getValueButton(context, widget.builderTotal, onChosen, widget.builderCondition.params[index]);
    }

    Object? param = widget.builderCondition.params[index];
    Widget buttonContent = param == null ? Icon(Icons.more_horiz, color: Colors.white, size: 30) : Text(widget.builderCondition.params[index].toString(), style: TextStyle(fontSize: 8, color: Colors.white));

    VoidCallback? onPressed = () 
    {
      print("click on param at index $index");
      if (widget.builderTotal.onTap(context, type)) 
      {
        print("=> builderTotal executed 'onTap'");
        return;
      }

      print("Add onNextTap to builderTotal");
      widget.builderTotal.onNextTap = (o) 
      {
        if (widget.builderCondition.canSetParam(index, o)) 
        {
          widget.builderCondition.setParam(index, o);
          widget.builderTotal.onChanged();
          setState(() {});
        }
      };

      Provider.of<ButtonChangeNotifier>(context, listen: false) .check((o) => widget.builderCondition.canSetParam(index, o));
    };

    Widget button = MaterialButton(onPressed: onPressed, color: FirstTheme.buttonColor, child: buttonContent);

    Widget builderButton = BuilderButton(widget.builderCondition.cond, button);

    return builderButton;
  }

  Widget ConditionButton(BuildContext context) 
  {
    return BuilderButton(widget.builderCondition.cond, MaterialButton(
        onPressed: () {
          if (widget.builderTotal.onTap(context, widget.builderCondition.cond))
            return;
          Popup.Show(context, conditionsPopup(context));
        },
        color: FirstTheme.buttonColor,
        child: widget.builderCondition.cond == null
            ? Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 20,
              )
            : Text(widget.builderCondition.cond!.getName(),
                style: TextStyle(fontSize: 8, color: Colors.white)),
      ),
    );
  }

  Widget conditionsPopup(BuildContext context) {
    return Column(
      children: Conditions.values.map((c) {
        return Column(
            children: [conditionsButton(context, c), Container(height: 10)]);
      }).toList(),
    );
  }

  Widget conditionsButton(BuildContext context, Conditions c) {
    return MaterialButton(
      onPressed: () {
        widget.builderCondition.setCondition(c);
        widget.builderTotal.onChanged();
        setState(() {});
        Navigator.pop(context);
      },
      minWidth: 200,
      height: 40,
      color: widget.builderCondition.cond == c
          ? Colors.blue
          : FirstTheme.buttonColor,
      child: Text(c.getName()),
    );
  }
}
