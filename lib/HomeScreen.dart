import 'dart:async';
import 'dart:ui';

import 'package:ads/ads.dart';
import 'package:esys_flutter_share/esys_flutter_share.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:housie/common_widgets.dart';
import 'package:housie/instructions.dart';
import 'package:housie/main.dart';
import 'package:housie/player.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:housie/ticket.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'authentication.dart';

//9:40 pm 13/05/2020
//TODO remove appbar if not necessary
//TODO check current session
//TODO delete sharedpreference file if user has been deleted from database
//First page of app. Contains heading, ticket and play button only
Ads ads;
bool showAd = false;

class HomeScreen extends StatefulWidget{
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>{
  Auth _auth = new Auth();
  Timer _everySecond; //Makes play button appear and disappear every 1 second
  bool _isShowing = true;//Value changes every 1 second to make play button disappear
  bool _newUser = false;
  bool _playPressed = false;
  TextEditingController _usernameController = new TextEditingController();
  String _error = "";
  final  _validCharacters = RegExp(r'^[a-zA-Z0-9_]+$'); //Allowed username characters
  DatabaseReference _playerDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e-71bf5.firebaseio.com/").reference().child("players");
  DatabaseReference _sessionDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e.firebaseio.com/").reference().child("sessions");
  static const String DATABASE_ERROR = "Cannot connect with database";
  bool pressed = false;





  void _openInstructionsDialog() {
    Navigator.of(context).push(new MaterialPageRoute<Null>(
        builder: (BuildContext context) {
          return new InstructionsPage();
        },
        fullscreenDialog: true
    ));
  }

  Future<bool> _checkIfUserExists(String username) async{
    try{
      DataSnapshot snapshot = await _playerDatabase.orderByKey().equalTo(username).once();
      if(snapshot.value == null){
        return false;
      }
      return true;
    }
    catch(error){
      pressed = false;
      _error = DATABASE_ERROR;
      return false;
    }
  }

  Future<void> _addUserToDatabase(String username) async{
    try{
      PLAYER = new Player("", username);
      await _playerDatabase.child(username).set(PLAYER.toJson());
      _setUsername(username);
      _retrieveCoins();
      setState(() {
        _newUser = false;
      });
    }
    catch(error){
      pressed = false;
      print(error.toString());
      _error = DATABASE_ERROR;
    }
  }

  Future<bool> _onBackPressed() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('Do you want to exit an App'),
        actions: <Widget>[
          new RaisedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new RaisedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<bool> _showReturnDialog() {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('You were in a game'),
        content: new Text('Do you want to resume previous game?'),
        actions: <Widget>[
          new RaisedButton(
            onPressed: (){
              try {
                _playerDatabase.child(PLAYER.username).update({
                  'cS': ""
                });
                SETTINGS.code = "";
              }
              catch(error){

              }
              Navigator.of(context).pop(false);
            },
            elevation: 8.0,
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new RaisedButton(
            onPressed: () async{
              Navigator.of(context).pop(false);
              try {
                DataSnapshot snapshot = await _sessionDatabase.child(
                    SETTINGS.code).once();
                SETTINGS.more = snapshot.value['m'];
                VIDEO = snapshot.value['v'];
                AT_HOME = false;
                REPEAT = true;
                onJoin();

              }
              catch(error){

              }
            },
            elevation: 8.0,
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Future<void> onJoin() async {

    // await for camera and mic permissions before pushing video page
    if(VIDEO)
      await _handleCameraAndMic();

    Navigator.pushNamed(context, '/callPage');
  }

  Future<void> _handleCameraAndMic() async {
//    await PermissionHandler().requestPermissions(
//      [PermissionGroup.camera, PermissionGroup.microphone],
//    );
  await Permission.camera.request();
  await Permission.microphone.request();
  }

  Future<String> _getUsername() async {
    String key = 'username';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }

  Future<List<String>> _getPrizeNames() async{
    String key = 'prizeNames';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<List<String>> _getPrizeDescriptions() async{
    String key = 'prizeDescriptions';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<List<String>> _getPrizeValues() async{
    String key = 'prizeValues';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key);
  }

  Future<void> _setUsername(String username) async{
    String key = 'username';
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString(key, username);
  }

  Future<int> _getVisited() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    int n = prefs.getInt("visited");
    if(n==null)
      n=0;
    prefs.setInt("visited", n+1);
    return n;
  }

  void _retrievePrizes() async{
    List<String> pNames = await _getPrizeNames();
    if(pNames == null) {
      prizeList.forEach((element) {
        previousPrizes.add(new Prize(element.name,element.description,element.custom,element.value));
      });
      return;
    }
    List<String> pDescs = await _getPrizeDescriptions();
    List<String> pVals = await _getPrizeValues();
    for(int i=0;i<pNames.length;i++){

      previousPrizes.add(new Prize(pNames[i], pDescs[i], true,int.parse(pVals[i])));
    }
  }

  void _retrieveVisited() async{
    int n = await _getVisited();
    print(n);
    if(n>2)
      showAd = true;
    else
      showAd = false;
  }

  void _checkIfInGame() async{
    DataSnapshot snapshot = await _playerDatabase.child(PLAYER.username).once();
    //Current session
    String cS = snapshot.value['cS'];
    if(cS == "" || cS == null)
      return;
    DataSnapshot session = await _sessionDatabase.child(cS).once();
    if(session.value == null){
      _playerDatabase.child(PLAYER.username).update({
        'cS': ""
      });
      return;
    }
    SETTINGS.code = cS;
    _showReturnDialog();
  }

  void _retrieveUsername() async{
    String username = await _getUsername();
    if(username == null){

        setState(() {
          _newUser = true;
      });
    }
    else{
      PLAYER.username = username;
      setState(() {
        _newUser = false;
      });
      _retrieveCoins();
      _checkIfInGame();
    }
  }

  void _retrieveCoins() async{
    int coins;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      coins = prefs.getInt('coins');
      if (coins == null) {
        try {
          DataSnapshot snapshot = await _playerDatabase.child(PLAYER.username)
              .once();
          coins = snapshot.value['c'];
        }
        catch (error) {

        }
      }
    }
    catch(error){

    }
    if (coins == null) {
      coins = 500;
      _playerDatabase.child(PLAYER.username).update({'c': 500});
    }
    setState(() {
      COINS = coins;
    });
  }


  Widget _newUserScreen() {
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
      child: Container(
        alignment: Alignment.center,
        child: Card(
          elevation: 8.0,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              SizedBox(height: 20.0,),
              Center(child:ResizableText(context, 10, "New User?")),
              Center(child:ResizableText(context, 10, "Enter a username")),
              TextField(

                controller: _usernameController,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                      borderSide: BorderSide(style: BorderStyle.solid),
                      borderRadius: BorderRadius.all(Radius.circular(12.0))
                  ),
                  labelStyle:TextStyle(
                    fontFamily: "Paint Stroke",
                    fontSize: MediaQuery.of(context).size.width/15,
                  ),
                  labelText: "Username",
                ),
              ),
              _error != "" ?  ResizableText(context, 15, _error, color: Colors.red) : Container(height: 0.0,),
              RaisedButton(
                elevation: 8.0,
                color: Colors.black54,
                textColor: Colors.white,
                child: Text("SUBMIT"),
                onPressed: (){
                  if(pressed)
                    return null;
                  pressed = true;
                  String username = _usernameController.text.trim();
                  _error = "";
                  if(username == "" || username == null){ //Check if username is blank
                    setState(() {
                      pressed=false;
                      _error = "Username cannot be blank";
                    });
                    return;
                  }
                  else if(!CONNECTION){
                    setState(() {
                      _error = "No internet connection";
                    });
                    pressed = false;
                    return;
                  }
                  else if(!_validCharacters.hasMatch(username)){
                    setState(() {
                      _error = "Username can only have '_' as special characters";
                    });
                    pressed = false;
                    return;
                  }
                  else if(username.length > 10){
                    setState(() {
                      _error = "Username cannot be more than 10 characters";
                    });
                    pressed = false;
                    return;
                  }
                  else {
                    try {
                      _checkIfUserExists(username).then((exists) {
                        if (exists)
                          setState(() {
                            _error = "Username already exists";
                            pressed = false;
                          });
                        else {
                          _addUserToDatabase(username);
                        }
                      });
                    }
                    catch(error){
                      pressed = false;
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
  //Housie heading
  Widget _heading(){
    return Container(
      alignment: Alignment.topCenter,
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: ResizableText(context, 4, "HOUSIE"),
    );
  }
  //Home screen ticket
  Widget _ticket(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 11, "TAP THE LETTERS"),),
        Ticket(gridState: HOMEGRID, ogGridState: OG_HOMEGRID, homePage: true,),
        ResizableText(context, 12, "You have " + COINS.toString() + " coins"),

      ],
    );
  }

  Widget _background(){
    return Container(
      color: Color.fromARGB(255,198,255,245),
      child: null,
    );
  }

  Widget _instructionsButton(){
    return ResizableButton(context, 11, "How To Play?", (){
      _openInstructionsDialog();
    });
  }

  Widget _playButton(){
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: AnimatedOpacity(
      opacity: _isShowing ? 1.0 : 0.0,
      duration: Duration(milliseconds: 250),
      child: GestureDetector(
        onTap: (){
          if(!CONNECTION)
            return null;
          if(_newUser)
            return null;
          if(COINS < TICKET_PRICE) {
          _playPressed = true;
            ads.showFullScreenAd(state: this);
            return;
          }
          AT_HOME = false;
          Navigator.pushNamed(context, '/gameSession');
          },
        child:  Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ResizableText(context, 4, "PLAY", fontFamily: "Bubbly"),
//            ResizableText(context,12,"TICKET PRICE: " + TICKET_PRICE.toString() + " COINS")
          Text("TICKET PRICE: " + TICKET_PRICE.toString() + " COINS"),
          ],
        ),
      ),
    ),
    );
  }

  @override
  void initState(){
    super.initState();
    SETTINGS.reset();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    _everySecond = Timer.periodic(Duration(milliseconds: 1000), (timer) { setState(() {
      _isShowing = !_isShowing;
      });
    });
    ads = Ads(appId);
    ads.setVideoAd(

      adUnitId: videoUnitId,

      keywords: ['interactive', 'gaming', 'cards'],

      childDirected: true,

      testDevices: ['8BF16EAFF8541941ED9531BB1301D829'],

    );

    ads.setFullScreenAd(

        adUnitId: screenUnitId,

        keywords: ['interactive', 'gaming', 'cards'],

        childDirected: true,

        testDevices: ['8BF16EAFF8541941ED9531BB1301D829'],

        listener: (MobileAdEvent event) {

          if (event == MobileAdEvent.opened) {

            print("An ad has opened up.");

          }

        });

    ads.screenListener = (MobileAdEvent event) {

      switch (event) {

        case MobileAdEvent.loaded:


          break;

        case MobileAdEvent.failedToLoad:

          if(AT_SESSION){
            Navigator.popAndPushNamed(context, '/callPage');
          }

          else if(AT_HOME &&  _playPressed && CONNECTION){
            _playPressed = false;
            AT_HOME = false;

              COINS += REWARD;
              SETTINGS.saveCoins();

            Navigator.pushNamed(context, '/gameSession');
          }

          break;

        case MobileAdEvent.clicked:

          print("The opened ad was clicked on.");

          break;

        case MobileAdEvent.impression:

          print("The user is still looking at the ad. A new ad came up.");

          break;

        case MobileAdEvent.opened:

          print("The Ad is now open.");

          break;

        case MobileAdEvent.leftApplication:

          print("You've left the app after clicking the Ad.");

          break;

        case MobileAdEvent.closed:

          if(AT_SESSION){
            Navigator.popAndPushNamed(context, '/callPage');
          }

          else if(AT_HOME &&  _playPressed){
            _playPressed = false;
            AT_HOME = false;

              COINS += REWARD;
              SETTINGS.saveCoins();

            Navigator.pushNamed(context, '/gameSession');
          }

          break;

        default:

          print("There's a 'new' MobileAdEvent?!");

      }

    };

    ads.videoListener =

        (RewardedVideoAdEvent event, {String rewardType, int rewardAmount}) {

      switch (event) {

        case RewardedVideoAdEvent.loaded:

          print("An ad has loaded successfully in memory.");

          break;

        case RewardedVideoAdEvent.failedToLoad:


          break;

        case RewardedVideoAdEvent.opened:

          print("The ad is now open.");

          break;

        case RewardedVideoAdEvent.leftApplication:

          print("You've left the app after clicking the Ad.");

          break;

        case RewardedVideoAdEvent.closed:



          break;

        case RewardedVideoAdEvent.rewarded:
          if(AT_HOME){
            COINS += REWARD;
            SETTINGS.saveCoins();
          }
          break;

        case RewardedVideoAdEvent.started:

          print("You've just started playing the Video ad.");

          break;

        case RewardedVideoAdEvent.completed:

          print("You've just finished playing the Video ad.");

          break;

        default:

          print("There's a 'new' RewardedVideoAdEvent?!");

      }

    };




    _retrieveUsername();
    _retrievePrizes();
    _retrieveVisited();
  }

  @override
  void dispose(){
    _everySecond.cancel();
    ads.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
//    temp();

    return WillPopScope(
      onWillPop: _onBackPressed,
      child: Scaffold(
        key: scaffoldKey,
//        appBar: _appBar(scaffoldKey.currentState),
        //TODO add navigation drawer
        body: Stack(
          children: <Widget>[
            _background(),
            ListView(
              shrinkWrap: true,
              children: <Widget>[
                _heading(),
                _ticket(),
                SizedBox(height: 30.0,),
                _playButton(),
                SizedBox(height: 20.0,),
                _instructionsButton(),
                Divider(thickness: 4.0,color: Colors.black,),

                SizedBox(height: 30.0,),
                Center(
                  child: RaisedButton(
                    elevation: 8.0,
                    onPressed: (){
                      ads.showVideoAd(state: this);
                    },
                    child: Text("Watch an ad to earn more coins"),
                  ),
                ),
              ],
            ),


            _newUser ? _newUserScreen() : Container(height: 0.0,),
            ConnectionWidget(),
          ],
        ),
      ),
    );
  }
}