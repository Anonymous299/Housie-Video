

import 'package:firebase_database/firebase_database.dart';
import 'package:housie/player_data.dart';

class Player{
  String currentSession;
  String username;

  Player(this.currentSession, this.username);

  Player.fromSnapshot(DataSnapshot snapshot) :
      currentSession = snapshot.value['currentSession'];

  toJson() {
    return {
      'cS': SETTINGS.code,
      'c': COINS
    };
  }
}