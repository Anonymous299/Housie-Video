import 'package:flutter/material.dart';
import 'package:housie/HomeScreen.dart';
import 'package:housie/call.dart';
import 'package:housie/game_session.dart';

final GlobalKey scaffoldKey = new GlobalKey();
void main() {
  runApp(MyApp());
}
class MyApp extends StatelessWidget{
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Housie App",
      initialRoute: '/',
      routes: {
        '/': (context) => HomeScreen(),
        '/gameSession': (context) => GameSession(),
        '/callPage': (context) => CallPage(),
      },
    );
  }
}
