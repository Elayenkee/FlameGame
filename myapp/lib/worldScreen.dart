import 'package:flame/game.dart';
import 'package:flutter/cupertino.dart';
import 'package:myapp/main.dart';

class WorldScreen extends StatelessWidget
{
  @override
  Widget build(BuildContext context) 
  {
    return GameWidget(game: WorldLayout());
  }
}

class WorldLayout extends AbstractLayout
{
  WorldLayout():super("World");
}