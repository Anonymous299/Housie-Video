import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:housiiee/common_widgets.dart';
import 'package:housiiee/main.dart';
import 'package:housiiee/player_data.dart';
import 'package:housiiee/ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authentication.dart';

//TODO remove appbar if not necessary
//First page of app. Contains heading, ticket and play button only
class HomeScreen extends StatefulWidget{
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  Auth _auth = new Auth();
  Timer _everySecond; //Makes play button appear and disappear every 1 second
  bool _isShowing = true;//Value changes every 1 second to make play button disappear
  bool _newUser = false;
  TextEditingController _usernameController = new TextEditingController();
  String _error = "";

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('Do you want to exit an App'),
        actions: <Widget>[
          new GestureDetector(
            onTap: () => Navigator.of(context).pop(false),
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new GestureDetector(
            onTap: () => Navigator.of(context).pop(true),
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<String> _getUsername() async {
    String key = 'username';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<void> _setUsername(String username) async{
    String key = 'username';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, username);
  }

  void _retrieveUsername() async{
    String username = await _getUsername();
    if(username == null){
      FirebaseUser user = await _auth.getCurrentUser();
      if(user == null){
        setState(() {
          _newUser = true;
        });
      }
    }
    else{
      USERNAME = username;
      setState(() {
        _newUser = false;
      });
    }
  }


  Widget _newUserScreen(){
    Card(
      elevation: 8.0,
      child: Container(
        alignment: Alignment.center,
        child: FractionallySizedBox(
          heightFactor: 0.5,
        ),
      )
    );
  }

  //Appbar widget
  Widget _appBar(ScaffoldState currentState){
    return AppBar(
      elevation: 0.0,
      backgroundColor: Colors.black12,
      //Opens navigation drawer
      leading: IconButton(
        icon: Icon(Icons.menu,color: Colors.black54,),
        onPressed: () {
          currentState.openDrawer();
        },
      ),
    );
  }
  //Housie heading
  Widget _heading(){
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: ResizableText(context, 4, "HOUSIIEE"),
    );
  }
  //Home screen ticket
  Widget _ticket(){
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: FractionallySizedBox(
        heightFactor: 0.5,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ResizableText(context, 11, "TAP THE LETTERS"),
            Ticket(gridState: HOMEGRID, ogGridState: OG_HOMEGRID)
          ],
        ),
      )
    );
  }

  Widget _playButton(){
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: AnimatedOpacity(
      opacity: _isShowing ? 1.0 : 0.0,
      duration: Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: (){
          },
        child:  ResizableText(context, 4, "PLAY", fontFamily: "Bubbly"),
      ),
    ),
    );
  }

  @override
  void initState(){
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _everySecond = Timer.periodic(Duration(milliseconds: 1000), (timer) { setState(() {
      _isShowing = !_isShowing;
      });
    });
    _retrieveUsername();
  }

  @override
  void dispose(){
    _everySecond.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: scaffoldKey,
//        appBar: _appBar(scaffoldKey.currentState),
        //TODO add navigation drawer
        body: Stack(
          children: <Widget>[
            _heading(),
            _ticket(),
            _playButton(),
            _newUser ? _newUserScreen() : Container(height: 0.0,),
          ],
        ),
      ),
    );
  }
}