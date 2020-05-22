import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:ads/ads.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/common_widgets.dart';
import 'package:housie/list_generator.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:housie/settings.dart';
import 'package:permission_handler/permission_handler.dart';

import 'HomeScreen.dart';



class GameSession extends StatefulWidget{
  @override
  _GameSessionState createState() => _GameSessionState();
}
class _GameSessionState extends State<GameSession>{

  List<bool> _gameButtonsSelected = [true, false];//stores selection state of toggle buttons
  List<String> _gameButtonList = ["NEW GAME", "JOIN GAME"];
  List<bool> _videoButtonsSelected = [VIDEO, !VIDEO];//stores selection state of toggle buttons
  List<String> _videoButtonList = ["VIDEO", "NO VIDEO"];
  DatabaseReference _sessionDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e.firebaseio.com/").reference().child("sessions"); //TODO add new database to firebase and update databaseURL accordingly
  DatabaseReference _playerDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e-71bf5.firebaseio.com/").reference().child("players");
  List<String> _playerList = [];
  StreamSubscription _childAddedSubscription;
  StreamSubscription _childChangedSubscription;
  StreamSubscription _childDeletedSubscription;
  bool _isShowing = true;
  Timer _everySecond;
  TextEditingController _codeController = new TextEditingController();
  TextEditingController _numController = new TextEditingController();
  String _error="";
  String _numError = "";
  bool _showHostAlert = false;
  bool _pressed = false;
  bool _pressedSubmit = false;


  void _deleteSession(){
    HOST = false;
    _sessionDatabase.child(SETTINGS.code).remove();
    SETTINGS.reset();
  }

  void _updatePlayerList(Event event){
    try{
      List<dynamic> dyn_onlineList = event.snapshot.value['pL'];
      List<String> onlineList = dyn_onlineList.cast<String>().toList();
      setState(() {
        _playerList = onlineList;
      });
    }
    catch(error){
    print(error.toString());
    }
  }

  void _addListeners(){
      Query playerListQuery = _sessionDatabase.orderByKey().equalTo(
          SETTINGS.code);
      _childAddedSubscription = playerListQuery.onChildAdded.listen((event) {
        _updatePlayerList(event);
      });
      _childChangedSubscription =
          playerListQuery.onChildChanged.listen((event) {
            _updatePlayerList(event);
          });
      _childDeletedSubscription =
          playerListQuery.onChildRemoved.listen((event) {
            if(event.snapshot.key == SETTINGS.code){
              Navigator.pop(context);
            }
          });
  }

  Future<void> onJoin() async {

      // await for camera and mic permissions before pushing video page
    if(VIDEO)
      await _handleCameraAndMic();
    //update player current session
      try {
        _playerDatabase.child(PLAYER.username).update({
          'cS': SETTINGS.code,
        });
      }
      catch(error){

      }

    // show ad

      ads.showFullScreenAd(state: this);

  }

  Future<void> _handleCameraAndMic() async {
//    await PermissionHandler().requestPermissions(
//      [PermissionGroup.camera, PermissionGroup.microphone],
//    );
    await Permission.camera.request();
    await Permission.microphone.request();
  }

  Future<void> _joinGame() async{
    if(_pressedSubmit)
      return null;
    _pressedSubmit = true;
    if(CONNECTION) {

       _error = "";
       String code = _codeController.text;
       if (code == "" || code == null) {
         setState(() {
           _error = "Code cannot be blank";
           _pressedSubmit = false;
         });
         return;
       }
       try {
         DataSnapshot snapshot = await _sessionDatabase.child(code).once();
         if (snapshot.value == null) {
           setState(() {
             _pressedSubmit = false;
             _error = "Code does not exist";
           });
           return;
         }
         List<dynamic> dynPlayerList = snapshot.value['pL'];
         List<String> playerList = dynPlayerList.cast<String>().toList();
         bool alreadyIn = false;
         if (snapshot.value['st'] == "started" ||
             snapshot.value['st'] == "locker") {
           if (!playerList.contains(PLAYER.username)) {
             setState(() {
               _pressedSubmit = false;
               _error = "Game has already been started";
             });
             return;
           }
           else {
             alreadyIn = true;
           }
         }
         SETTINGS.more = snapshot.value['m'];
         if (!SETTINGS.more && !alreadyIn) {
           if (playerList.length >= 15) {
             setState(() {
               _pressedSubmit = false;
               _error = "Game cannot have more than 15 people";
             });
             return;
           }
         }

         if (!alreadyIn) {
           COINS -= TICKET_PRICE * SETTINGS.numTickets;
           if(COINS<0)
             COINS = 0;
           SETTINGS.saveCoins();
         }
         VIDEO = snapshot.value['v'];
         MORE_AUDIO = snapshot.value['mA'] != null ? true : false;
         if (!alreadyIn) {
           _sessionDatabase.child(code).runTransaction((mutableData) async {
             List<dynamic> dynPlayerList = mutableData.value['pL'];
             List<String> playerList = dynPlayerList.cast<String>().toList();
             playerList.add(PLAYER.username);
             mutableData.value['pL'] = playerList;
             return mutableData;
           }).then((value) {
             SETTINGS.code = code;
             onJoin();
           });
         }
         else {
           SETTINGS.code = code;
           REPEAT = true;
           onJoin();
         }
       }
       catch (error) {
         _pressedSubmit = false;
       }

   }
  }

  Future<bool> _onBackPressed(){
    if(HOST) {
      return showDialog(
        context: context,
        builder: (context) =>
        new AlertDialog(
          title: new Text('Are you sure?'),
          content: new Text(
              'Do you want to go back to home screen? Current game session will be deleted'),
          actions: <Widget>[
            new RaisedButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("NO"),
            ),
            SizedBox(height: 16),
            new RaisedButton(
              onPressed: () {
                Navigator.of(context).pop(true);
                AT_HOME = true;
                _deleteSession();
              },
              child: Text("YES"),
            ),
          ],
        ),
      ) ??
          false;
    }
    AT_HOME = true;
    Navigator.of(context).pop(true);
    return Future.value(false);
  }

  Future<bool> _showAudioDialog(){
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text('Game With Audio?'),
        content: new Text(
            'Do you want audio enabled for all users in the game?'),
        actions: <Widget>[
          new RaisedButton(
            onPressed: (){
              MORE_AUDIO = false;
              Navigator.of(context).pop(false);
            },
            elevation: 7.0,
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new RaisedButton(
            onPressed: (){
              MORE_AUDIO = true;
              try{
                _sessionDatabase.child(SETTINGS.code).update({
                  'mA': true
                });
              }
              catch(error){

              }
              Navigator.of(context).pop(false);
            },
            elevation: 8.0,
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;

  }


  Future<bool> _showGeneratedCode(){
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text('Generated Code'),
        content: ResizableText(context, 9, SETTINGS.code, color: Colors.greenAccent),
        actions: <Widget>[
          new FlatButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text("CANCEL")
          ),
          SizedBox(height: 16),
          new RaisedButton(
            elevation: 8.0,
              onPressed: () {
                Share.text('Generated Housie Number', "Housie Code: " + SETTINGS.code + "\nTo download the app, use the following link:\nhttps://www.google.com/url?q=https://play.google.com/store/apps/details?id%3Dcom.trype.housie&sa=D&source=hangouts&ust=1590030520397000&usg=AFQjCNG3k8R1Ln42YjYGJhOHEtDTMkE_sQ", 'text/plain');
                Navigator.of(context).pop(false);
              },
            child: Text("SHARE"),
          ),
        ],
      ),
    ) ??
        false;

  }

  Future<String> _generateCode() async{
    Random rand = new Random();
    String code = (rand.nextDouble() * 10000000000).floor().toString();
    DataSnapshot snapshot = await _sessionDatabase.orderByKey().equalTo(code).once();
    if(!(snapshot.value == null))
      code = await _generateCode();
    return code;
  }

  Future<void> _startGameSession(bool more) async{
    VIDEO = _videoButtonsSelected[0];
    _pressed = true;
    SETTINGS.more = more;
    try{
      String code = await _generateCode();
      SETTINGS.code = code;
      SETTINGS.playerList.add(PLAYER.username);
      await _sessionDatabase.child(code).set(SETTINGS.toJson());

      _addListeners();
      setState(() {
        HOST_NAME = PLAYER.username;
        HOST = true;
      });
    }
    catch(error){
      _pressed = false;
    }
  }

  Widget _toggleButtons(List<String> buttonList, List<bool> isSelected, int divisor, {double padding = 10.0}){
    int i=-1;
    return ToggleButtons(
      children: buttonList.map((buttonText) {
        i++;
        return ButtonContainer(isSelected, ResizableText(context, divisor, buttonText), i, padding: padding);
      }).toList(),
      isSelected: isSelected,
      disabledColor: Colors.grey,
      onPressed: (index) {
        print(VIDEO);
//        if(_startNewGame && index == 1)
//          return;
        setState(() {
          if (isSelected[index] == false) {
            for (int i = 0; i < isSelected.length; i++) {
              if (i == index)
                continue;
              isSelected[i] = false;
            }
            isSelected[index] = true;
          }
        });
      },
      borderWidth: null,
      renderBorder: false,
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
    );
  }

  Widget _gameButtons(){
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(0, 48, 0, 10),
      child: Container(
        child:  _toggleButtons(_gameButtonList, _gameButtonsSelected, 7),
      ),
    );

  }

  Widget _videoButtons(){
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.fromLTRB(0, 20, 0, 10),
      child: Container(
        child:  _toggleButtons(_videoButtonList, _videoButtonsSelected, 7),
      ),
    );
  }

  Widget _hostJoinAlert(){
    return AlertDialog(
      title: new Text('Join Game'),
      content: new Text(
          'You will not be able to add more players after joining the game'),
      actions: <Widget>[
        FlatButton(
          child: Text("Cancel"),
          onPressed: () {
            setState(() {
              _showHostAlert = false;
            });
          },
        ),
        SizedBox(height: 16),
        new RaisedButton(
          elevation: 8.0,
          child: Text("Join"),
          onPressed: (){
            List<int> numList = ListGenerator.housieNumberGenerator();
            try {
              _sessionDatabase.child(SETTINGS.code).update({
                'nL': numList,
                'st': 'locker',
              }).then((value) => onJoin());
            }
            catch(error){

            }
          },
        ),
      ],
    );
  }

  Widget _startNewGameButton(){
    return Container(
      alignment: Alignment.center,
      child: ResizableButton(context, 15, "START NEW GAME WITH LESS THAN 15 PEOPLE", () {
        if(!CONNECTION)
          return null;
        if(_pressed)
          return null;
        _startGameSession(false);
      }),
    );
  }

  Widget _startNewGameWithMoreButton(){
    return Container(
      alignment: Alignment.center,
      child: ResizableButton(context, _videoButtonsSelected[0] ? 15 : 10,_videoButtonsSelected[0] ? "START NEW GAME WITH MORE THAN 15 PEOPLE" : "START NEW GAME", () {
        if(!CONNECTION)
          return null;
        if(_pressed)
          return null;
        _startGameSession(true).then((value) {
          if(_videoButtonsSelected[0])
          _showAudioDialog();
        });
      }),
    );
  }

  Widget _showPlayerList(){
    if(_playerList.length>0){
      return ListView.builder(
          itemCount: _playerList.length,
          itemBuilder: (context, index){
            return Center(
              child: ResizableText(context, 10, _playerList[index]),
            );
          }
      );
    }
    else{
      return Center(child: Text("Welcome. Your list is empty",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 30.0),));
    }
  }

  Widget _chooseGame(){  //Choose start new game or join game
    return HOST ? _hostView() : ListView(
      shrinkWrap: true,
      children: <Widget>[
        Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _gameButtons(),
            Divider(thickness: 2.0,),
            _gameButtonsSelected[0] ? _videoButtons() : Container(height: 0.0,),
            _gameButtonsSelected[0] ? Divider(thickness: 2.0,) : Container(height: 0.0,),
          ],
        ),
        SizedBox(height:30.0),
        _gameButtonsSelected[0] ? Container(
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              _videoButtonsSelected[0] ? _startNewGameButton() : Container(height: 0.0,),
              SizedBox(height: 20.0,),
              _startNewGameWithMoreButton(),
            ],
          ),
        ) : Container(height: 0.0,)
      ],
    );
  }

  Widget _joinGameView(){
    if(!HOST && _gameButtonsSelected[1]){
      return Center(
        child: ListView(
          shrinkWrap: true,
          children: <Widget>[
            Center(child: ResizableText(context, 15, "Current number of tickets: " + SETTINGS.numTickets.toString()),),
            Center(child: ResizableText(context, 15, "Ticket price: 100 coins per ticket"),),
            TextField(
              keyboardType: TextInputType.number,
              controller: _numController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(style: BorderStyle.solid),
                    borderRadius: BorderRadius.all(Radius.circular(12.0))
                ),
                labelStyle: TextStyle(
                  fontFamily: "Paint Stroke",
                  fontSize: MediaQuery
                      .of(context)
                      .size
                      .width / 15,
                ),
                labelText: "Number of tickets",
              ),
            ),
            _numError == "" ? Container(height: 0.0,): ResizableText(context, 17, _numError, color: Colors.red),
            Center(child: RaisedButton(
              elevation: 8.0,
              onPressed: (){
                _numError = "";
                int n = int.parse(_numController.text);
                if(n < 1 || n > 5){
                  setState(() {
                    _numError = "Number of tickets cannot be less than 1 or greater than 5";
                  });
                  return;
                }
                if(n*100 > COINS){
                  setState(() {
                    _numError = "You do not have enough coins to buy $n tickets";
                  });
                  return;
                }
                setState(() {
                  SETTINGS.numTickets = n;
                });
              },
              child: Text("SET NUMBER OF TICKETS"),
              ),
            ),
            SizedBox(height: 20.0,),
            TextField(

              controller: _codeController,
              decoration: InputDecoration(
                border: OutlineInputBorder(
                    borderSide: BorderSide(style: BorderStyle.solid),
                    borderRadius: BorderRadius.all(Radius.circular(12.0))
                ),
                labelStyle: TextStyle(
                  fontFamily: "Paint Stroke",
                  fontSize: MediaQuery
                      .of(context)
                      .size
                      .width / 15,
                ),
                labelText: "Code",
              ),
            ),
            _error == "" ? Container(height: 0.0,) : ResizableText(context, 11, _error, color: Colors.red),
            Container(height: 40.0,),
            ResizableButton(context, 8, "JOIN", _joinGame)
          ],
        )
      );
    }
    return Container(height: 0.0,);
  }

  Widget _hostView(){
    return Column(
      children: <Widget>[
    Container(
    alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ResizableText(context, 8, "PLAYER LIST"),
          Divider(thickness: 3.0,),
          Container(
            alignment: Alignment.topCenter,
            height: MediaQuery.of(context).size.height/2.5,
            child: _showPlayerList(),
          ),
          Divider(thickness: 2.0,)
        ],
      ),
    ),
        Container(
          padding: EdgeInsets.fromLTRB(0, 30.0, 0, 20.0),
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              Center(child: _enterButton(),),
              SizedBox(height: 30.0,),
              ResizableButton(context, 8, "GENERATED CODE", (){
                _showGeneratedCode();
              }),
              SizedBox(height: 30.0,),
              ResizableButton(context, 8, "GAME SETTINGS", (){
                return _showHostAlert ? null : Navigator.push(context, MaterialPageRoute(
                  builder: (BuildContext context) => Settings()
                ));
              }),
            ],
          ),
        )
      ],
    );
  }

  Widget _enterButton(){
    return AnimatedOpacity(
        opacity: _isShowing ? 1.0 : 0.0,
        duration: Duration(milliseconds: 250),
        child: GestureDetector(
          onTap: (){
            if(!CONNECTION)
              return;
            setState(() {
              _showHostAlert = true;
            });
          },
          child:  ResizableText(context, 7, "ENTER GAME", fontFamily: "Bubbly"),
        ),
      );
  }

  @override
  void initState(){
    super.initState();
    SETTINGS.reset();
    AT_SESSION = true;
    _everySecond = Timer.periodic(Duration(milliseconds: 1000), (timer) {
      if(AT_SESSION) {
        setState(() {
          _isShowing = !_isShowing;
        });
      }
    });

  }
  @override
  void dispose(){
    AT_SESSION = false;
    if(HOST){
      try {
        _childAddedSubscription.cancel();
        _childChangedSubscription.cancel();
        _childDeletedSubscription.cancel();
      }
      catch(error){

      }
    }
    _everySecond.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        body: Stack(
          children: <Widget>[
            ListView(
              children: <Widget>[
                _chooseGame(),
                _joinGameView(),
              ],
            ),
            _showHostAlert ? _hostJoinAlert() : Container(height: 0.0,),
            ConnectionWidget(),
          ],
        ),
      ),
    );
  }
}