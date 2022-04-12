import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderConditionWidget.dart';
import 'package:myapp/graphics/builderWidgets/widgets/builderButton.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';

class BuilderConditionGroupWidget extends StatefulWidget {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderConditionGroup builderConditionGroup;

  BuilderConditionGroupWidget(BuilderBehaviourTotalWidget builderTotal,
      BuilderConditionGroup builderConditionGroup) {
    this.builderTotal = builderTotal;
    this.builderConditionGroup = builderConditionGroup;
  }

  _BuilderConditionGroup createState() =>
      _BuilderConditionGroup(builderTotal, builderConditionGroup);
}

class _BuilderConditionGroup extends State<BuilderConditionGroupWidget> {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderConditionGroup builderConditionGroup;

  _BuilderConditionGroup(BuilderBehaviourTotalWidget builderTotal,
      BuilderConditionGroup builderConditionGroup) {
    this.builderTotal = builderTotal;
    this.builderConditionGroup = builderConditionGroup;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        //color: Colors.blue,
        decoration: FirstTheme.borderDecoration(),
        padding: EdgeInsets.all(10),
        child: getChild(context),
      ),
    );
  }

  Widget getChild(BuildContext context) {
    List<Widget> liste = [];

    builderConditionGroup.conditions.forEach((cond) {
      liste.add(Row(children: [
        BuilderConditionWidget(builderTotal, cond),
        Container(width: 10),
        Container(
          width: 50,
          child: BuilderButton(
            null,
            MaterialButton(
              onPressed: () {
                if (widget.builderTotal.onTap(context, null)) return;
                builderConditionGroup.conditions.remove(cond);
                builderTotal.onChanged();
                setState(() {});
              },
              color: Colors.red,
              child: Icon(
                Icons.delete,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
        ),
      ]));
    });

    liste.add(Container(
      height: 5,
    ));

    liste.add(Row(children: [
      Container(
          width: 50,
          child: BuilderButton(
            null,
            MaterialButton(
              onPressed: () {
                if (widget.builderTotal.onTap(context, null)) return;
                builderConditionGroup.addCondition();
                builderTotal.onChanged();
                setState(() {});
              },
              color: FirstTheme.buttonColor,
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: 20,
              ),
            ),
          ))
    ]));

    return Column(children: liste);
  }
}
