import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:housie/player_data.dart';
//TODO clean this class
class Board extends StatefulWidget{
  final List<List<String>> gridState;
  final List<List<String>> ogGridState;
  final bool large;
  Board({
    @required this.gridState,
    @required this.ogGridState,
    this.large = false,
  }) :  assert(gridState != null);

  _BoardState createState() => _BoardState();
}

class _BoardState extends State<Board>{
  @override
  Widget build(BuildContext context) {
    return _buildTicketBody();
  }
  Widget _buildTicketBody(){
    const int gridStateBreadth = 10;
    const int gridStateLength = 9;
    return widget.gridState.isEmpty ? Container(height: 0.0,) : Container(
      width: MediaQuery.of(context).size.width,
      height: widget.large ? MediaQuery.of(context).size.height * 0.7 : MediaQuery.of(context).size.height,
      child:  Center(
        child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridStateBreadth),
          itemBuilder: _buildGridItems,
          itemCount: gridStateBreadth * gridStateLength,
        ),
      ),

    );

  }
  Widget _buildGridItems(BuildContext context, int index){
    const int gridStateBreadth = 10;
    int x = (index / gridStateBreadth).floor();
    int y = (index % gridStateBreadth);
    return GridTile(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            color: widget.gridState[x][y] == "*" ? Colors.greenAccent : Colors.white,
          ),
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              return Center(
                child: _buildGridItem(x, y, constraints),
              );
            },
          ),
        ),
      );
  }
  Widget _buildGridItem(int x, int y, BoxConstraints constraints){
    String character = widget.ogGridState[x][y];

      return Text(character, style: TextStyle(
        fontSize: constraints.maxWidth/2,
      ),);

  }
}