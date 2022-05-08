import 'package:flutter/material.dart';
import 'package:myapp/bdd.dart';
import 'package:myapp/builder.dart';
import 'package:myapp/graphics/builderWidgets/builderBehaviourTotalWidget.dart';
import 'package:myapp/graphics/builderWidgets/widgets/builderButton.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';
import 'package:myapp/graphics/themes/popup.dart';
import 'package:myapp/works/work.dart';

class BuilderWorkWidget extends StatefulWidget {
  late final BuilderBehaviourTotalWidget builderTotal;
  late final BuilderWork builderWork;

  BuilderWorkWidget(
      BuilderBehaviourTotalWidget builderTotal, BuilderWork builderWork) {
    this.builderTotal = builderTotal;
    this.builderWork = builderWork;
  }

  _BuilderWorkWidget createState() => _BuilderWorkWidget();
}

class _BuilderWorkWidget extends State<BuilderWorkWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      child: Container(
        //color: Colors.brown,
        decoration: FirstTheme.borderDecoration(),
        padding: EdgeInsets.all(10),
        child: getChild(),
      ),
    );
  }

  Widget getChild() {
    return Container(
      alignment: Alignment.topLeft,
      child: BuilderButton(
        widget.builderWork.work,
        MaterialButton(
          onPressed: () {
            if (widget.builderTotal.onTap(context, widget.builderWork.work))
              return;
            Popup.Show(context, worksWidget(context));
          },
          color: FirstTheme.buttonColor,
          child: getButtonWidget(),
        ),
      ),
    );
  }

  Widget getButtonWidget() {
    return widget.builderWork.work == null
        ? Icon(
            Icons.more_horiz,
            color: Colors.white,
            size: 30,
          )
        : Text(widget.builderWork.work!.toString(),
            style: TextStyle(fontSize: 8, color: Colors.white));
  }

  Widget worksWidget(BuildContext context) {
    return Column(
      children: Work.values.map((w) {
        return Column(
            children: [workButton(context, w), Container(height: 10)]);
      }).toList(),
    );
  }

  Widget workButton(BuildContext context, Work w) {
    return MaterialButton(
      onPressed: () {
        widget.builderWork.work = w;
        widget.builderTotal.onChanged();
        setState(() {});
        Navigator.pop(context);
      },
      minWidth: 200,
      height: 40,
      color:
          widget.builderWork.work == w ? Colors.blue : FirstTheme.buttonColor,
      child: Text(w.toString()),
    );
  }
}
