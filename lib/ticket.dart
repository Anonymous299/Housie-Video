import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//TODO clean this class
class Ticket extends StatefulWidget{
  final List<List<String>> gridState;
  final List<List<String>> ogGridState;
  Ticket({
    @required this.gridState,
    @required this.ogGridState,
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
    return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height * 0.2,
          child:  Center(
            child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: gridStateBreadth),
              itemBuilder: _buildGridItems,
              itemCount: gridStateBreadth * gridStateLength,
            ),
          ),

        );

  }
  Widget _buildGridItems(BuildContext context, int index){
    const int gridStateBreadth = 9;
    int x = (index / gridStateBreadth).floor();
    int y = (index % gridStateBreadth);
    return GestureDetector(
      onTap: (){
        if(widget.gridState[x][y] == '') {

          return;
        }
        if(widget.gridState[x][y] == '*'){
          setState(() {
            widget.gridState[x][y] = widget.ogGridState[x][y];
          });
        }
        else {
          setState(() {
            widget.gridState[x][y] = "*";
          });
        }
      },
      child: GridTile(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black, width: 2.0),
            color: Colors.white,
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

          Icon(Icons.clear, size: constraints.maxWidth,),
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