import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

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