import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/player_data.dart';
//TODO clean this class
class Ticket extends StatefulWidget{
  final List<List<String>> gridState;
  final List<List<String>> ogGridState;
  final bool checking;
  final bool homePage;
  Ticket({
    @required this.gridState,
    @required this.ogGridState,
    this.checking = false,
    this.homePage = false,
  }) :  assert(gridState != null);

  _TicketState createState() => _TicketState();
}

class _TicketState extends State<Ticket>{
  @override
  Widget build(BuildContext context) {
    return _buildTicketBody();
  }
  Widget _buildTicketBody(){
    const int gridStateBreadth = 9;
    const int gridStateLength = 3;
    return widget.gridState.isEmpty ? Container(height: 0.0,) : Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.all(0),
      height: widget.homePage ? MediaQuery.of(context).size.width/9*4 : MediaQuery.of(context).size.height * 0.4,
          child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridStateBreadth),
            itemBuilder: _buildGridItems,
            physics: NeverScrollableScrollPhysics(),
            itemCount: gridStateBreadth * gridStateLength,
          ),


        );

  }
  Widget _buildGridItems(BuildContext context, int index){
    const int gridStateBreadth = 9;
    int x = (index / gridStateBreadth).floor();
    int y = (index % gridStateBreadth);
    return GestureDetector(
      onTap: (){
        if(widget.gridState[x][y] == '' || widget.checking) {

          return;
        }
        if(widget.gridState[x][y] == '*'){
          if(!AT_HOME)
            SETTINGS.saveTicket();
          setState(() {
            widget.gridState[x][y] = widget.ogGridState[x][y];
          });
        }
        else {
          if(!AT_HOME)
            SETTINGS.saveTicket();
          setState(() {
            widget.gridState[x][y] = "*";
          });
        }
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            color: widget.checking ? widget.gridState[x][y] == "*" ? Colors.greenAccent : Colors.white : Colors.white,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: _buildGridItem(x, y, constraints),
              );
            },
          ),
        ),
      ),
    );
  }
  Widget _buildGridItem(int x, int y, BoxConstraints constraints){
    String character = widget.gridState[x][y];
    if(character == '*')
    {
      return Stack(
        children: <Widget>[

          !widget.checking ? Icon(Icons.clear, size: constraints.maxWidth,) : Container(height:0.0),
          Center(
            child: Text(widget.ogGridState[x][y], style: TextStyle(
              fontSize: constraints.maxWidth/2,
            ),
            ),
          ),
        ],
      );
    }
    else if(character == ''){
      return Text('');
    }
    else{
      return Text(character, style: TextStyle(
        fontSize: constraints.maxWidth/2,
      ),);
    }
  }
}