import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/cupertino.dart';
import 'package:housie/call.dart';
import 'package:wakelock/wakelock.dart';
class LifeCycle extends StatefulWidget{
  @override
  _LifeCycleState createState() => _LifeCycleState();
}
class _LifeCycleState extends State<LifeCycle> with WidgetsBindingObserver {
  AppLifecycleState notification;
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if(state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      AgoraRtcEngine.muteLocalVideoStream(true);
      AgoraRtcEngine.muteLocalAudioStream(true);
      Wakelock.disable();
    }
    else if(state == AppLifecycleState.resumed) {
     if(!hide)
      AgoraRtcEngine.muteLocalVideoStream(false);
     if(!muted){
       AgoraRtcEngine.muteLocalAudioStream(false);
     }
     Wakelock.enable();
    }
  }

  @override
  initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
  @override
  Widget build(BuildContext context) {
    return Container(height: 0.0,);
  }
}