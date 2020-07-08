



import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class InstructionsPage extends StatefulWidget{
  @override
  _InstructionsState createState() => _InstructionsState();
}
class _InstructionsState extends State<InstructionsPage>{
  int TOTAL_PAGES = 5;
  int pageNum = 0;
  List<String> _pageList = ["HOW TO PLAY","START GAME", "GAME SETTINGS", "PRIZES", "PRIZE SETTINGS"];
  bool showPages = false;


  Widget _howInstruction(){
    return SingleChildScrollView(
      child: RichText(
        text: TextSpan(
          text: '',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width/13,
              color: Colors.black,),
          children: <TextSpan>[
            TextSpan(text: '  How To Play\n\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/8)),
            TextSpan(text: '  Objective: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
            TextSpan(text: '''\n\n  Strike out numbers as they are called out such that you become eligible to win a prize.\n\nGame ends when: All prizes are claimed.\n\n•	Users have to pay attention to numbers as they get called out and as soon as the numbers are called out in a particular sequence, making them eligible for a prize, claim your prize using the following sequence:\n\n Prize -> Name of Prize you have Won\n\n'''),
            TextSpan(text: '    Swipe left or right for other instructions', style: TextStyle(fontFamily: "Ariel", fontSize: MediaQuery.of(context).size.width/20))
          ],
        ),
      ),
    );
  }
  Widget _startGameInstruction(){
    return SingleChildScrollView(
      child: RichText(
        text: TextSpan(
          text: '',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width/13,
              color: Colors.black,
              ),
          children: <TextSpan>[
            TextSpan(text: '  To Start The Game\n\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/10)),
            TextSpan(text: '''\n\n•	Click on Play button on the home screen.\n\n•	The button will not work if you have less than 100 coins (i.e. the price of a single ticket)\n\n•	To earn more coins, you may watch an ad.\n\n•	If you are going to host the game, you have two sets of options: Video/No Video:
'''),
            TextSpan(text: '  Video: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
            TextSpan(text: ''' For a game where players are not playing together in the same place, the host can use the video option which makes the game interactive as the users can enjoy the live video call while being part of the game session.'''),
            TextSpan(text: '\n\n  No Video: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
            TextSpan(text: ''' When all users are playing together in the same room, use this option for system generated tickets and convenient hosting experience.'''),
            TextSpan(text: '\n\n  Number of Players(for video): ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
            TextSpan(text: '\n\n  Less than 15: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''If the number of phones playing is less than 15, the host can select this option and the game is played with a seamless video call for all players. Users from the same place can access using one phone since there is an option of multiple tickets.'''),
            TextSpan(text: '\n\n  More than 15: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''Choose this option when playing with more than 15 people.\n\n  With audio: Every users voice can be heard with this option. There is no video during the game session.\n\n  Without audio: Only host’s video and voice will be streamed to all users.\n\n•	Once the host selects the appropriate option and starts the game, a game code gets created which the host can share with all players using any messaging platform. 
'''),
            TextSpan(text: '\n\n  How to join: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''\n\n•	Once the host selects the appropriate option and starts the game, a game code gets created which the host can share with all players using any messaging platform. Enter this code in the appropriate field provided under the "Join Game" heading.'''),


            TextSpan(text: '\n\n    Swipe left or right for other instructions', style: TextStyle(fontFamily: "Ariel", fontSize: MediaQuery.of(context).size.width/20)),
          ],
        ),
      ),
    );
  }

  Widget _settingsInstruction(){
    return SingleChildScrollView(
      child: RichText(

        text: TextSpan(
          text: '',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width/13,
              color: Colors.black,),
          children: <TextSpan>[
            TextSpan(text: '  Game Settings\n\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/8)),
            TextSpan(text: ' Automatic Generating of Numbers: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''The host will not need to press the “Generate Number” button every time and a number gets automatically generated at a fixed interval of time set by the host. The host can pause or play the generation and can also turn this function on or off.'''),
            TextSpan(text: '\n\n Will Host Play: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''If the host is not playing the game then he/she can constantly see the game board. If the host is playing the game, then the game board automatically becomes visible to all users after every 20 numbers for a period of 20 seconds.'''),
            TextSpan(text: '\n\n Allow Multiple Prizes on Same Ticket: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''This setting by the host decided whether or not a person can claim more than one prize on the same ticket.'''),
            TextSpan(text: '\n\n Number of Tickets: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''Choose the number of tickets you want to play with during a game'''),
            TextSpan(text: '\n\n Prizes: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''  Shows a list of prizes enabled for the current game\n\n Add Prize: Lets you add a custom prize. For more information look under "Prize Settings".\n\n  Delete Prize: Delete a prize from the current game.'''),
            TextSpan(text: '\n\n Mute/Unmute User: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''  Allows host to mute/unmute a user in the game.'''),
            TextSpan(text: '\n\n Remove User: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/12)),
            TextSpan(text: '''  Allows host to remove a user from the game.'''),


            TextSpan(text: '\n\n    Swipe left or right for other instructions', style: TextStyle(fontFamily: "Ariel", fontSize: MediaQuery.of(context).size.width/20)),
          ],
        ),
      ),
    );
  }

  Widget _prizeInstructions(){

      return SingleChildScrollView(
        child: RichText(

          text: TextSpan(
            text: '',
            style: TextStyle(fontSize: MediaQuery.of(context).size.width/13,
                color: Colors.black,),
            children: <TextSpan>[
              TextSpan(text: '  Prizes\n\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/8)),

              TextSpan(text: '''•	If the prize is system generated, the app will check the prize and declare whether or not the user has won the prize.\n\n•	If the prize is custom generated by the host, the ticket on which the prize is won gets displayed on everyone’s screen and the host can either mark the claim as correct or incorrect.\n\n•	The'''),
              TextSpan(text: '  default ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
              TextSpan(text: ''' prizes are:\n\n'''),
              TextSpan(text: '  Four Corners: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
              TextSpan(text: '''If the first and last numbers of the first and last rows are announced, you eligible for this prize.'''),
              TextSpan(text: '\n\n  FAST 5: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
              TextSpan(text: '''The first player to strike off 5 numbers off his ticket wins this prize.
First Row: When all the numbers from the first row are called out and marked, you win this prize.'''),
              TextSpan(text: '\n\n  Row: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
              TextSpan(text: '''The first, second or third row can be claimed when all the numbers from the first, second or third row respectively are called out and marked.'''),
              TextSpan(text: '\n\n  Full House: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
              TextSpan(text: '''When all the numbers from your ticket are called out and marked, you win this prize.'''),
              TextSpan(text: '\n\n    Swipe left or right for other instructions', style: TextStyle(fontFamily: "Ariel", fontSize: MediaQuery.of(context).size.width/20))
            ],
          ),
        ),
      );
  }

  Widget _pSettingsInstructions(){
    return SingleChildScrollView(
      child: RichText(

        text: TextSpan(
          text: '',
          style: TextStyle(fontSize: MediaQuery.of(context).size.width/13,
              color: Colors.black,),
          children: <TextSpan>[
            TextSpan(text: ' Prize Settings\n\n', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/8)),
//            TextSpan(text: '  Objective: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: MediaQuery.of(context).size.width/11)),
            TextSpan(text: '''•	The prize values are set as a percentage of the total coin value which is pooled by all players playing the game (each ticket = 100 coins).\n\n•	The host can view and change these values in the option known as “Show Prize Values”\n\n•	The host can also add a custom prize to the game using “Add Prize” option where the user can give a name and description to the prize. In this option, the host can also choose from the list of previously added custom prizes using the option “Choose from Previous Prizes”.\n\n•	Similarly, the host can also delete a prize from the list that he/she may not want.\n\n•	These prize settings can be made any time before the game starts.'''),

            TextSpan(text: '\n\n    Swipe left or right for other instructions', style: TextStyle(fontFamily: "Ariel", fontSize: MediaQuery.of(context).size.width/20))
          ],
        ),
      ),
    );
  }

  Widget _instruction(){
    switch(pageNum){
      case 0:
        return _howInstruction();
        break;
      case 1:
        return _startGameInstruction();
        break;
      case 2:
        return _settingsInstruction();
        break;
      case 3:
        return _prizeInstructions();
        break;
      case 4:
        return _pSettingsInstructions();
        break;
      default:
        return null;
    }
  }

  Widget _dismissInstructions(){
    if(pageNum>=TOTAL_PAGES-1 || pageNum <= 0){
      return Dismissible(
        key: UniqueKey(),
        child: _instruction(),
        direction: pageNum>=TOTAL_PAGES-1 ? DismissDirection.startToEnd : DismissDirection.endToStart,
        onDismissed: (direction){
          if(direction == DismissDirection.endToStart && pageNum<TOTAL_PAGES-1)
            setState(() {
              pageNum++;
            });
          else if(direction == DismissDirection.startToEnd && pageNum > 0)
            setState(() {
              pageNum--;
            });
        },
      );
    }
    return Dismissible(
      key: UniqueKey(),
      child: _instruction(),
      onDismissed: (direction){
        if(direction == DismissDirection.endToStart && pageNum<TOTAL_PAGES-1)
          setState(() {
            pageNum++;
          });
        else if(direction == DismissDirection.startToEnd && pageNum > 0)
          setState(() {
            pageNum--;
          });
      },
    );
  }

  Widget _showPages(){
    return showPages ? Dialog(
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
                    itemCount: TOTAL_PAGES*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      return Card(
                        child: ListTile(
                          title: Text(_pageList[list_index]),
                          onTap: (){
                            setState(() {
                              showPages = false;
                              pageNum = list_index;
                            });
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
                        showPages = false;
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
    Scaffold(
    appBar: AppBar(
        title: Text("INSTRUCTIONS"),
    actions: <Widget>[
    new FlatButton(
    onPressed: () {
      setState(() {
        showPages = true;
      });
    },
    child: new Text('NAVIGATE TO',
    style: Theme
        .of(context)
        .textTheme
        .subtitle1
        .copyWith(color: Colors.white))),
    ],
    ),
    body: _dismissInstructions()
    ),
        _showPages(),
      ],
    );
  }
}