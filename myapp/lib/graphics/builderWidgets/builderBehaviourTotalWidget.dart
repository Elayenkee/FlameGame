import 'package:flutter/material.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourWidget.dart';
import 'package:myapp/engine/entity.dart';
import 'package:myapp/graphics/builderWidgets/widgets/builderButton.dart';
import 'package:myapp/graphics/builderWidgets/widgets/buttonChangeNotifier.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/engine/server.dart';
import 'package:provider/provider.dart';

class BuilderBehaviourTotalWidget extends StatelessWidget {
  late final Server server;
  late final Entity entity;
  late final BuilderTotal builderTotal;
  late final ButtonChangeNotifier changeNotifier;
  late final BuilderValidWidget builderValidWidget;

  Function? onNextTap;

  BuilderBehaviourTotalWidget(
      Server server, Entity entity, BuilderTotal builderTotal) {
    this.server = server;
    this.entity = entity;
    this.builderTotal = builderTotal;
    this.changeNotifier = ButtonChangeNotifier();
  }

  @override
  Widget build(BuildContext context) {
    builderValidWidget = BuilderValidWidget(builderTotal);

    return ChangeNotifierProvider(
      create: (context) => changeNotifier,
      child: FittedBox(
        child: Column(
          children: [
            builderValidWidget,
            Row(
              children: [
                Container(
                  child: SingleChildScrollView(
                      padding: EdgeInsets.all(10),
                      child: Container(
                          child: Column(
                        children: builderTotal.builderBehaviours
                            .map((builderBehaviour) {
                          return Container(
                            child: Column(
                              children: [
                                BuilderBehaviourWidget(this, builderBehaviour),
                                Container(
                                  height: 10,
                                )
                              ],
                            ),
                          );
                        }).toList(),
                      ))),
                ),
                Container(
                  width: 100,
                  child: Column(
                      children: server.getAllies().map((e) {
                    return Container(
                      padding: EdgeInsets.all(10),
                      width: 80,
                      height: 50,
                      child: BuilderButton(
                          e,
                          MaterialButton(
                              onPressed: () {
                                print("onPressed $e");
                                if (onTap(context, e)) return;
                              },
                              color: FirstTheme.buttonColor,
                              child: Text(e.getName(),
                                  style: TextStyle(
                                      fontSize: 8, color: Colors.white)))),
                    );
                  }).toList()),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  bool onTap(BuildContext context, Object? o) {
    if (onNextTap != null) {
      onNextTap!(o);
      onNextTap = null;
      changeNotifier.check(null);
      return true;
    }
    return false;
  }

  void onChanged() {
    builderValidWidget.onChanged();
  }
}

class BuilderValidWidget extends StatefulWidget {
  late final _BuilderValidWidget _builderValidWidget;

  final BuilderTotal builderTotal;

  BuilderValidWidget(this.builderTotal);

  @override
  State<StatefulWidget> createState() {
    _builderValidWidget = _BuilderValidWidget(builderTotal);
    return _builderValidWidget;
  }

  void onChanged() {
    _builderValidWidget.onChanged();
  }
}

class _BuilderValidWidget extends State<BuilderValidWidget> {
  BuilderTotal builderTotal;

  _BuilderValidWidget(this.builderTotal);

  void onChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 50,
      height: 50,
      color: builderTotal.isValid(Validator(false)) ? Colors.green : Colors.red,
    );
  }
}
