import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderConditionGroupWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderTriFunctionWidget.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';

class BuilderTargetSelectorWidget extends StatefulWidget {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderTargetSelector builderTargetSelector;

  BuilderTargetSelectorWidget(BuilderBehaviourTotalWidget builderTotal,
      BuilderTargetSelector builderTargetSelector) {
    this.builderTotal = builderTotal;
    this.builderTargetSelector = builderTargetSelector;
  }

  _BuilderTargetSelector createState() => _BuilderTargetSelector();
}

class _BuilderTargetSelector extends State<BuilderTargetSelectorWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        //color: Colors.amber,
        decoration: FirstTheme.borderDecoration(),
        padding: EdgeInsets.all(10),
        child: getChild(),
      ),
    );
  }

  Widget getChild() {
    return Column(children: [
      BuilderTriFunctionWidget(
          widget.builderTotal, widget.builderTargetSelector.builderTriFunction),
      Container(
        height: 10,
      ),
      BuilderConditionGroupWidget(widget.builderTotal,
          widget.builderTargetSelector.builderConditionGroup),
    ]);
  }
}
