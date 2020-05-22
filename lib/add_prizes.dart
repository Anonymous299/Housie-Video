import 'dart:async';
import 'dart:ui';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/common_widgets.dart';
import 'package:housie/player_data.dart';
import 'package:housie/prize.dart';
import 'package:housie/settings.dart';

class AddPrize extends StatefulWidget{
  _AddPrizeState createState() => _AddPrizeState();
}

class _AddPrizeState extends State<AddPrize>{
  TextEditingController _nameController = new TextEditingController();
  TextEditingController _descriptionController = new TextEditingController();
  final  _validCharacters = RegExp(r'^[$#[]:/\]+$'); //Allowed characters
  String _error = "";
  String _sliderError = "";
  bool showPrizes = false;
  bool showValues = false;
  bool previous = false;
  bool showMessage = false;


  Future<bool> _showPrizeDescription(int index){
    String prizeName = previous ? previousPrizes[index].name : prizeList[index].name;
    String description = previous ? previousPrizes[index].description : prizeList[index].description;
    String value = previous ? previousPrizes[index].value.toString() : prizeList[index].value.toString();
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

  Future<void> addPrize(Prize prize) async{
    _error = "";
    if(!previous && (_nameController.text == "" || _nameController.text == null || _descriptionController.text == "" || _descriptionController.text == null)){
      setState(() {
        _error = "Name or description cannot be blank";
      });
      return;
    }
    if(!previous && (_validCharacters.hasMatch(_nameController.text) || _validCharacters.hasMatch(_descriptionController.text))){
      setState(() {
        _error = "Description or name contains invalid characters";
      });
      return;
    }
    if(!previous && (prizeList.any((element) => element.name == prize.name))){
      setState(() {
        _error = "Prize with the same name already exists";
      });
      return;
    }
    if(!previous && prize.value > 40){
      setState(() {
        _error = "Value of prize cannot be more than 40 coins";
      });
      return;
    }
    if(previous && (prizeList.any((element) => element.name == prize.name))){
      setState(() {
        showMessage = true;
      });
      return;
    }
    int sum = prize.value;
    int index=0;
    while(sum!=0){
      if(index == prizeList.length)
        index = 0;
      prizeList[index].value--;
      sum--;
      index++;
    }

    prizeList.add(prize);
    setState(() {
      showMessage = true;
      showValues = true;
    });

    _nameController.clear();
    _descriptionController.clear();

  }

  Widget _nameInputArea(){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.topCenter,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ResizableText(context, 8, "Enter Prize Name"),
            SizedBox(height: 20.0,),
            !showPrizes && !showValues ? TextField(
                maxLength: 20,
                controller: _nameController,
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
                    labelText: "Prize Name"
                )
            ) : Container(height:0.0)
          ],
        ),
      ),
    );
  }

  Widget _descriptionInputArea(){
    return Container(
      padding: EdgeInsets.symmetric(vertical: 48),
      alignment: Alignment.topCenter,
      child: Container(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ResizableText(context, 8, "Enter Prize Description"),
            SizedBox(height: 20.0,),
            !showPrizes && !showValues ? TextField(
              maxLength: 200,
                maxLines: 8,
                controller: _descriptionController,
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
                    labelText: "Prize Description"
                )
            ) : Container(height:0.0)
          ],
        ),
      ),
    );
  }



  Widget _showValueButton(){
    return ResizableButton(context, 10, "SET PRIZE VALUES", (){
      if(previous || showPrizes || showValues)
        return null;
      setState(() {
        showValues = true;
      });
    });
  }

  Widget _addPrizeButton(){
    return ResizableButton(context, 10, "ADD PRIZE", (){
      if(previous || showPrizes || showValues)
        return null;
      addPrize(new Prize(_nameController.text, _descriptionController.text, true, 5));
    });
  }

  Widget _previousPrizeButton(){
    return ResizableButton(context, 10, "CHOOSE FROM PREVIOUS PRIZES", (){
      if(previous || showPrizes || showValues)
        return null;
      setState(() {
        previous = true;
      });
    });
  }

  Widget _showPrizeButton(){
    return ResizableButton(context, 10, "SHOW PRIZES", (){
      if(previous || showPrizes)
        return null;
      setState(() {
        showPrizes = true;
      });
    });
  }

  Widget _showPrizes(){
    return showPrizes || previous ? Dialog(
      child: BackdropFilter(
          filter : ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            child: ListView(
              children: <Widget>[
                Text("Tap and hold to view description"),
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height * 0.8,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: previous ? previousPrizes.length*2 : prizeList.length*2,
                    itemBuilder: (BuildContext context, int index){
                      if(index%2==1)
                        return Divider();
                      int list_index = index~/2;
                      return Card(
                        child: ListTile(
                          title: Text(previous ? previousPrizes[list_index].name : prizeList[list_index].name),
                          onTap: (){
                            if(previous){
                              addPrize(previousPrizes[list_index]);
                            }
                          },
                          onLongPress: (){
                            _showPrizeDescription(list_index);
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
                        showPrizes = false;
                        previous = false;
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

  Widget _showAdded({String message = "Prize Added", Color color = Colors.greenAccent}){
    if(showMessage){
      Timer(new Duration(seconds: 1), (){
        setState(() {
          showMessage = false;
        });
      });
      return SafeArea(
        child: Container(
          alignment: Alignment.topCenter,
          child: Container(
            color: color,
            child: ResizableText(context, 14, message),
          ),
        ),
      );
    }
    return Container(height:0.0);
  }

  Future<bool> _closeShowPrize(){
    setState(() {
      previous = false;
      showPrizes = false;
    });
    return Future.value(false);
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

  @override
  Widget build(BuildContext context) {
    print(showValues);
    return WillPopScope(
      onWillPop: showPrizes || previous ? _closeShowPrize : showValues ? _closeShowValue : null,
      child: SafeArea(
        child: Scaffold(
          body: Stack(
            children: <Widget>[

              ListView(
                children: <Widget>[
                  _nameInputArea(),
                  _descriptionInputArea(),
                  _error != "" ? Center(child: ResizableText(context, 15, _error, color: Colors.red),) : Container(height: 0.0,),
                  _addPrizeButton(),
                  SizedBox(height: 10.0,),
                  _showValueButton(),
                  SizedBox(height: 10.0,),
                  _previousPrizeButton(),
                  SizedBox(height: 10.0,),
                  _showPrizeButton(),
                ],
              ),
              _showPrizes(),
              _showValues(),
              _showAdded(),
              SafeArea(
                child: Container(
                  padding: EdgeInsets.all(30),
                  alignment: Alignment.topLeft,
                  child: Container(
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.redAccent,
                        child: GestureDetector(
                          onTap: (){
                            Navigator.pop(context);
                          },
                          child: Icon(Icons.close),
                        ),
                      )
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}