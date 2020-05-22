import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/add_prizes.dart';
import 'package:housie/common_widgets.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:housie/call.dart';
//TODO add sound on/off, automatic number, host play


List<Prize> prevPrizes = [];
class Settings extends StatefulWidget{
  final List<String> muteList;
  Settings({this.muteList});
  _SettingState createState() => _SettingState();
}

class _SettingState extends State<Settings>{

  bool _changed = false; //Checks if user has changed any settings
  TextEditingController _durationController = new TextEditingController();
  TextEditingController _numController = new TextEditingController();
  int _duration = DURATION;
  final  _validCharacters = RegExp(r'^[0-9]+$'); //Allowed username characters
  String _error="";
  String _numError="";
  int number = SETTINGS.numTickets;
  String _sliderError = "";
  DatabaseReference _sessionDatabase = FirebaseDatabase(databaseURL: "https://housie-7a94e.firebaseio.com/").reference().child("sessions");


  //Data for automatic buttons
  List<bool> _automaticSelected = [AUTOMATIC, !AUTOMATIC];
  List<String> _automaticButtonList = ["YES","NO"];

  //Data for play buttons
  List<bool> _playSelected = [HOST_PLAY, !HOST_PLAY];
  List<String> _playButtonList = ["YES","NO"];

  //Data for choose buttons
  List<bool> _chooseSelected = [SETTINGS.choose, !SETTINGS.choose];
  List<String> _chooseButtonList = ["YES","NO"];

  bool showPrizes = false;
  bool deleting = false;
  bool showValues = false;
  bool showMuted = false;
  bool showKicked = false;
  List<Prize> deleted = [];
  List<String> tempMuteList = [];

  Future<bool> _showPrizeDescription(int index){
    String prizeName = prizeList[index].name;
    String description = prizeList[index].description;
    String value = prizeList[index].value.toString();
    return showDialog(
      context: context,
      builder: (context) =>
      new AlertDialog(
        title: new Text(prizeName + " Description"),
        content: new Text(
            description + "\nValue: " + value + "%"
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

  Future<void> _saveChanges() async{
    if(SETTINGS.started){
      if(AUTOMATIC != _automaticSelected[0] || DURATION != _duration)
        {
          isPaused =  true;
          try {
            automaticTimer.cancel();
          }
          catch(error){

          }
        }
    }
    AUTOMATIC = _automaticSelected[0];
    DURATION = _duration;
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool("host", HOST);
    prefs.setBool("automatic", AUTOMATIC);
    prefs.setInt("duration", DURATION);

    if(HOST && VIDEO){
      try {
        DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code)
            .once();
        List<dynamic> dynMuteList = snapshot.value['mL'] ?? [];
        List<String> muteList = dynMuteList.cast<String>().toList();
        muteList = tempMuteList;
        _sessionDatabase.child(SETTINGS.code).update({
          'mL': muteList
        });
      }
      catch(error){

      }
    }

    if(!SETTINGS.started) {
      if(AT_SESSION){
        SETTINGS.numTickets = number;
      }
      HOST_PLAY = _playSelected[0];
      prefs.setBool("host_play", HOST_PLAY);
      SETTINGS.savePrizes();



        if(!CONNECTION){
          prizeList = [];
          prevPrizes.forEach((element) {
            prizeList.add(new Prize(element.name, element.description, element.custom, element.value));
          });
        }
        else{
          SETTINGS.choose = _chooseSelected[0];
        List<String> prizeNames = [];
        List<String> prizeDescs = [];
        List<bool> prizeCustoms = [];
        List<int> prizeValues = [];
        prizeList.forEach((prize) {
          prizeNames.add(prize.name);
          prizeDescs.add(prize.description);
          prizeCustoms.add(prize.custom);
          prizeValues.add(prize.value);
        });
      try {
        await _sessionDatabase.child(SETTINGS.code).update({
          'c': SETTINGS.choose,
        });
        await _sessionDatabase.child(SETTINGS.code).child('cu').update({
          'pN': prizeNames,
          'pD': prizeDescs,
          'pC': prizeCustoms,
          'pV': prizeValues,
        });
      }
      catch(error) {
        prizeList = [];
        prevPrizes.forEach((element) {
          prizeList.add(new Prize(
              element.name, element.description, element.custom,
              element.value));
        });
      }
      }
    }
  }

  void _updateDuration(){
    String duration = _durationController.text;
    if(duration == "" || duration == null){
      setState(() {
        _error = "Duration cannot be blank";
      });
      return;
    }
    if(!(_validCharacters.hasMatch(duration))){
      setState(() {
        _error = "Duration can only have numerical characters";
      });
      return;
    }
    if(int.parse(duration) > 20 || int.parse(duration) < 1){
      setState(() {
        _error = "Duration cannot be more than 20 seconds or less than 1 second";
      });
      return;
    }
    setState(() {
      if(_duration != int.parse(duration))
        _changed = true;
      _duration = int.parse(duration);
    });
  }

  Future<bool> _onBackPressed() {

      return showDialog(
        context: context,
        builder: (context) => new AlertDialog(
          title: new Text('Save Changes?'),
          content: new Text('Do you want to save your changes?'),
          actions: <Widget>[
            new RaisedButton(
              onPressed: () {
                prizeList = [];
                prevPrizes.forEach((element) {
                  prizeList.add(new Prize(element.name, element.description, element.custom, element.value));
                });
                Navigator.of(context).pop(true);
                },
              child: Text("NO"),
            ),
            SizedBox(height: 16),
            new RaisedButton(
              onPressed: () {
                _saveChanges();
                return Navigator.of(context).pop(true);
              },
              child: Text("YES"),
            ),
            SizedBox(height: 16),
            new RaisedButton(
              onPressed: () {

                Navigator.of(context).pop(false);
              },
              child: Text("CANCEL"),
            ),
          ],
        ),
      ) ??
          false;
  }

  Widget _showDuration(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 12, "Current duration: $_duration seconds"),),
        TextField(
          keyboardType: TextInputType.number,
          controller: _durationController,
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
            labelText: "Duration",
          ),
        ),
        Center(
          child: RaisedButton(
            elevation: 8.0,
            child: Text("SET DURATION"),
            onPressed: _updateDuration,
          ),
        ),
        _error == "" ? Container(height: 0.0,) : ResizableText(context, 12, _error, color: Colors.red)
      ],
    );
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
        _changed = true;
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


  Widget _automaticButtons(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 11, "AUTOMATIC GENERATING OF NUMBERS?"),),
        Container(
          child: Center(child: _toggleButtons(_automaticButtonList, _automaticSelected, 6, padding: 60),),
        ),
        _automaticSelected[0] ? _showDuration() : Container(height: 0.0,),
        Divider(thickness: 3.0,)
      ],
    );
  }

  Widget _playButtons(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 8, "WILL HOST PLAY?"),),
        Container(
          child: Center(child: _toggleButtons(_playButtonList, _playSelected, 6, padding: 60),),
        ),
        Divider(thickness: 3.0,)
      ],
    );
  }

  Widget _chooseButtons(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 13, "ALLOW MULTIPLE PRIZES ON SAME TICKET?"),),
        Container(
          child: Center(child: _toggleButtons(_chooseButtonList, _chooseSelected, 6, padding: 60),),
        ),
        Divider(thickness: 3.0,)
      ],
    );
  }

  Widget _muteButton() {
    return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: ResizableButton(context, 10, "MUTE/UNMUTE USER", () {
            if(showKicked || showMuted || showPrizes || showValues)
              return null;
            setState(() {
              showMuted = true;
            });
          }),
        )
    );
  }

  Widget _kickButton() {
    return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: ResizableButton(context, 9, "REMOVE USER", () {
            if(showKicked || showMuted || showPrizes || showValues)
              return null;
            setState(() {
              showKicked = true;
            });
          }),
        )
    );
  }

  Widget _numTicketWidget(){
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Center(child: ResizableText(context, 15, "Current number of tickets: " + number.toString()),),
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
              number = n;
            });
          },
          child: Text("SET NUMBER OF TICKETS"),
        ),
        ),
        SizedBox(height: 20.0,),
      ],
    );
  }

  Widget _saveButton() {
    return Center(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0),
          child: ResizableButton(context, 8, "SAVE CHANGES", () {
            if(showKicked || showMuted || showPrizes || showValues)
              return null;
            _saveChanges();
            Navigator.pop(context);
          }),
        )
      );
  }

  Widget _showPrizes(){
    return showPrizes ? Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                deleting ? ResizableText(context, 13, "Tap or swipe prize name to delete") : Text("Tap and hold to view description"),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: prizeList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      int list_index = index~/2;
                      Prize p = prizeList[list_index];
                      if(index%2==1)
                        return Divider();
                      return deleting ? Dismissible(
                        key: Key(prizeList[list_index].name),
                        onDismissed: (dismissDirection){
                            int sum = p.value;
                            int index=0;
                            prizeList.removeAt(list_index);
                            while(sum!=0){
                              if(index==prizeList.length)
                                index = 0;
                              prizeList[index].value++;
                              index++;
                              sum--;
                            }
                            _changed = true;
                            setState(() {

                            });

                        },
                        child: Card(
                          color: Colors.redAccent,
                          child: ListTile(
                            title: Text(p.name),
                            onTap: (){
                              int sum = p.value;
                              int index=0;
                              prizeList.removeAt(list_index);
                              while(sum!=0){
                                if(index==prizeList.length)
                                  index = 0;
                                prizeList[index].value++;
                                sum--;
                              }
                                _changed = true;
                                setState(() {
                                });

                            },
                            onLongPress: (){
                              _showPrizeDescription(list_index);
                            },
                          ),
                        ),
                      ) : Card(
                        child: ListTile(
                          title: Text(p.name),
                          onTap: (){
                          },
                          onLongPress: (){
                            _showPrizeDescription(list_index);
                          },
                        ),
                      );
                    },
                  ),
                ),
                !deleting ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    SizedBox(height:30.0),
                        RaisedButton(
                          elevation: 8.0,
                          color: Colors.white,
                          onPressed: () {
                            setState(() {
                              showValues = true;
                            });
                          },
                          child: Text("SHOW PRIZE VALUES"),
                        ),

                    SizedBox(height: 10.0,),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: <Widget>[
                        RaisedButton(
                          elevation: 8.0,
                          color: Colors.blueAccent,
                          onPressed: () {
                            _changed = true;
                            setState(() {
                              showPrizes = false;
                            });
                            Navigator.push(context, MaterialPageRoute(
                                builder: (context) => AddPrize()
                            ));
                          },
                          child: Text("ADD PRIZE"),
                        ),
                        RaisedButton(
                          elevation: 8.0,
                          color: Colors.redAccent,
                          onPressed: () {
                            setState(() {
                              deleting = true;
                            });
                          },
                          child: Text("DELETE PRIZE"),
                        ),

                      ],
                    )
                  ],
                ) : RaisedButton(
                  elevation: 8.0,
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      deleting = false;
                    });
                  },
                  child: Text("DONE"),
                ),
                deleting? Container(height:0.0) : RaisedButton(
                  elevation: 8.0,
                  color: Colors.white,
                  onPressed: () {
                    setState(() {
                      showPrizes = false;
                    });
                  },
                  child: Text("OK"),
                ),
              ],
            ),
          )
      ),
    ) : Container(height:0.0);
  }

  Widget _showValues(){
    return showValues ?  Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: prizeList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      return Card(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Center(child: ResizableText(context, 11, prizeList[list_index].name),),
                            Slider(
                              value: prizeList[list_index].value.toDouble(),
                              max: 100,
                              min: 0,
                              onChanged: (value){
                                if(value < 0)
                                  return null;
                                _sliderError = "";
                                int sum = 0;
                                prizeList.forEach((element) {
                                  if(element != prizeList[list_index])
                                    sum+=element.value;
                                });
                                sum+=value.toInt();
                                if(sum > 100){
                                  setState(() {
                                    _sliderError = "Sum of percentages cannot be more than 100";
                                  });
                                  setState(() {
                                    prizeList[list_index].value = (value - (sum - 100)).toInt();
                                  });
                                }
                                else {
                                  setState(() {
                                    prizeList[list_index].value = value.toInt();
                                  });
                                }
                              },
                              divisions: 100,
                            ),
                            Center(child: ResizableText(context, 13, "Current value: " + prizeList[list_index].value.toString() + "%")),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                _sliderError != "" ? ResizableText(context, 20, _sliderError, color: Colors.red) : Container(height: 0.0,),
                Center(
                  child: RaisedButton(
                    elevation: 8.0,
                    color: Colors.white,
                    onPressed: () {
                      _sliderError = "";
                      int sum = 0;
                      prizeList.forEach((element) {
                        sum += element.value;
                      });
                      if (sum != 100) {
                        int dif = 100 - sum;
                        int index = 0;
                        while (dif != 0) {
                          if (index == prizeList.length)
                            index = 0;
                          prizeList[index].value++;
                          index++;
                          dif--;
                        }
                      }
                      setState(() {
                        showValues = false;
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

  Widget _showMuted(){
    return showMuted ?  Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: SETTINGS.playerList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      if(SETTINGS.playerList[list_index] == PLAYER.username)
                        return Container(height: 0.0,);
                      return Card(
                          color: tempMuteList.any((element) => element == SETTINGS.playerList[list_index]) ? Colors.redAccent : Colors.blueAccent,
                          child: ListTile(
                            title: Center(child: ResizableText(context, 11, SETTINGS.playerList[list_index]),),
                            onTap: () {
                              _changed = true;
                             setState(() {
                               if (tempMuteList.contains(
                                   SETTINGS.playerList[list_index])) {
                                 tempMuteList.remove(
                                     SETTINGS.playerList[list_index]);
                               }
                               else {
                                 tempMuteList.add(
                                     SETTINGS.playerList[list_index]);
                               }
                             });
                             print(widget.muteList);
                            },
                          ),
                      );
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    RaisedButton(
                      elevation: 8.0,
                      color: Colors.blueAccent,
                      child: Text("UNMUTE ALL"),
                      onPressed: (){
                        _changed = true;
                        setState(() {
                          tempMuteList.clear();
                        });
                      },
                    ),
                    RaisedButton(
                      elevation: 8.0,
                      color: Colors.redAccent,
                      child: Text("MUTE ALL"),
                      onPressed: (){
                        _changed = true;
                        SETTINGS.playerList.forEach((element) {
                          if(element != PLAYER.username)
                            tempMuteList.add(element);
                        });
                        setState(() {

                        });
                      },
                    )
                  ],
                ),
                RaisedButton(
                  elevation: 8.0,
                  color: Colors.white,
                  child: Text("OK"),
                  onPressed: (){
                    setState(() {
                      showMuted = false;
                    });
                  },
                )
              ],
            ),
          )
      ),
    ) : Container(height:0.0);
  }

  Future<bool> _onKicked(String name) {
    return showDialog(
      context: context,
      builder: (context) => new AlertDialog(
        title: new Text('Are you sure?'),
        content: new Text('Do you want to kick ' + name + ' out?'),
        actions: <Widget>[
          new RaisedButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text("NO"),
          ),
          SizedBox(height: 16),
          new RaisedButton(
            onPressed: () async{
              DataSnapshot snapshot = await _sessionDatabase.child(SETTINGS.code).once();
              List<dynamic> dynPlayerList = snapshot.value['pL'];
              List<String> playerList = dynPlayerList.cast<String>().toList();
              playerList.remove(name);
              _sessionDatabase.child(SETTINGS.code).update({
                'pL': playerList,
              });
              setState(() {
                SETTINGS.playerList.remove(name);
              });
              return Navigator.of(context).pop(true);
            },
            child: Text("YES"),
          ),
        ],
      ),
    ) ??
        false;
  }

  Widget _showKicked(){
    return showKicked ?  Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: SETTINGS.playerList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      if(SETTINGS.playerList[list_index] == PLAYER.username)
                        return Container(height: 0.0,);
                      return Card(
                        color: Colors.white,
                        child: ListTile(
                          title: Center(child: ResizableText(context, 11, SETTINGS.playerList[list_index]),),
                          onTap: () {
                              _onKicked(SETTINGS.playerList[list_index]);
                          },
                        ),
                      );
                    },
                  ),
                ),

                RaisedButton(
                  elevation: 8.0,
                  color: Colors.greenAccent,
                  child: Text("OK"),
                  onPressed: (){
                    setState(() {
                      showKicked = false;
                    });
                  },
                )
              ],
            ),
          )
      ),
    ) : Container(height:0.0);
  }

  Future<bool> _closeShowValue(){
    _sliderError = "";
    int sum = 0;
    prizeList.forEach((element) {
      sum+=element.value;
    });
    if(sum != 100){
      int dif = 100-sum;
      int index = 0;
      while(dif!=0){
        if(index==prizeList.length)
          index=0;
        prizeList[index].value++;
        index++;
        dif--;
      }
    }
    setState(() {
      showValues = false;
    });
    return Future.value(false);
  }

  Future<bool> _closeShowMuted(){

    setState(() {
      showMuted = false;
      showKicked = false;
    });
    return Future.value(false);
  }

  @override
  void initState() {
    super.initState();
    prizeList.forEach((element) {
      prevPrizes.add(new Prize(element.name,element.description,element.custom,element.value));
    });
    if(widget.muteList != null){
      widget.muteList.forEach((element) {
        tempMuteList.add(element);
      });
    }
  }

  @override
  void dispose(){
    prevPrizes = [];
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print(SETTINGS.choose);
    return WillPopScope(
      onWillPop: showMuted || showKicked ? _closeShowMuted : showValues ? _closeShowValue : _changed ? _onBackPressed : null,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: <Widget>[
              ListView(
                children: <Widget>[
                  _automaticButtons(),
                  !SETTINGS.started ? _playButtons() : Container(height: 0.0,),
                  !SETTINGS.started ? _chooseButtons() : Container(height: 0.0,),
                  !SETTINGS.started && AT_SESSION ? _numTicketWidget() : Container(height: 0.0,),
                  !SETTINGS.started ? ResizableButton(context, 9, "Prizes", (){
                    setState(() {
                      showPrizes = true;
                    });
                  }) : Container(height: 0.0,),
                  SETTINGS.started && HOST && VIDEO && (!SETTINGS.more || MORE_AUDIO) ? _muteButton() : Container(height: 0.0,),
                  SETTINGS.started && HOST ? _kickButton() : Container(height: 0.0,),
                  _saveButton(),
                  Center(child:ResizableText(context, 15, "Housie Code: " + SETTINGS.code)),
                  HOST ? Center(child:ResizableText(context, 15, "Current number of players in game: " + SETTINGS.playerList.length.toString())): Container(height:0.0),
                ],
              ),
              _showPrizes(),
              _showValues(),
              _showMuted(),
              _showKicked(),
            ],
          )
        ),
      ),
    );
  }
}
/* */
