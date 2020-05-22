import 'package:flutter/cupertino.dart';

Prize fast5 = new Prize("FAST 5", "Prize claimed when any five numbers have been crossed out on your card", false,10);
Prize firstRow = new Prize("FIRST ROW", "Prize claimed when the whole first row of numbers has been crossed out", false,15);
Prize secondRow = new Prize("SECOND ROW", "Prize claimed when the whole second row of numbers has been crossed out", false,15);
Prize thirdRow = new Prize("THIRD ROW", "Prize claimed when the whole third row of numbers has been crossed out", false,15);
Prize fullHouse = new Prize("FULL HOUSE", "Prize claimed when all numbers of your ticket have been crossed out", false,35);
Prize fourCorners = new Prize('FOUR CORNERS', "Prize claimed when you have crossed out the four corner numbers of your ticket", false,10);
List<Prize> prizeList = [fourCorners, fast5, firstRow, secondRow, thirdRow, fullHouse];
List<Prize> previousPrizes = [];
class Prize{
  String name;
  String description;
  int value;
  bool custom;
  Prize(
      this.name,
      this.description,
      this.custom,
      this.value
      );
}