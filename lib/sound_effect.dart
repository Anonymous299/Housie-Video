import 'package:audioplayers/audio_cache.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioEffects{
  static Future<AudioPlayer> playSound(String file) async {
    AudioCache cache = new AudioCache();
    return await cache.play(file);
  }
}