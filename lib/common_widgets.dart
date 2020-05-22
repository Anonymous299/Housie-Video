
import 'package:connectivity/connectivity.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/player_data.dart';

import 'custom_button.dart';

Widget ResizableText(BuildContext context, int divisor, String text,{String fontFamily="Paint Stroke", Color color = Colors.black}){
  return Text(
    text,
    style: TextStyle(
      color: color,
      fontFamily: fontFamily,
      fontSize: MediaQuery.of(context).size.width / divisor,
    ),
  );
}

Widget ConnectionWidget(){
  return SafeArea(
    child: StreamBuilder(
        stream: Connectivity().onConnectivityChanged,
        builder: (BuildContext ctxt,
            AsyncSnapshot<ConnectivityResult> snapShot) {
          if (!snapShot.hasData) return Container(height: 0.0,);
          var result = snapShot.data;
          switch (result) {
            case ConnectivityResult.none:
              CONNECTION = false;
              return _showConnectionStatus(ctxt);
            case ConnectivityResult.mobile:
            case ConnectivityResult.wifi:
              CONNECTION = true;
              return Container(height: 0.0,);
            default:
              CONNECTION = false;
              return _showConnectionStatus(ctxt);
          }
        }),
  );
}

Widget _showConnectionStatus(BuildContext context){
  return Container(
    alignment: Alignment.bottomCenter,
    height: MediaQuery.of(context).size.height/11,
    color: Colors.white,
    margin: EdgeInsets.symmetric(vertical: 10.0),
    child: ResizableText(context, 11, "No internet connection!"),
  );
}

Widget ResizableButton(BuildContext context, int divisor, String text, Function onPressed, {String fontFamily="Paint Stroke", Color color = Colors.black}){
  return FlatButton(
    child: ResizableText(context, divisor, text),
    shape: BeveledRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12.0)),
      side: BorderSide(width: 2.0, style: BorderStyle.solid),
    ),
    onPressed: onPressed,
  );
}

GradientPainter _painter(List<bool> _isSelected, int index){
  return _isSelected[index] ? GradientPainter(
      strokeWidth: 4, radius: 12, gradient: LinearGradient(
    colors: [Colors.red, Colors.redAccent],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  )
  ) : GradientPainter(strokeWidth: 4, radius: 12, gradient: LinearGradient(
    colors: [Colors.black, Colors.black12],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  )
  );
}

Widget ButtonContainer(List<bool> _isSelected, Widget child, int index, {double padding = 10.0}){
  return CustomPaint(
    painter: _painter(_isSelected, index),
    child: Container(
        padding: EdgeInsets.symmetric(horizontal: padding),
        constraints: BoxConstraints(minWidth: 88, minHeight: 48),
        child: Center(child: child,)
    ),

  );
}

