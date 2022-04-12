import 'package:flutter/foundation.dart';

class ButtonChangeNotifier extends ChangeNotifier {
  Function? isHighLighted = null;

  void check(Function? isHighLighted) {
    this.isHighLighted = isHighLighted;
    notifyListeners();
  }
}
