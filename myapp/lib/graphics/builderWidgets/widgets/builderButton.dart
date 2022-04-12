import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:myapp/graphics/builderWidgets/widgets/buttonChangeNotifier.dart';
import 'package:provider/provider.dart';

// NEXT 10
class BuilderButton extends StatefulWidget {
  final Widget child;
  final Object? objectToCheck;
  BuilderButton(this.objectToCheck, this.child);

  @override
  State<StatefulWidget> createState() {
    return _BuilderButton();
  }
}

class _BuilderButton extends State<BuilderButton> {
  @override
  Widget build(BuildContext context) {
    Consumer<ButtonChangeNotifier> consumer = Consumer(
      builder: (c, button, child) {
        bool highlighted = button.isHighLighted != null &&
            button.isHighLighted!(widget.objectToCheck);
        bool enabled = highlighted || button.isHighLighted == null;
        return Card(
          child: Opacity(
            opacity: enabled ? 1 : .5,
            child: Container(
              child: widget.child,
              color: highlighted ? Colors.yellow : Colors.white.withAlpha(0),
              padding: EdgeInsets.all(2),
            ),
          ),
        );
      },
    );

    return consumer;
  }
}
