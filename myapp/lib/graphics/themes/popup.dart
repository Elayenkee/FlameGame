import 'package:flutter/material.dart';
import 'package:myapp/graphics/themes/firstTheme.dart';

class Popup extends StatelessWidget {
  static Show(BuildContext mContext, Widget child) {
    showDialog(
        context: mContext,
        builder: (BuildContext context) {
          return Popup(child);
        });
  }

  final Widget child;

  Popup(this.child) {}

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20),
      child: Container(
        padding: EdgeInsets.all(10),
        color: Colors.white,
        child: Column(
          children: [
            closeButton(context),
            Container(
              height: 10,
            ),
            child
          ],
        ),
      ),
    );
  }

  Widget closeButton(BuildContext context) {
    return Container(
      alignment: Alignment.topRight,
      //width: 48,
      height: 30,
      child: MaterialButton(
          onPressed: () {
            Navigator.pop(context);
          },
          shape: CircleBorder(),
          color: FirstTheme.buttonColor,
          child: Icon(
            Icons.close,
            color: Colors.white,
          )),
    );
  }
}
