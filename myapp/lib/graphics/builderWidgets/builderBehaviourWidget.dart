import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderTargetSelectorWidget.dart';
import 'package:myapp/graphics/builderWidgets/builderWorkWidget.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';

class BuilderBehaviourWidget extends StatelessWidget {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderBehaviour builderBehaviour;

  BuilderBehaviourWidget(BuilderBehaviourTotalWidget builderTotal,
      BuilderBehaviour builderBehaviour) {
    this.builderTotal = builderTotal;
    this.builderBehaviour = builderBehaviour;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        //color: Colors.red,
        decoration: FirstTheme.borderDecoration(),
        padding: EdgeInsets.all(10),
        child: getChild(),
      ),
    );
  }

  Widget getChild() {
    List<Widget> liste = [];

    liste.add(BuilderTargetSelectorWidget(
        builderTotal, builderBehaviour.builderTargetSelector));
    liste.add(Container(
      height: 5,
    ));

    liste.add(BuilderWorkWidget(builderTotal, builderBehaviour.builderWork));

    return Column(children: liste);
  }
}
