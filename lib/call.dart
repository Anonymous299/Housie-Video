import 'dart:async';
import 'dart:collection';
import 'dart:ui';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:firebase_admob/firebase_admob.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:housie/HomeScreen.dart';
import 'package:housie/board.dart';
import 'package:housie/common_widgets.dart';
import 'package:housie/game_settings.dart';
import 'package:housie/lifecycle.dart';
import 'package:housie/list_generator.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:housie/settings.dart';
import 'package:housie/ticket.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock/wakelock.dart';

Timer automaticTimer;
bool isPaused = false;
bool hide = false;
bool muted = false;
//TODO Change channel name to a coded string
final String APP_ID = "23dccdde0f36471dad0fda6493518bdc";

class CallPage extends StatefulWidget {

  /// Creates a call page with given channel name.
  const CallPage({Key key}) : super(key: key);

  @override
  _CallPageState createState() => _CallPageState();
}

class _CallPageState extends State<CallPage> with TickerProviderStateMixin{
  static final _users = <AgoraUserInfo>[];
  static final _userNames = <String>[];
  static final _userState = <int>[];
  List<String> _muteList = <String>[];
  static final _userAudioState = <int>[];
  final _infoStrings = <String>[];
  List<Prize> _prizeList = [];

  int time;
  bool noGeneration = false;
  bool startedDisplayTimer = false;
  bool showNumber = false;
  bool showPrizes = true;
  bool switched = false;
  bool canChoose = true;
  bool displayBoard = false;
  bool showConfirmation = false;
  bool populated = false;
  bool ended = false;
  bool showWinners = false;
  bool displayingBoard = false;
  bool showMessage = false;
  bool factoring = false;
  bool host_muted = false;
  bool close_pressed = false;
  bool close = false;
  bool showMassConfirmation = false;
  int currentTicket=0;
  String _offlineMessage = "";


  DatabaseReference _sessionDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e.firebaseio.com/").reference().child("sessions"); //TODO add new database to firebase and update databaseURL accordingly
  StreamSubscription _childAddedSubscription;
  StreamSubscription _childChangedSubscription;
  StreamSubscription _childDeletedSubscription;
  Timer _delay;
  Timer _hideNumber;
  Timer _deleteClaims;

  Timer _deletionTimer;
  int host_index = -1;
  String _error = "";
  List<List<String>> _checkingTicket = [['','','','','','','','',''],
    ['','','','','','','','',''],
    ['','','','','','','','','']];
  List<List<String>> _checkingOgTicket = [['','','','','','','','',''],
    ['','','','','','','','',''],
    ['','','','','','','','','']];
  List<String> winners=[];
  List<AgoraUserInfo> leftUsers = [];
  List<Prize> _absolutePrizeList = [];


  @override
  void dispose() {
    Wakelock.disable();
    AT_CALL = false;
    AT_HOME = true;

    // clear users
    _userState.clear();
    _users.clear();
    // destroy sdk
    if(VIDEO) {
      AgoraRtcEngine.leaveChannel();
      AgoraRtcEngine.destroy();
    }
    //Dispose animation controller
    _childDeletedSubscription.cancel();
    _childChangedSubscription.cancel();
    _childAddedSubscription.cancel();
    if(HOST && AUTOMATIC && !isPaused) {
      try {
        automaticTimer.cancel();
      }
      catch(error){

      }
    }
    try {
      _delay.cancel();
    }
    catch(error){

    }
    try {
      _hideNumber.cancel();
    }
    catch(error){

    }
    try {
      _deleteClaims.cancel();
    }
    catch(error){

    }
    try {
      _deletionTimer.cancel();
    }
    catch(error){

    }

//
//    ;
    //Delete session
    if(showWinners || showPrizes)
      _closeShowPrize();
    if(displayBoard)
      _closeDisplayBoard();
   _deleteSession();
//    ads.hideBannerAd();
    if(!VIDEO || (SETTINGS.more && MORE_AUDIO))
      ads.closeBannerAd();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Wakelock.enable();
    isPaused = false;
    hide = false;
    muted = false;
    AT_CALL = true;
    populateSettings().then((value) {
      _addListeners();
    }).catchError((error){
      return error;
    });
    if(REPEAT){
      _getRepeatTickets();
    }
    if(VIDEO)
      initialize();
//    _addAnimation();

    _deletionTimer = Timer(new Duration(minutes: 85), (){
      setState(() {
        _error = "Session is going to be deleted in 5 minutes";
      });
    });

    if(!VIDEO || (SETTINGS.more && MORE_AUDIO))
      ads.showBannerAd(

        adUnitId: bannerUnitId,

        size: AdSize.banner,

        keywords: ['interactive', 'gaming', 'cards'],

        contentUrl: null,

        childDirected: true,

        testDevices: ['8BF16EAFF8541941ED9531BB1301D829'],

      );

  }

  void _getRepeatTickets() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    SETTINGS.numTickets = prefs.getInt('numTickets');
    List<String> expandedExpandedList = prefs.getStringList('tickets');
    List<String> expandedExpandedOgList = prefs.getStringList('ogTickets');
    print(expandedExpandedList);

    for(int i=0;i<SETTINGS.numTickets;i++){
      List<String> expandedList = expandedExpandedList.getRange(27*i, 27*(i+1)).toList();
      List<String> expandedOgList = expandedExpandedOgList.getRange(27*i, 27*(i+1)).toList();
      _populateTicketList(
          SETTINGS.ticketList, expandedList, false);
      _populateTicketList(
          SETTINGS.ogTicketList, expandedOgList, false);
      _addTicketToList();
    }
  }

  void _updateBoard(int whichNum){
    for(int i=0;i<=whichNum;i++){
      int num = SETTINGS.numList[i];
      num--;
      int row = (num/10).floor();
      int col = num%10;
      SETTINGS.boardNumList[row][col] = "*";
    }
  }



  void _resumeAutomaticTimer(){
    if(HOST && AUTOMATIC){
      print("autotimer ddjdd");
      automaticTimer =
          Timer.periodic(new Duration(seconds: DURATION + 4), (timer) {
              _incrementNumber();
          });
    }
  }

  void _incrementNumber() async{
   int tempNum = SETTINGS.whichNum + 1;
   if(tempNum >= 90)
     return;
   try {
     if(!CONNECTION)
       return;
     await _sessionDatabase.child(SETTINGS.code).update({
       'wN': tempNum
     });
     _delay = Timer(new Duration(seconds: 4), () {
       setState(() {
         noGeneration = false;
       });
     });
     setState(() {
       noGeneration = true;
     });
   }
   catch(error){

   }

  }

  void _updateSettings(Event event){
    DataSnapshot snapshot = event.snapshot;
    if(snapshot.key==null)
      Navigator.pop(context);
    bool started = snapshot.value['st'] == "started" ? true : false;
    if(started){
      if(snapshot.value['wN'] == -1){
        if(SETTINGS.tickets[0][0].isEmpty){
          for(int i=0;i<SETTINGS.numTickets;i++){
            SETTINGS.ticketList = ListGenerator.generateTicketList();
            SETTINGS.ogTicketList = ListGenerator.getOgList();
            _addTicketToList();
          }
          setState(() {});
        }
        if(HOST && AUTOMATIC && !isPaused && !ended && !displayingBoard)
          _resumeAutomaticTimer();
        showPrizes = false;
        SETTINGS.choose = snapshot.value['c'] ?? true;

        List<dynamic> dynPlayerList = snapshot.value['pL'];
        SETTINGS.playerList = dynPlayerList.cast<String>().toList();
        List<dynamic> dynNumList = snapshot.value['nL'];
        SETTINGS.numList = dynNumList.cast<int>().toList();
        SETTINGS.whichNum = snapshot.value['wN'];
        SETTINGS.started = started;
//        print(SETTINGS.whichNum);
      }
      List<dynamic> dynStopList = snapshot.value['stop'];
      if(dynStopList == null || dynStopList.isEmpty){
        if(HOST && AUTOMATIC && !isPaused && SETTINGS.stop.isNotEmpty && !displayingBoard)
          _resumeAutomaticTimer();
        setState(() {
          factoring = false;
          showMassConfirmation = false;
          SETTINGS.stop = [];
        });
      }
      else{
        if(HOST && AUTOMATIC && !isPaused)
          automaticTimer.cancel();
        SETTINGS.stop = dynStopList.cast<String>().toList();
        if(!showNumber){
          setState(() {
          });
        }
      }
      if(SETTINGS.whichNum != snapshot.value['wN'])
        {

          SETTINGS.whichNum = snapshot.value['wN'];
          if(SETTINGS.whichNum == 89 && !ended){
            Timer(new Duration(seconds: 30), (){
              if(!AT_CALL || ended)
                return;
              ended = true;
              setState(() {
                _error = "Session will be deleted in 5 minutes";

                _handleEndgame();
              });
            });
            if(HOST){
              if(AUTOMATIC) {
                automaticTimer.cancel();
              }
            }
          }

          _updateBoard(SETTINGS.whichNum);
          _hideNumber = Timer(new Duration(seconds: 4), (){
            setState(() {
              showNumber = false;
              if((SETTINGS.whichNum + 1)%20 == 0) {
                displayBoard = true;
                displayingBoard=true;
                if(HOST && AUTOMATIC && !isPaused)
                automaticTimer.cancel();
              }
            });
          });
          setState(() {
            showNumber = true;
          });

        }
      if(VIDEO){
        List<dynamic> dynMuteList = snapshot.value['mL'];
          List<String> muteList = dynMuteList == null ? [] : dynMuteList.cast<String>().toList();
          _muteList.forEach((element) {
            if(!muteList.any((element2) => element2 == element)){
              print("jdhkjhdkjhdkhsdjk: $element");
              if(element == PLAYER.username){
                setState(() {
                  host_muted = false;
                });
              }
              else {
                AgoraRtcEngine.muteRemoteAudioStream(_users
                    .firstWhere((element3) => element3.userAccount == element)
                    .uid, false);
              }
            }
          });
          muteList.forEach((element) {
            if(!_muteList.any((element2) => element == element2)){
              if(element == PLAYER.username){
                setState(() {
                  host_muted = true;
                });
              }
              else {
                AgoraRtcEngine.muteRemoteAudioStream(_users
                    .firstWhere((element3) => element3.userAccount == element)
                    .uid, true);
              }
            }
          });
          _muteList = muteList;
      }
      List<dynamic> dynPlayerList = snapshot.value['pL'];
      List<String> playerList = dynPlayerList.cast<String>().toList();

      if(!playerList.any((element) => element == PLAYER.username)){
        Navigator.pop(context);
      }
      SETTINGS.playerList = playerList;
    }
    else{
      List<dynamic> dynPlayerList = snapshot.value['pL'];
      SETTINGS.playerList = dynPlayerList.cast<String>().toList();
      List<dynamic> dynPrizeNames = snapshot.value['cu']['pN'];
      if(dynPrizeNames.length != _prizeList.length){
        int end = dynPrizeNames.length - _prizeList.length;
        int start = _prizeList.length;
        List<String> prizeNames = dynPrizeNames.cast<String>().toList();
        List<dynamic> dynPrizeDesc = snapshot.value['cu']['pD'];
        List<String> prizeDesc = dynPrizeDesc.cast<String>().toList();
        List<dynamic> dynPrizeCustoms = snapshot.value['cu']['pC'];
        List<bool> prizeCustoms = dynPrizeCustoms.cast<bool>().toList();
        List<dynamic> dynPrizeValues = snapshot.value['cu']['pV'];
        List<int> prizeValues = dynPrizeValues.cast<int>().toList();
        for(int i=0;i<end;i++){
          _prizeList.add(new Prize(prizeNames[start+i], prizeDesc[start+i],prizeCustoms[start+i],prizeValues[start + i]));
          _absolutePrizeList.add(new Prize(prizeNames[start+i], prizeDesc[start+i],prizeCustoms[start+i],prizeValues[start + i]));
        }
        setState(() {
          showPrizes = true;
        });
      }
    }
    HOST_NAME = snapshot.value['h'];
    if(HOST_NAME == PLAYER.username && !HOST){
      setState(() {
        host_index = _users.indexWhere((element) => element.userAccount == PLAYER.username);
        HOST = true;
      });
    }

  }

  void _addListeners(){
    Query playerListQuery = _sessionDatabase.orderByKey().equalTo(
        SETTINGS.code);
    _childAddedSubscription = playerListQuery.onChildAdded.listen((event) {
      _updateSettings(event);
    });
    _childChangedSubscription =
        playerListQuery.onChildChanged.listen((event) {
          _updateSettings(event);
        });
    _childDeletedSubscription = _sessionDatabase.onChildRemoved.listen((event) {
      if(event.snapshot.key == SETTINGS.code)
        if(AT_CALL)
          Navigator.pop(context);
    });
  }

  void _populateTicketList(List<List<String>> ticketList, List<String> list, bool board){

    int length = !board ? 3 : 9;
    int breadth = !board ? 9 : 10;
    for(int i=0;i<length*breadth;i++){
      int row = (i/breadth).floor();
      int col = i%breadth;
      ticketList[row][col] = list[i];
    }
  }

  Future<void> populateSettings() async{

    if(REPEAT) {

      SharedPreferences prefs = await SharedPreferences.getInstance();

      _populateTicketList(
          SETTINGS.boardNumList, prefs.getStringList("boardList"), true);
      _populateTicketList(
          SETTINGS.ogBoardNumList, prefs.getStringList("ogBoardList"), true);

      HOST = prefs.getBool("host");
      AUTOMATIC = prefs.getBool("automatic");
      if (HOST && AUTOMATIC)
        _resumeAutomaticTimer();
      DURATION = prefs.getInt("duration");
      HOST_PLAY = prefs.getBool("host_play");
      VIDEO = prefs.getBool("video");
      MORE_AUDIO = prefs.getBool("audio");
      try {
        DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code)
            .once();

        HOST_NAME = snapshot.value['h'];
        SETTINGS.choose = snapshot.value['c'] ?? true;
        List<dynamic> dynPlayerList = snapshot.value['pL'];
        SETTINGS.playerList = dynPlayerList.cast<String>().toList();
        List<dynamic> dynNumList = snapshot.value['nL'];
        SETTINGS.numList = dynNumList.cast<int>().toList();
        SETTINGS.whichNum = snapshot.value['wN'];
        SETTINGS.started = snapshot.value['st'] == "started" ? true : false;
        List<dynamic> dynPrizeList = snapshot.value['wL'];
        if (dynPrizeList != null) {
          List<String> localPrizeList = dynPrizeList.cast<String>().toList();
          for (int i = 0; i < localPrizeList.length; i++) {
            String prize = localPrizeList[i].split(":")[1];
            _prizeList.removeWhere((element) => element.name == prize);
          }
        }
        List<dynamic> dynPrizeNames = snapshot.value['cu']['pN'];
        if (dynPrizeNames.length != _prizeList.length) {
          int end = dynPrizeNames.length - _prizeList.length;
          int start = _prizeList.length;
          List<String> prizeNames = dynPrizeNames.cast<String>().toList();
          List<dynamic> dynPrizeDesc = snapshot.value['cu']['pD'];
          List<String> prizeDesc = dynPrizeDesc.cast<String>().toList();
          List<dynamic> dynPrizeCustoms = snapshot.value['cu']['pC'];
          List<bool> prizeCustoms = dynPrizeCustoms.cast<bool>().toList();
          List<dynamic> dynPrizeValues = snapshot.value['cu']['pV'];
          List<int> prizeValues = dynPrizeValues.cast<int>().toList();
          for (int i = 0; i < end; i++) {
            _prizeList.add(new Prize(
                prizeNames[start + i], prizeDesc[start + i],
                prizeCustoms[start + i], prizeValues[start + i]));
          }
          List<dynamic> dynMuteList = snapshot.value['mL'];
          if (dynMuteList != null) {
            _muteList = dynMuteList.cast<String>().toList();
          }

          setState(() {

          });
        }
      }
      catch(error){

      }
    }
    else
      {
        try {
          DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code)
              .once();
          HOST_NAME = snapshot.value['h'];
          SETTINGS.choose = snapshot.value['c'] ?? true;
        }
        catch(error){

        }
          for(int i=0;i<SETTINGS.numTickets;i++){
            SETTINGS.ticketList = ListGenerator.generateTicketList();
            SETTINGS.ogTicketList = ListGenerator.getOgList();
            _addTicketToList();
          }


          SETTINGS.boardNumList = ListGenerator.fillBoardNums();
          SETTINGS.ogBoardNumList = ListGenerator.getOgBoardNums();

        SETTINGS.save();
      }
    populated = true;
  }

  void _addTicketToList(){
    int last = SETTINGS.tickets.length;
    SETTINGS.tickets.add([['','','','','','','','',''],
      ['','','','','','','','',''],
      ['','','','','','','','','']]);
    SETTINGS.ogTickets.add([['','','','','','','','',''],
      ['','','','','','','','',''],
      ['','','','','','','','','']]);
    _populateLast(last);
  }

  void _populateLast(int last){
    for(int i=0;i<3;i++){
      for(int j=0;j<9;j++){
        SETTINGS.tickets[last][i][j] = SETTINGS.ticketList[i][j];
        SETTINGS.ogTickets[last][i][j] = SETTINGS.ogTicketList[i][j];
      }
    }
  }

  Future<void> _deleteSession() async{
    if(HOST) {
      HOST = false;
      if(!ended)
        try {
          _sessionDatabase.child(SETTINGS.code).remove();
        }
      catch(error){

      }
    }
    if(!HOST) {
      try {
        DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code).once();
        if(snapshot.value == null)
          return;
        _sessionDatabase.child(SETTINGS.code).runTransaction((
            mutableData) async {
          List<dynamic> dynPlayerList = mutableData.value['pL'];
          List<String> playerList = dynPlayerList.cast<String>().toList();
          playerList.remove(PLAYER.username);
          mutableData.value['pL'] = playerList;
          return mutableData;
        });
      }

      catch (error) {

      }
    }
    await SETTINGS.reset();
    await SETTINGS.save();
  }

  Future<void> initialize() async {
    if (APP_ID.isEmpty) {
      setState(() {
        _infoStrings.add(
          'APP_ID missing, please provide your APP_ID in settings.dart',
        );
        _infoStrings.add('Agora Engine is not starting');
      });
      return;
    }

    await _initAgoraRtcEngine();
    _addAgoraEventHandlers();
    await AgoraRtcEngine.enableWebSdkInteroperability(true);
    await AgoraRtcEngine.setParameters(
        '''{\"che.video.lowBitRateStreamParameter\":{\"width\":320,\"height\":180,\"frameRate\":15,\"bitRate\":140}}''');
//    await AgoraRtcEngine.joinChannel(null, SETTINGS.code, null, 0);
    await AgoraRtcEngine.joinChannelByUserAccount({
        "userAccount": PLAYER.username,
        "token": null,
        "channelId": SETTINGS.code
      });
  }

  Future<bool> _onBackPressed(){
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text(
            'Do you want to go back to home screen? You will be removed from the current game'),
        actions: <Widget>[
          new RaisedButton(
            onPressed: () {
              close_pressed = false;
              return Navigator.of(context).pop(false);},
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new RaisedButton(
            onPressed: () {
              if(close_pressed)
                Navigator.of(context).pop(true);
              close_pressed = false;
              return Navigator.of(context).pop(true);
            },
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;

  }

  Future<bool> _showPrizeDescription(int index){
    String prizeName = _prizeList[index].name;
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text(_prizeList[index].name + " Description"),
        content: new Text(
          _prizeList[index].description + "\nValue: " + _prizeList[index].value.toString() + "%"
            ),
        actions: <Widget>[
          RaisedButton(
            elevation: 8.0,
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("OK"),
          ),
        ],
      ),
    ) ??
        false;

  }

  Future<void> _sendTicket(Prize p) async{
    List<String> expandedTicketList = [];
    List<String> expandedOgTicketList = [];
    for(int i=0;i<SETTINGS.tickets[currentTicket].length;i++){
      for(int j=0;j<SETTINGS.tickets[currentTicket][0].length;j++){
        expandedTicketList.add(SETTINGS.tickets[currentTicket][i][j]);
        expandedOgTicketList.add(SETTINGS.ogTickets[currentTicket][i][j]);
      }
    }
    try {
      _sessionDatabase.child(SETTINGS.code).child('ticket').child(p.name).child(
          PLAYER.username).set({
        'tL': expandedTicketList,
        'oTL': expandedOgTicketList,
      });
      _sessionDatabase.child(SETTINGS.code).runTransaction((mutableData) async {
        List<dynamic> dynStopList = mutableData.value['stop'];
        List<String> stopList = dynStopList == null ? [] : dynStopList.cast<
            String>().toList();
        String status = "claimed";
        String message = p.name + ":" + PLAYER.username + ":" + status;
        stopList.add(message);
        mutableData.value['stop'] = stopList;
        return mutableData;
      });
    }
    catch(error){

    }
  }

  bool _checkTicket(Prize p, int lastNumIndex) {
    String prize = p.name;
    if(!SETTINGS.started)
      return false;
    bool success;
    switch(prize){
      case 'FOUR CORNERS':
        success = fourCorners(lastNumIndex);
        break;
      case 'FAST 5':
        success = fast5(lastNumIndex);
        break;
      case 'FIRST ROW':
        success = row(lastNumIndex,1);
        break;
      case 'SECOND ROW':
        success = row(lastNumIndex,2);
        break;
      case 'THIRD ROW':
        success = row(lastNumIndex,3);
        break;
      case 'FULL HOUSE':
        success = fullHouse(lastNumIndex);
        break;
      default:
        success = false;
        break;
    }
//    success = true;
    try {
      _sessionDatabase.child(SETTINGS.code).runTransaction((mutableData) async {
        List<dynamic> dynStopList = mutableData.value['stop'];
        List<String> stopList = dynStopList == null ? [] : dynStopList.cast<
            String>().toList();
        String status = success ? "got" : "not got";
        String message = prize + ":" + PLAYER.username + ":" + status;
        stopList.add(message);
        mutableData.value['stop'] = stopList;
        return mutableData;
      });
    }
    catch(error){

    }
    return success;
  }

  bool fourCorners(int lastNumIndex){
    List<int> nums = [];
    List<int> numberList = SETTINGS.numList.getRange(0, lastNumIndex+1).toList();
    int firstCornerIndex = -1;
    int secondCornerIndex = -1;
    int thirdCornerIndex = -1;
    int fourthCornerIndex = -1;
    for(int i=0;i<9;i++){
      if(SETTINGS.ogTickets[currentTicket][0][i] != "") {
        if (firstCornerIndex == -1) {
          firstCornerIndex = i;
        }
        secondCornerIndex = i;
      }
      if(SETTINGS.ogTickets[currentTicket][2][i] != "") {
        if (thirdCornerIndex == -1) {
          thirdCornerIndex = i;
        }
        fourthCornerIndex = i;
      }
    }
    if(SETTINGS.tickets[currentTicket][0][firstCornerIndex] != "*" || SETTINGS.tickets[currentTicket][0][secondCornerIndex] != "*")
      return false;

    if(SETTINGS.tickets[currentTicket][2][thirdCornerIndex] != "*" || SETTINGS.tickets[currentTicket][2][fourthCornerIndex] != "*")
      return false;

    if( !numberList.contains(int.parse(SETTINGS.ogTickets[currentTicket][0][firstCornerIndex])) || !numberList.contains(int.parse(SETTINGS.ogTickets[currentTicket][0][secondCornerIndex])))
      return false;
    if( !numberList.contains(int.parse(SETTINGS.ogTickets[currentTicket][2][thirdCornerIndex])) || !numberList.contains(int.parse(SETTINGS.ogTickets[currentTicket][2][fourthCornerIndex])))
      return false;

    return true;
  }

  bool fast5(int lastNumIndex){
    List<int> nums = [];
    List<int> numberList = SETTINGS.numList.getRange(0, lastNumIndex+1).toList();
    for(int i=0;i<3;i++){
      for(int j=0;j<9;j++){
        if(SETTINGS.tickets[currentTicket][i][j] == '*'){
          nums.add(int.parse(SETTINGS.ogTickets[currentTicket][i][j]));
        }
      }
    }
    //Check if 5 completed
    if(nums.length < 5)
      return false;
    //Check if last number is included
    //Check if all numbers are include
    int n = 0;
    int index = 0;
    while(n!=5){
      if(index == nums.length)
        return false;
      if(numberList.contains(nums[index]))
        n++;
      index++;
    }
    return true;
  }

  bool row(int lastNumIndex, int rowNum){

    List<String> nums = SETTINGS.ogTickets[currentTicket][rowNum-1];
    List<String> rowData = SETTINGS.tickets[currentTicket][rowNum-1];

    List<int> numberList = SETTINGS.numList.getRange(0, lastNumIndex+1).toList();
    for(int i=0;i<5;i++){
      if(nums[i] == "")
        continue;
      if(rowData[i] != "*")
        return false;
      if(!numberList.contains(int.parse(nums[i])))
        return false;

    }
    return true;
  }

  bool fullHouse(int lastNumIndex){
    List<int> numberList = SETTINGS.numList.getRange(0, lastNumIndex+1).toList();

    for(int i=0;i<3;i++){
      for(int j=0;j<9;j++){
        if(SETTINGS.ogTickets[currentTicket][i][j] == "")
          continue;
        if(SETTINGS.tickets[currentTicket][i][j] != '*')
          return false;
        if(!numberList.contains(int.parse(SETTINGS.ogTickets[currentTicket][i][j])))
          return false;
      }
    }
    return true;
  }

  /// Create agora sdk instance and initialize
  Future<void> _initAgoraRtcEngine() async {
    await AgoraRtcEngine.create(APP_ID);
    if(!SETTINGS.more) {
      await AgoraRtcEngine.enableVideo();
    }
    else{
      if(MORE_AUDIO)
        return;
      await AgoraRtcEngine.setChannelProfile(ChannelProfile.LiveBroadcasting);
      if(HOST){
        await AgoraRtcEngine.setClientRole(ClientRole.Broadcaster);
      }
      else{
        await AgoraRtcEngine.setClientRole(ClientRole.Audience);
      }
      await AgoraRtcEngine.enableVideo();
    }
  }

  /// Add agora event handlers
  void _addAgoraEventHandlers() {
    AgoraRtcEngine.onError = (dynamic code) {
      setState(() {
        final info = 'onError: $code';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onJoinChannelSuccess = (
        String channel,
        int uid,
        int elapsed,
        ) {
      setState(() {
        final info = 'onJoinChannel: $channel, uid: $uid';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onLeaveChannel = () {
      setState(() {
        _infoStrings.add('onLeaveChannel');
        _userState.clear();
        _userAudioState.clear();
        _users.clear();
      });
    };


    AgoraRtcEngine.onUserOffline = (int uid, int reason) {
      setState(() {
        final info = 'userOffline: $uid';
        _infoStrings.add(info);
        if(SETTINGS.more && MORE_AUDIO)
          return;
          int index = _users.indexWhere((element) => element.uid == uid);
          AgoraUserInfo user = _users.where((element) => element.uid == uid)
              .elementAt(0);
          if (user.userAccount == HOST_NAME)
            host_index = -1;

          leftUsers.add(user);
          _users.remove(user);
          _userState.removeAt(index);
          _userAudioState.removeAt(index);

          setState(() {
            showMessage = true;
            _offlineMessage =
                "The user " + user.userAccount + " has gone offline";
          });

      });
    };

    AgoraRtcEngine.onFirstRemoteVideoFrame = (
        int uid,
        int width,
        int height,
        int elapsed,
        ) {
      setState(() {
        final info = 'firstRemoteVideo: $uid ${width}x $height';
        _infoStrings.add(info);
      });
    };

    AgoraRtcEngine.onRemoteVideoStateChanged = (
        int uid,
        int state,
        int reason,
        int elapsed,
    ) {
      setState(() {
        int index = _users.indexWhere((element) => element.uid == uid);
        if(index != -1)
          _userState[index] = state;
      });
    };

    AgoraRtcEngine.onRemoteAudioStateChanged = (
      int uid,
        int state,
        int reason,
        int elapsed
    ){
      setState(() {
        int index = _users.indexWhere((element) => element.uid == uid);
        if(index != -1)
          _userAudioState[index] = state;
      });
    };

    AgoraRtcEngine.onUserJoined = (
        int uid,
        int elapsed,
    ){
      if(SETTINGS.more && MORE_AUDIO)
        return;
      try {
        AgoraUserInfo user = leftUsers.firstWhere((element) =>
        element.uid == uid);

        if (user != null) {
          print("dksjdkslddsad");

            _users.add(user);

            _userState.add(2);
            _userAudioState.add(2);
            if(user.userAccount == HOST_NAME)
              host_index = _users.length-1;

        }
      }
      catch(error){
        print(error.toString());
      }
    };

    AgoraRtcEngine.onUpdatedUserInfo = (
        AgoraUserInfo userInfo,
        int uid,
    ) {
      if(SETTINGS.more && MORE_AUDIO)
        return;
      print("user joined");
      setState(() {


          _users.add(userInfo);

          _userState.add(2);
          _userAudioState.add(2);
          if(userInfo.userAccount == HOST_NAME)
            host_index = _users.length-1;

        AgoraRtcEngine.setupRemoteVideo(0, VideoRenderMode.Fit, uid);
      });
    };
  }



  /// Helper function to get list of native views
  List<Widget> _getRenderViews() {
    if(SETTINGS.more && MORE_AUDIO)
      return [];
    final List<Widget> list =  SETTINGS.more && !HOST ? host_index != -1 ? [_userState[host_index] != 0 ? AgoraRenderWidget(_users[host_index].uid) : Container(color: Colors.black,),] : []
        : host_index != -1 ? [
      !hide ? AgoraRenderWidget(0, local: true, preview: true) : Container(color: Colors.black,),
      _userState[host_index] != 0 ? AgoraRenderWidget(_users[host_index].uid) : Container(color: Colors.black,),

    ] : [
      !hide ? AgoraRenderWidget(0, local: true, preview: true) : Container(color: Colors.black,),
    ];
    _userNames.clear();
    if(!SETTINGS.more || HOST)
    _userNames.add(PLAYER.username);
    if(host_index != -1){
      _userNames.add(HOST_NAME);
    }
    int index= 0;
    _users.forEach((AgoraUserInfo user) {
      if(index != host_index) {
        if (_userState[index] == 0) {
          list.add(Container(color: Colors.black,));
        }
        else {
          list.add(AgoraRenderWidget(user.uid));
        }
        _userNames.add(user.userAccount);
      }
      index++;
    });
    return list;
  }

  /// Video view wrapper
  Widget _videoView(view, int index) {
    int audioIndex = _users.indexWhere((element) => element.userAccount == _userNames[index]);
    String name = _userNames[index] == HOST_NAME ? _userNames[index] + " (HOST)" : _userNames[index];
    int state = -1;
    if(audioIndex != -1)
      state = _userAudioState[audioIndex];
    return Expanded(child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.blue, width: 2.0)
        ),
        child: Stack(
         children: <Widget>[
           view,
           Container(
             alignment: Alignment.topCenter,
             child: Container(
                 child: SafeArea(
                   child: LayoutBuilder(
                     builder: (context, constraints){
                       return Row(
                         mainAxisSize: MainAxisSize.min,
                         children: <Widget>[
                           ResizableText(context, 9, name, color: Colors.white),
                           SizedBox(width: 10.0,),
                           state == -1 ? Container(height: 0.0,) : state == 0 ? CircleAvatar(
                             backgroundColor: Colors.white,
                             child: Icon(Icons.mic_off),
                             radius: 12,
                           ) :  CircleAvatar(
                             backgroundColor: Colors.white,
                             child: Icon(Icons.mic),
                             radius: 12,
                           )
                         ],
                       );
                     },
                   ),
                 )
             ),
           ),
         ],
        )
    )
    );
  }

  /// Video view row wrapper
  Widget _expandedVideoRow(List<Widget> views, List<int> indices) {
//    final wrappedViews = views.map<Widget>(_videoView).toList();
    List<Widget> wrappedViews = [];
    for(int i=0;i<views.length;i++){
      wrappedViews.add(_videoView(views[i], indices[i]));
    }
    return Expanded(
      child: Row(
        children: wrappedViews,
      ),
    );
  }

  Widget _listVideoRow(List<Widget> views, List<int> indices){
    List<Widget> wrappedViews = [];
    for(int i=0;i<views.length;i++){
      wrappedViews.add(_videoView(views[i], indices[i]));
    }
    double height = MediaQuery.of(context).size.height*0.3;
    return Container(
      child: Container(
            height: height,
            child: Row(
              children: wrappedViews,
            ),
          ),
    );
  }

  /// Video layout wrapper
  Widget _viewRows() {
    final views = _getRenderViews();
    double height =  MediaQuery.of(context).size.height*0.3;
    try {
      switch (views.length) {
        case 0:
          return Stack(
            children: <Widget>[
              Container(
                  color: Color.fromARGB(255,198,255,245),
                  child: Container(
                      width: MediaQuery.of(context).size.width,
                      height: MediaQuery.of(context).size.height
                  )
              ),
              Container(
                alignment: Alignment.center,
                child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))  ? Container(height: MediaQuery.of(context).size.height*0.4,
                      child: _displayNumberBoard(),
                    ) : Container(height: 0.0,),
                    (!HOST || (HOST && HOST_PLAY)) ? Center(child: ResizableText(context, 8, "TICKET"),) : Container(height: 0.0,),
                    (!HOST || (HOST && HOST_PLAY)) ? Ticket(gridState: SETTINGS.tickets[currentTicket], ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,) : Container(height: 0.0,),
                    SizedBox(height: 20.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[

                        (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                          child: RawMaterialButton(
                            onPressed: (){
                              setState(() {
                                currentTicket--;
                              });
                            },
                            child: Icon(
                              Icons.arrow_left,
                              color: Colors.white,
                              size: 20.0,
                            ),
                            shape: CircleBorder(),
                            elevation: 2.0,
                            fillColor: Colors.blueAccent,
                            padding: const EdgeInsets.all(12.0),
                          ),
                        ) : Container(height:0.0),
                        (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                          child: RawMaterialButton(
                            onPressed: (){
                              setState(() {
                                currentTicket++;
                              });
                            },
                            child: Icon(
                              Icons.arrow_right,
                              color: Colors.white,
                              size: 20.0,
                            ),
                            shape: CircleBorder(),
                            elevation: 2.0,
                            fillColor: Colors.blueAccent,
                            padding: const EdgeInsets.all(12.0),
                          ),
                        ) : Container(height:0.0),
                      ],
                    ),
                    SizedBox(height: 12.0,),
                    VIDEO ? _toolbar() : Container(height:0.0),
                  ],
                ),
              )
            ],
          );
        case 1:
          return Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))? Expanded(child: _displayNumberBoard(),): _videoView(views[0], 0),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[

                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                              child: RawMaterialButton(
                                onPressed: (){
                                  setState(() {
                                    currentTicket--;
                                  });
                                },
                                child: Icon(
                                  Icons.arrow_left,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                                shape: CircleBorder(),
                                elevation: 2.0,
                                fillColor: Colors.blueAccent,
                                padding: const EdgeInsets.all(12.0),
                              ),
                            ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                              child: RawMaterialButton(
                                onPressed: (){
                                  setState(() {
                                    currentTicket++;
                                  });
                                },
                                child: Icon(
                                  Icons.arrow_right,
                                  color: Colors.white,
                                  size: 20.0,
                                ),
                                shape: CircleBorder(),
                                elevation: 2.0,
                                fillColor: Colors.blueAccent,
                                padding: const EdgeInsets.all(12.0),
                              ),
                            ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  )
                ],
              ));
        case 2:
          return Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),): _videoView(views[0], 0),
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height: 0.0,) : _expandedVideoRow([views[1]], [1]),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  )
                ],
              ));
        case 3:
          return Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_expandedVideoRow(views.sublist(0, 2),[0,1]),
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height: 0.0,) :_expandedVideoRow(views.sublist(2, 3),[2]),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  )
                ],
              ));
        case 4:
          return Container(
              color: Colors.white,
              child: Column(
                children: <Widget>[
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_expandedVideoRow(views.sublist(0, 2),[0,1]),
                  displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height: 0.0,) :_expandedVideoRow(views.sublist(2, 4),[2,3]),
                  ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  )
                ],
              ));
        case 5:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0], views[1]], [0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) : Container(
                  height: height+10,
                  child:
                  ListView(
                      children: <Widget>[
                          _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,5),[4]),
                      ],
                    ),

                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 6:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),

                displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                      ],
                    ),

                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 7:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard && (!HOST || (HOST_PLAY && !showConfirmation))? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                         _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                         _listVideoRow(views.sublist(6,7),[6]),
                      ],
                    ),

                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 8:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                      ],
                    ),

                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 9:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,

                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,9),[8]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 10:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,

                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 11:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height + 10,

                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                        _listVideoRow(views.sublist(10,11),[10])
                      ],
                    ),

                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),
                ),
              ],
            ),
          );
        case 12:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                        _listVideoRow(views.sublist(10,12),[10,11]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 13:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height:height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                       _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                        _listVideoRow(views.sublist(10,12),[10,11]),
                        _listVideoRow(views.sublist(12,13),[12]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 14:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                        _listVideoRow(views.sublist(10,12),[10,11]),
                        _listVideoRow(views.sublist(12,14),[12,13]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        case 15:
          return Container(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Expanded(child: _displayNumberBoard(),):_listVideoRow([views[0],views[1]],[0,1]),
                displayBoard&& (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) :Container(
                  height: height+10,
                    child: ListView(
                      children: <Widget>[
                        _listVideoRow(views.sublist(2,4),[2,3]),
                        _listVideoRow(views.sublist(4,6),[4,5]),
                        _listVideoRow(views.sublist(6,8),[6,7]),
                        _listVideoRow(views.sublist(8,10),[8,9]),
                        _listVideoRow(views.sublist(10,12),[10,11]),
                        _listVideoRow(views.sublist(12,14),[12,13]),
                        _listVideoRow(views.sublist(14,15),[13,14]),
                      ],
                    ),
                ),
                Container(child: Expanded(
                  child: ListView(
                    shrinkWrap: true,
                    children: <Widget>[
                      HOST ? HOST_PLAY ? Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket], homePage: true,) : Container(height: 0.0,) : Ticket(gridState: SETTINGS.tickets[currentTicket],
                        ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[

                          (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket--;
                                });
                              },
                              child: Icon(
                                Icons.arrow_left,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                          (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                            child: RawMaterialButton(
                              onPressed: (){
                                setState(() {
                                  currentTicket++;
                                });
                              },
                              child: Icon(
                                Icons.arrow_right,
                                color: Colors.white,
                                size: 20.0,
                              ),
                              shape: CircleBorder(),
                              elevation: 2.0,
                              fillColor: Colors.blueAccent,
                              padding: const EdgeInsets.all(12.0),
                            ),
                          ) : Container(height:0.0),
                        ],
                      ),
                      SizedBox(height: 12.0,),
                      VIDEO ? _toolbar() : Container(height:0.0),
                    ],
                  ),
                ),),
              ],
            ),
          );
        default:
      }
    }
    catch(error){

    }
    return Container();
  }


  Widget _upperButtons(){
    return ended ? Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: <Widget>[
        RaisedButton(
          elevation: 8.0,
          color: Colors.white,
          onPressed: (){
            setState(() {

              showWinners = true;
            });
          },
          child: Text("Show Winners"),
        ),
        RaisedButton(
          elevation: 8.0,
          color: Colors.white,
          onPressed: (){
            if(displayBoard){
              setState(() {
                displayBoard = false;
              });
              return;
            }
            setState(() {
              displayBoard = true;
            });
          },
          child: Text("Show Board"),
        )
      ],
    ) : Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        HOST ? !SETTINGS.started ? RaisedButton(
          elevation: 8.0,
          color: Colors.white,
          onPressed: (){
//            print(SETTINGS.code);
            try {
              if(!CONNECTION)
                return null;
              _sessionDatabase.child(SETTINGS.code).update({
                'st': 'started'
              });
              if(HOST_PLAY) {
                COINS -= TICKET_PRICE*SETTINGS.numTickets;
                if (COINS < 0)
                  COINS = 0;
                SETTINGS.saveCoins();
              }
            }
            catch(error){

            }
          },
          child: Text("Start Game"),
        ) : !AUTOMATIC ? RaisedButton(
          elevation: 8.0,
          color: (noGeneration || SETTINGS.stop.isNotEmpty || SETTINGS.whichNum == 89 || displayBoard) ? Colors.red : Colors.white,
          onPressed: (){
            if(noGeneration || SETTINGS.stop.isNotEmpty || SETTINGS.whichNum == 89 || displayBoard)
              return null;
            _incrementNumber();
          },
          child: Text("Generate Number"),
        ) : RawMaterialButton(
          onPressed: (){
            if(displayingBoard || SETTINGS.stop.isNotEmpty)
              return null;
            _onTogglePause();
            print('toggled pause!!!!!!!!!!!');
          },
          child: Icon(
            isPaused ? Icons.play_arrow : Icons.pause,
            color: isPaused ? Colors.white : Colors.blueAccent,
            size: 20.0,
          ),
          shape: CircleBorder(),
          elevation: 2.0,
          fillColor: displayingBoard || SETTINGS.stop.isNotEmpty ? Colors.redAccent : isPaused ? Colors.blueAccent : Colors.white,
          padding: const EdgeInsets.all(12.0),
        ) : Container(height: 0.0,),
        SizedBox(width: 20.0,),
        RaisedButton(
          elevation: 8.0,
          color: Colors.white,
          onPressed: (){
            if((!HOST || (HOST && HOST_PLAY))){

              setState(() {
                showPrizes = true;
              });
            }
            else{
              if(displayingBoard)
                return null;
//                    print(SETTINGS.ticketList);
              setState(() {
                displayBoard = true;
              });
            }
          },
          child: Text((!HOST || (HOST && HOST_PLAY)) ? "Prize" : "Show Numbers"),
        ),
        (!SETTINGS.started && (!HOST || (HOST && HOST_PLAY))) ? RawMaterialButton(
          onPressed: _refreshTicket,
          child: Icon(
            Icons.refresh,
            color: Colors.white,
            size: 20.0,
          ),
          shape: CircleBorder(),
          elevation: 2.0,
          fillColor: Colors.blueAccent,
          padding: const EdgeInsets.all(12.0),
        ) : Container(height: 0.0,),
      ],
    );
  }
  /// Toolbar layout
  Widget _toolbar() {
    return Container(
      alignment: Alignment.bottomCenter,
      padding: const EdgeInsets.symmetric(vertical: 0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _upperButtons(),
          SizedBox(
            height: 5.0,
          ),
          VIDEO ? Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              !SETTINGS.more || MORE_AUDIO || HOST ?  RawMaterialButton(
                onPressed: _onToggleMute,
                child: Icon(
                  host_muted ? Icons.mic_off : muted ? Icons.mic_off : Icons.mic,
                  color: muted ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: host_muted ? Colors.red : muted ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ): Container(height:0.0),
      !SETTINGS.more || (!MORE_AUDIO && HOST)?  RawMaterialButton(
                onPressed: _onSwitchCamera,
                child: Icon(
                  Icons.switch_camera,
                  color: Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: Colors.white,
                padding: const EdgeInsets.all(12.0),
              ) : Container(height:0.0),
              !SETTINGS.more || (!MORE_AUDIO && HOST) ?   RawMaterialButton(
                onPressed: _onToggleVideo,
                child: Icon(
                  hide ? Icons.videocam_off : Icons.videocam,
                  color: hide ? Colors.white : Colors.blueAccent,
                  size: 20.0,
                ),
                shape: CircleBorder(),
                elevation: 2.0,
                fillColor: hide ? Colors.blueAccent : Colors.white,
                padding: const EdgeInsets.all(12.0),
              ) : Container(height:0.0),
            ],
          ) : Container(height: 0.0,),
        ],
      )
    );
  }

  void _getConfirmationTicket(String prizeName, String playerName) async{
    if(!factoring) {
      factoring = true;
      try {
        DataSnapshot childSnapshot = await _sessionDatabase.child(SETTINGS.code)
            .child('ticket').child(prizeName).child(playerName)
            .once();
        List<dynamic> dynExpandedList = childSnapshot.value['tL'];
        List<String> expandedList = dynExpandedList.cast<String>().toList();
        List<dynamic> dynExpandedOgList = childSnapshot.value['oTL'];
        List<String> expandedOgList = dynExpandedOgList.cast<String>().toList();
        _populateTicketList(_checkingTicket, expandedList, false);
        _populateTicketList(_checkingOgTicket, expandedOgList, false);
        setState(() {
          showMassConfirmation = true;
        });
      }
      catch(error){

      }
    }
  }

  /// Info panel to show logs
  Widget _panel() {
    if(SETTINGS.stop.isNotEmpty && !showNumber) {
      String _prizeName, _playerName, _prizeStatus;
      List<String> _prizeData = SETTINGS.stop[0].split(":");
      _prizeName = _prizeData[0];
      _playerName = _prizeData[1];
      _prizeStatus = _prizeData[2];
      if(_playerName == PLAYER.username && _prizeStatus == "got"){
        if(!SETTINGS.choose)
          canChoose = false;
      }
      String message = _playerName + " has " + _prizeStatus + " " + _prizeName;
      if(_prizeStatus == "got") {

        setState(() {
          showMassConfirmation = false;
          factoring = false;
          _prizeList.removeWhere((element) => element.name == _prizeName);
        });
        
        if(_prizeList.isEmpty && !ended){
          ended = true;
          Timer(new Duration(seconds:5), (){
            if(AT_CALL) {
              setState(() {
                _error = "Session will be deleted in 5 minutes";

                _handleEndgame();
              });
              try{
                automaticTimer.cancel();
              }
              catch(error){

              }
            }
          });
        }
      }
      else if(_prizeStatus == "claimed"){
        if(!HOST) {
          _getConfirmationTicket(_prizeName, _playerName);

        }
      }
      else{
        setState(() {
          showMassConfirmation = false;
          factoring = false;
        });
      }
      return SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: Container(
            decoration: BoxDecoration(
                border: Border.all(),
                color: Colors.white
            ),
            child: ResizableText(context, 12, message),
          ),
        ),
      );
    }
     return Container(height: 0.0,);
  }

  Widget _housieNumber(){
    return showNumber ? SafeArea(
      child: Container(
        alignment: Alignment.topCenter,
        child: CircleAvatar(
            backgroundColor: Colors.white,
            radius: 50.0,
            child: Center(
              child: Text(
                SETTINGS.numList[SETTINGS.whichNum].toString(),
                style: TextStyle(
                  fontSize: 50.0,
                ),
              ),
            ),
          )

      ),
    ) : Container(height: 0.0,);
  }

  Widget _prizeView(){
    return showPrizes ? Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                Text("Tap and hold to view description"),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _prizeList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      return Card(
                        child: ListTile(
                          title: Text(_prizeList[list_index].name),
                          onTap: (){
                            if(!SETTINGS.started || !CONNECTION)
                              return null;
                            if(!canChoose){
                              //ShowMessage
                              setState(() {
                                _error = "You cannot claim more than 1 prize";
                                showPrizes = false;
                              });
                              return null;
                            }
                            if(!_prizeList[list_index].custom) {
                              _checkTicket(
                                  _prizeList[list_index], SETTINGS.whichNum);
                            }
                            else{
                              _sendTicket(_prizeList[list_index]);
                            }
                            setState(() {
                              showPrizes=false;
                            });
                          },
                          onLongPress: (){
                            _showPrizeDescription(list_index);
                          },
                        ),
                      );
                    },
                  ),
                ),
                Center(
                  child: RaisedButton(
                    elevation: 8.0,
                    color: Colors.white,
                    onPressed: () {
                      setState(() {
                        showPrizes = false;
                      });
                    },
                    child: Text("OK"),
                  ),
                )
              ],
            ),
          )
      ),
    ) : Container(height:0.0);
  }

  Future<void> _getWinners(List<String> winners) async{
    try {
      DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code)
          .once();
      List<dynamic> dynWinnerList = snapshot.value['wL'];
      List<String> winnerList = dynWinnerList.cast<String>().toList();
      winnerList.forEach((element) {
        if (!winners.contains(element))
          winners.add(element);
      });
    }
    catch(error){

    }
  }

  Widget _showWinners() {
    if(showWinners) {
      List<String> winnerNames = [];
      List<String> winnerPrizes = [];
      winners.forEach((element) {
        String pName = element.split(":")[0];
        String pWinner = element.split(":")[1];
        winnerNames.add(pWinner);
        winnerPrizes.add(pName);
      });
      return Dialog(
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              height: MediaQuery
                  .of(context)
                  .size
                  .height,
              width: MediaQuery
                  .of(context)
                  .size
                  .width,
              child: ListView(
                children: <Widget>[
                  Center(
                    child: ResizableText(context, 8, "WINNERS"),
                  ),
                  Container(
                    width: MediaQuery
                        .of(context)
                        .size
                        .width,
                    height: MediaQuery
                        .of(context)
                        .size
                        .height * 0.6,
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: winnerNames.length * 2,
                      itemBuilder: (BuildContext context, int index) {
                        if (index % 2 == 1)
                          return Divider();
                        int list_index = index ~/ 2;
                        return Card(
                          child: ListTile(
                            title: Text(winnerNames[list_index] + " won " + winnerPrizes[list_index]),
                          ),
                        );
                      },
                    ),
                  ),
                  Center(
                    child: RaisedButton(
                      elevation: 8.0,
                      color: Colors.white,
                      onPressed: () {
                        setState(() {
                          showWinners = false;
                        });
                      },
                      child: Text("OK"),
                    ),
                  )
                ],
              ),
            )
        ),
      );
    }
    return Container(height:0.0);
  }

  Widget _deleteWarning(){
    if(_error != ""){
      if(_error != "Session will be deleted in 5 minutes") {
        Timer(new Duration(seconds: 5), () {
          if (!AT_CALL)
            return;
          setState(() {
            _error = "";
          });
        });
      }
      return SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: Container(
            color: Colors.white,
            child: ResizableText(context, 14, _error),
          ),
        ),
      );
    }
    return Container(height: 0.0,);
  }

  Widget _settings(){
    return HOST ? SafeArea(
      child: Container(
        padding: EdgeInsets.all(5),
        alignment: Alignment.topRight,
        child: Container(
          child: CircleAvatar(
            radius: 12,
            backgroundColor: Colors.white,
            child: GestureDetector(
              onTap: (){
                Navigator.push(context, new MaterialPageRoute(builder: (context) => Settings(muteList: _muteList,)));
              },
              child: Icon(Icons.settings),
            ),
          )
        ),
      ),
    ) : Container(height:0.0);
  }

  Widget _displayNumberBoard(){

    if(displayBoard){
        if(displayingBoard) {
          if (!startedDisplayTimer) {
            startedDisplayTimer = true;
            Timer(new Duration(seconds: 15), () {
              if (!AT_CALL)
                return;
              setState(() {
                if ((!HOST || HOST_PLAY) && !showConfirmation && !ended)
                  displayBoard = false;
                if (HOST && AUTOMATIC && !isPaused && displayingBoard && !ended)
                  _resumeAutomaticTimer();
                displayingBoard = false;
                startedDisplayTimer = false;
              });
            });
          }
        }

      return ((!HOST || HOST_PLAY) && !showConfirmation) ?

                Container(
//                  height: MediaQuery.of(context).size.height - MediaQuery.of(context).size.height/9*4 + 72,
                  child: ListView(
                  shrinkWrap: true,
                  children: <Widget>[
                    Center(child: Container(
                      color: Colors.white,
                      child: Text("Number Board",),
                    )),
                    Board(gridState: SETTINGS.boardNumList, ogGridState: SETTINGS.ogBoardNumList),
                  ],
                ),
              )
         : SafeArea(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(alignment: Alignment.topCenter,
            child: ListView(
              shrinkWrap: true,
              children: <Widget>[
                Center(child: Container(
                  color: Colors.white,
                  child: Text("Number Board",),
                )),
                Board(gridState: SETTINGS.boardNumList, ogGridState: SETTINGS.ogBoardNumList,large: true,),
                SizedBox(height: 30.0,),
                RaisedButton(
                  elevation: 8.0,
                  onPressed: () {
                    setState(() {
                      displayBoard = false;
                    });
                  },
                  child: Text("OK"),
                )
              ],
            ),
          ),
        ),
      );
    }
    return Container(height: 0.0,);
  }

  Future<bool> _showNumberBoard(){
    return showDialog(
      context: context,
      builder: (context) =>
      new Dialog(
          child: BackdropFilter(
            filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Container(
                  alignment: Alignment.center,
                  child: Board(gridState: SETTINGS.boardNumList, ogGridState: SETTINGS.ogBoardNumList),
                ),
               SizedBox(
                 height: 10.0,
               ),
                RaisedButton(
                 elevation: 8.0,
                 onPressed: () => Navigator.of(context).pop(false),
                 child: Text("OK"),
                )
              ],
            )
          ),
      )
    ) ??
        false;

  }

  Widget _showConfirmationView(){

    if(showConfirmation){
      if(HOST && AUTOMATIC){
        isPaused = true;
        try {
          automaticTimer.cancel();
        }
        catch(error){

        }
      }
      return BackdropFilter(
        filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          alignment: Alignment.center,
          child: Container(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Ticket(gridState: _checkingTicket, ogGridState: _checkingOgTicket, checking: true,),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RaisedButton(
                      elevation: 8.0,
                      color: Colors.greenAccent,
                      onPressed: () {
                        if(!CONNECTION)
                          return null;
                        setState(() {
                          showConfirmation = false;
                        });
                        try {
                          _sessionDatabase.child(SETTINGS.code).runTransaction((
                              mutableData) async {
                            List<dynamic> dynStopList = mutableData
                                .value['stop'];
                            List<String> stopList = dynStopList.cast<String>()
                                .toList();
                            String name = stopList[0].split(":")[1];
                            String prize = stopList[0].split(":")[0];
                            stopList[0] = "$prize:$name:got";
                            mutableData.value['stop'] = stopList;
                            return mutableData;
                          });
                        }
                        catch(error){

                        }
                      },
                      child: Text("CORRECT"),
                    ),
                    RaisedButton(
                      elevation: 8.0,
                      color: Colors.redAccent,
                      onPressed: () {
                        if(!CONNECTION)
                          return null;
                        setState(() {
                          showConfirmation = false;
                        });
                        _sessionDatabase.child(SETTINGS.code).runTransaction((mutableData) async{
                          List<dynamic> dynStopList = mutableData.value['stop'];
                          List<String> stopList = dynStopList.cast<String>().toList();
                          String name = stopList[0].split(":")[1];
                          String prize = stopList[0].split(":")[0];
                          stopList[0] = "$prize:$name:not got";
                          mutableData.value['stop'] = stopList;
                          return mutableData;
                        });

                      },
                      child: Text("INCORRECT"),
                    ),
                  ],
                ),
                SizedBox(height: 20.0,),
                RaisedButton(
                  elevation: 8.0,
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      displayBoard = true;
                    });
                  },
                  child: Text("SHOW BOARD"),
                ),
              ],
            )
          ),
        ),
      );
    }
    if(showMassConfirmation){
      return BackdropFilter(
        filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          alignment: Alignment.center,
          child: Container(
            child: Ticket(gridState: _checkingTicket, ogGridState: _checkingOgTicket,checking: true,),
          ),
        ),
      );
    }
    return Container(height: 0.0,);
  }
//
  Widget _background(){
    return Stack(
      children: <Widget>[
        Container(
        color: Color.fromARGB(255,198,255,245),
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height
        )
        ),
        Container(
          alignment: Alignment.center,
          child: ListView(
            shrinkWrap: true,
            children: <Widget>[
              displayBoard ? Container(height: MediaQuery.of(context).size.height*0.4,
              child: _displayNumberBoard(),
              ) : Container(height: 0.0,),
              (!HOST || (HOST && HOST_PLAY)) ? Center(child: ResizableText(context, 8, "TICKET"),) : Container(height: 0.0,),
              (!HOST || (HOST && HOST_PLAY)) ? Ticket(gridState: SETTINGS.tickets[currentTicket], ogGridState: SETTINGS.ogTickets[currentTicket],homePage: true,) : Container(height: 0.0,),
              SizedBox(height: 20.0,),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[

                  (!HOST || HOST_PLAY) && currentTicket > 0 ? Container(
                    child: RawMaterialButton(
                      onPressed: (){
                        setState(() {
                          currentTicket--;
                        });
                      },
                      child: Icon(
                        Icons.arrow_left,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor: Colors.blueAccent,
                      padding: const EdgeInsets.all(12.0),
                    ),
                  ) : Container(height:0.0),
                  (!HOST || HOST_PLAY) && currentTicket < SETTINGS.numTickets - 1 ? Container(
                    child: RawMaterialButton(
                      onPressed: (){
                        setState(() {
                          currentTicket++;
                        });
                      },
                      child: Icon(
                        Icons.arrow_right,
                        color: Colors.white,
                        size: 20.0,
                      ),
                      shape: CircleBorder(),
                      elevation: 2.0,
                      fillColor: Colors.blueAccent,
                      padding: const EdgeInsets.all(12.0),
                    ),
                  ) : Container(height:0.0),
                ],
              ),
              _upperButtons(),
              displayBoard ? Container(height: 100.0,) : Container(height:0.0),
            ],
          ),
        )
      ],
    );
  }



  void _onTogglePause(){
    if(!SETTINGS.started)
      return null;

    try{
      if(isPaused)
        _resumeAutomaticTimer();
      else
        automaticTimer.cancel();
    }
    catch(error){

    }
    setState(() {
      isPaused = !isPaused;
    });
  }

  void _onCallEnd(BuildContext context) {
    Navigator.pop(context);
  }

  void _onToggleMute() {

    setState(() {
      muted = !muted;
    });
    AgoraRtcEngine.muteLocalAudioStream(muted);

  }

  void _onToggleVideo() {
    setState(() {
      hide = !hide;
    });
    AgoraRtcEngine.muteLocalVideoStream(hide);
  }

  void _onSwitchCamera() {
    AgoraRtcEngine.switchCamera();
  }

  void _refreshTicket(){
    setState(() {
      SETTINGS.ticketList = ListGenerator.generateTicketList();
      SETTINGS.ogTicketList = ListGenerator.getOgList();
      _populateLast(currentTicket);
    });
  }


  Future<void> _factorClaims() async{
    factoring = true;
    print("factor bob");
    DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code).once();
    List<dynamic> dynStopList = snapshot.value['stop'];
    List<String> stopList = dynStopList == null ? [] : dynStopList.cast<String>().toList();
    if(stopList != [] || stopList != null){
      String element = stopList[0];
      String _status = stopList[0].split(":")[2];
      String _playerName = stopList[0].split(":")[1];
      String _prizeName = stopList[0].split(":")[0];
      if(_status == "claimed"){
        DataSnapshot childSnapshot = await _sessionDatabase.child(SETTINGS.code).child('ticket').child(_prizeName).child(_playerName).once();
        List<dynamic> dynExpandedList = childSnapshot.value['tL'];
        List<String> expandedList = dynExpandedList.cast<String>().toList();
        List<dynamic> dynExpandedOgList = childSnapshot.value['oTL'];
        List<String> expandedOgList = dynExpandedOgList.cast<String>().toList();
        _populateTicketList(_checkingTicket, expandedList, false);
        _populateTicketList(_checkingOgTicket, expandedOgList, false);
        setState(() {
          showConfirmation = true;
          displayBoard = false;
        });
      }
      else{
        _deleteClaims = Timer(new Duration(seconds: 1), (){
          _sessionDatabase.child(SETTINGS.code).runTransaction((mutableData) async {
            stopList.removeAt(0);
            List<dynamic> dynWinnerList = mutableData.value['wL'];
            List<String> winnerList = dynWinnerList == null
                ? []
                : dynWinnerList.cast<String>().toList();
            if (_status == "got") {
              stopList.removeWhere((element) =>
              element.split(":")[0] == _prizeName);
              if(winnerList == [] || !winnerList.any((element2) => element == element2))
                winnerList.add(element);
            }
            mutableData.value['stop'] = stopList;
            mutableData.value['wL'] = winnerList;
            return mutableData;
          });
        });
      }
    }
    factoring = false;
  }

  Widget _showOfflineMessage(){
    if(showMessage){
      Timer(new Duration(seconds: 1), (){
        setState(() {
          showMessage = false;
        });
      });
      return SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: Container(
            child: ResizableText(context, 14, _offlineMessage),
          ),
        ),
      );
    }
    return Container(height:0.0);
  }

  Future<bool> _closeDisplayBoard(){

      setState(() {
        displayBoard = false;
      });
    return Future.value(false);
  }

  Future<bool> _closeShowPrize(){
    setState(() {
      showPrizes = false;
      showWinners = false;
    });
    return Future.value(false);
  }

  Future<void> _handleEndgame() async{
    Timer(new Duration(seconds: 10), (){
      if(AT_CALL)
        ads.showFullScreenAd(state: this);
    });
    try {
      await _getWinners(winners);
      winners.forEach((element) {
        String name = element.split(":")[1];
        if (name == PLAYER.username) {
          String prizeName = element.split(":")[0];
          Prize p = _absolutePrizeList.firstWhere((element) =>
          element.name == prizeName);
          COINS += (SETTINGS.playerList.length * TICKET_PRICE * p.value / 100)
              .ceil();
          try {
            SETTINGS.saveCoins();
          }
          catch(error){

          }
        }
      });
    }
    catch(error){

    }
    setState(() {
      showWinners = true;
    });
    if(HOST){
      _sessionDatabase.child(SETTINGS.code).update({
        'st': "ended",
        'eT': DateTime.now().millisecondsSinceEpoch
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    if(!showNumber && SETTINGS.stop.isNotEmpty && HOST && !showConfirmation && !factoring)
      _factorClaims();
    return WillPopScope(
      onWillPop: showPrizes ? _closeShowPrize : !displayBoard ? _onBackPressed : _closeDisplayBoard,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: Stack(
            children: <Widget>[
              LifeCycle(),
              VIDEO ? _viewRows() : _background(),

//              VIDEO ? Container(height: 0.0,) : _inconvenienceWidget(),

              HOST && !HOST_PLAY ? _showConfirmationView() : displayBoard ? Container(height:0.0) : _showConfirmationView(),
              showConfirmation ? _panel() : Container(height:0.0),
//              !VIDEO ? _displayNumberBoard() : Container(height: 0.0,),
            (!HOST || (HOST_PLAY && !showConfirmation)) ? Container(height:0.0) : _displayNumberBoard() ,
              _showOfflineMessage(),
              ConnectionWidget(),
              !showConfirmation ? _panel() : Container(height:0.0),
              _prizeView(),
              _housieNumber(),
              _deleteWarning(),
              _showWinners(),
              _settings(),
              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(5),
                  alignment: Alignment.topLeft,
                  child: Container(
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.redAccent,
                        child: GestureDetector(
                          onTap: (){
                            close_pressed = true;
                            _onBackPressed();
                          },
                          child: Icon(Icons.close),
                        ),
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
/*
if(!SETTINGS.started)
                            return null;
                          _checkTicket(_prizeList[list_index],SETTINGS.whichNum);
                          setState(() {
                            showPrizes=false;
                          });
 */