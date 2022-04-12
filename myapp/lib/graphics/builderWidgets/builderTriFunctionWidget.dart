import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/widgets/builderButton.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/graphics/themes/popup.dart';
import 'package:myapp/engine/valuesolver.dart';

class BuilderTriFunctionWidget extends StatefulWidget {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderTriFunction builderTriFunction;

  BuilderTriFunctionWidget(BuilderBehaviourTotalWidget builderTotal,
      BuilderTriFunction builderTriFunction) {
    this.builderTotal = builderTotal;
    this.builderTriFunction = builderTriFunction;
  }

  _BuilderTriFunctionWidget createState() => _BuilderTriFunctionWidget();

  static Widget getValueButton(
      BuildContext context,
      BuilderBehaviourTotalWidget builderTotal,
      Function onChosen,
      VALUE? selected) {
    return _BuilderTriFunctionWidget.getValueButton(
        context, builderTotal, onChosen, selected);
  }
}

class _BuilderTriFunctionWidget extends State<BuilderTriFunctionWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        decoration: FirstTheme.borderDecoration(),
        padding: EdgeInsets.all(10),
        child: getChild(context),
      ),
    );
  }

  Widget getChild(BuildContext context) {
    return Row(
      children: [
        getTriFunctionButton(context),
        Container(
          width: 10,
        ),
        getValueButton(context, widget.builderTotal, (v) {
          print("onChosen from getChild ligne 53 $v");
          widget.builderTriFunction.value = v;
          widget.builderTotal.onChanged();
          setState(() {});
        }, widget.builderTriFunction.value)
      ],
    );
  }

  Widget getTriFunctionButton(BuildContext context) {
    return BuilderButton(
      widget.builderTriFunction.tri,
      MaterialButton(
        onPressed: () {
          if (widget.builderTotal.onTap(context, widget.builderTriFunction.tri))
            return;
          Popup.Show(context, triFunctionsWidget());
        },
        color: FirstTheme.buttonColor,
        child: widget.builderTriFunction.tri == null
            ? Icon(
                Icons.more_horiz,
                color: Colors.white,
                size: 30,
              )
            : Text(widget.builderTriFunction.tri!.toString(),
                style: TextStyle(fontSize: 8, color: Colors.white)),
      ),
    );
  }

  Widget triFunctionsWidget() {
    return Column(
      children: TriFunctions.values.map((t) {
        return Column(
            children: [triFunctionsButton(context, t), Container(height: 10)]);
      }).toList(),
    );
  }

  Widget triFunctionsButton(BuildContext context, TriFunctions t) {
    return MaterialButton(
      onPressed: () {
        widget.builderTriFunction.tri = t;
        widget.builderTotal.onChanged();
        setState(() {});
        Navigator.pop(context);
      },
      minWidth: 200,
      height: 40,
      color: widget.builderTriFunction.tri == t
          ? Colors.blue
          : FirstTheme.buttonColor,
      child: Text(t.toString()),
    );
  }

  static Widget getValueButton(
      BuildContext context,
      BuilderBehaviourTotalWidget builderTotal,
      Function onChosen,
      VALUE? selected) {
    return BuilderButton(
      selected,
      MaterialButton(
          onPressed: () {
            print("onPressed value button $selected");
            if (builderTotal.onTap(context, selected)) return;
            Popup.Show(context, valuesWidget(context, onChosen, selected));
          },
          color: FirstTheme.buttonColor,
          child: selected == null
              ? Icon(
                  Icons.more_horiz,
                  color: Colors.white,
                  size: 30,
                )
              : Text(selected.toString(),
                  style: TextStyle(fontSize: 8, color: Colors.white))),
    );
  }

  static Widget valuesWidget(
      BuildContext context, Function onChosen, VALUE? selected) {
    List<Widget> rows = [];

    List<Widget> buttons = [];
    VALUE.values.forEach((value) {
      buttons.add(valuesButton(context, value, onChosen, selected));
      if (buttons.length == 3) {
        rows.add(Row(children: buttons));
        buttons = [];
      }
    });
    if (buttons.length > 0) rows.add(Row(children: buttons));

    return FittedBox(
      child: Center(
        child: Column(
          children: rows,
        ),
      ),
    );
  }

  static Widget valuesButton(
      BuildContext context, VALUE v, Function onChosen, VALUE? selected) {
    return Padding(
      padding: const EdgeInsets.all(3.0),
      child: MaterialButton(
        onPressed: () {
          print("onPressed values button $v");
          onChosen(v);
          Navigator.pop(context);
        },
        minWidth: 200,
        height: 40,
        color: selected == v ? Colors.blue : FirstTheme.buttonColor,
        child: Text(v.toString()),
      ),
    );
  }
}
