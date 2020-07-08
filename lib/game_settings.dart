import 'package:firebase_database/firebase_database.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:shared_preferences/shared_preferences.dart';

class GameSettings {
  List<int> numList = [];
  List<List<List<String>>> tickets = [];
  List<List<List<String>>> ogTickets = [];
  List<List<String>> ticketList = [['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', '']];
  List<List<String>> ogTicketList = [['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', ''],
    ['', '', '', '', '', '', '', '', '']];
  List<List<String>> boardNumList = [
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""]
  ];
  List<List<String>> ogBoardNumList = [
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""],
    ["", "", "", "", "", "", "", "", "", ""]
  ];
  List<String> playerList = [];
  int whichNum = -1;
  bool started = false;
  List<String> stop = [];
  String code;
  bool more = false;
  bool choose = true;
  int numTickets = 1;
  DatabaseReference _playerDatabase = FirebaseDatabase(
      databaseURL: "https://housie-7a94e-71bf5.firebaseio.com/")
      .reference()
      .child("players");

  GameSettings();

  GameSettings.fromSnapshot(DataSnapshot snapshot)
      :
        numList = snapshot.value['nL'],
        playerList = snapshot.value['pL'],
        whichNum = snapshot.value['wN'],
        started = snapshot.value['st'],
        stop = snapshot.value['stop'];

  toJson() {
    List<String> prizeNames = prizeList.map((e) => e.name).toList();
    List<String> prizeDesc = prizeList.map((e) => e.description).toList();
    List<bool> prizeCustoms = prizeList.map((e) => e.custom).toList();
    List<int> prizeValues = prizeList.map((e) => e.value).toList();
    return {
      'nL': numList,
      'pL': playerList,
      'wN': whichNum,
      'st': started == true ? "started" : "",
      'stop': stop,
      'm': more,
      'time': DateTime
          .now()
          .millisecondsSinceEpoch,
      'h': PLAYER.username,
      'v': VIDEO,
      'cu': {
        'pN': prizeNames,
        'pD': prizeDesc,
        'pC': prizeCustoms,
        'pV': prizeValues,
      }
    };
  }

  reset() {
    numList = [];
    ticketList = [['', '', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', '', '']];
    ogTicketList = [['', '', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', '', ''],
      ['', '', '', '', '', '', '', '', '']];
    tickets = [];
    ogTickets = [];
    playerList = [];
    whichNum = -1;
    started = false;
    stop = [];
    code = null;
    more = false;
    choose = true;
    numTickets = 1;
    HOST = false;
    MORE_AUDIO = false;
    REPEAT = false;
    HOST_NAME = "";
  }

  save() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('code', code);
    prefs.setBool("host", HOST);
    prefs.setBool("automatic", AUTOMATIC);
    prefs.setInt("duration", DURATION);
    prefs.setBool("choose", choose);
    prefs.setBool("video", VIDEO);
    prefs.setBool("audio", MORE_AUDIO);
    prefs.setInt("numTickets", numTickets);
    List<String> expandedTicketList = [];
    List<String> expandedOgTicketList = [];
    for (int i = 0; i < tickets.length; i++) {
      for (int j = 0; j < tickets[0].length; j++) {
        for (int k = 0; k < tickets[0][0].length; k++) {
          expandedTicketList.add(tickets[i][j][k]);
          expandedOgTicketList.add(ogTickets[i][j][k]);
        }
      }
    }
    prefs.setStringList('tickets', expandedTicketList);
    prefs.setStringList('ogTickets', expandedOgTicketList);

    expandedTicketList = [];
    expandedOgTicketList = [];
    for (int i = 0; i < boardNumList.length; i++) {
      for (int j = 0; j < boardNumList[0].length; j++) {
        expandedTicketList.add(boardNumList[i][j]);
        expandedOgTicketList.add(ogBoardNumList[i][j]);
      }
    }
    prefs.setStringList('boardList', expandedTicketList);
    prefs.setStringList('ogBoardList', expandedOgTicketList);
  }

  savePrizes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    List<String> pNames = [];
    List<String> pDescs = [];
    List<String> pVals = [];
    for (int i = 0; i < prizeList.length; i++) {
      pNames.add(prizeList[i].name);
      pDescs.add(prizeList[i].description);
      pVals.add(prizeList[i].value.toString());
    }
    previousPrizes.forEach((element) {
      if (!pNames.contains(element.name)) {
        pNames.add(element.name);
        pDescs.add(element.description);
        pVals.add(element.value.toString());
      }
    });
    prefs.setStringList("prizeNames", pNames);
    prefs.setStringList("prizeDescriptions", pDescs);
    prefs.setStringList("prizeValues", pVals);
  }

  saveTicket() async {
    if (tickets[0][0].isEmpty)
      return;
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      List<String> expandedTicketList = [];
      for (int i = 0; i < tickets.length; i++) {
        for (int j = 0; j < tickets[0].length; j++) {
          for (int k = 0; k < tickets[0][0].length; k++) {
            expandedTicketList.add(tickets[i][j][k]);
          }
        }
      }
      prefs.setStringList('tickets', expandedTicketList);
    }
    catch(error){

    }
  }
  saveCoins() async{
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt("coins", COINS);
    _playerDatabase.child(PLAYER.username).update({'c': COINS});
  }

}