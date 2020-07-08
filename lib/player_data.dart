import 'package:housie/game_settings.dart';
import 'package:housie/player.dart';
import 'dart:io' show Platform;


const TICKET_PRICE = 100;
const REWARD = 250;
const List<List<String>> OG_HOMEGRID = [
  ['F','U','N','','F','O','R','',''],
  ['','E','V','E','R','Y','O','N','E'],
  ['A','T','','H','O','M','E','!','']
]; //Grid for home screen ticket

List<List<String>> HOMEGRID = [
  ['F','U','N','','F','O','R','',''],
  ['','E','V','E','R','Y','O','N','E'],
  ['A','T','','H','O','M','E','!','']
];
bool IS_AUTH = false;
Player PLAYER = new Player("", null);
GameSettings SETTINGS = new GameSettings();
bool CONNECTION = false;
bool HOST = false;
bool SOUND_ENABLED = true;
bool AUTOMATIC = false;
bool HOST_PLAY = false;
bool VIDEO = true;
bool MORE_AUDIO = false;
int DURATION = 5;
String HOST_NAME = "";
int COINS = 500;
bool AT_HOME = true;
bool AT_SESSION = false;
bool AT_CALL = false;
bool REPEAT = false;

final String appId = Platform.isAndroid

    ? 'ca-app-pub-2328129614997367~6944303526'

    : 'ca-app-pub-3940256099942544~1458002511';

final String bannerUnitId = Platform.isAndroid

    ? 'ca-app-pub-2328129614997367/4038389846'
//? 'ca-app-pub-3940256099942544/6300978111'

    : 'ca-app-pub-3940256099942544/2934735716';

final String screenUnitId = Platform.isAndroid

    ? 'ca-app-pub-2328129614997367/5411730005'
//? 'ca-app-pub-3940256099942544/1033173712'

    : 'ca-app-pub-3940256099942544/4411468910';

final String videoUnitId = Platform.isAndroid

    ? 'ca-app-pub-2328129614997367/1472484995'
//? 'ca-app-pub-3940256099942544/5224354917'

    : 'ca-app-pub-3940256099942544/1712485313';

