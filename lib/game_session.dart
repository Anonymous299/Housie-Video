import 'dart:ui';

import 'package:flutter/cupertino.dart';

class GameSession extends StatefulWidget{
  @override
  _GameSessionState createState() => _GameSessionState();
}
class _GameSessionState extends State<GameSession>{
  @override
  Widget build(BuildContext context) {
    return BackdropFilter(
        filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
    child: Container(),
    );
  }
}