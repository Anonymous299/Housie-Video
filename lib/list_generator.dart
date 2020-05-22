import 'dart:math';

class ListGenerator{
  static int rows = 3;
  static int cols = 9;
  static List<List<String>> _ogBoardNums = [["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""]];
  static List<List<String>> _ogList;
  List<List<String>> populatingList = [['','','','','','','','',''],
    ['','','','','','','','',''],
    ['','','','','','','','','']];
  static List<List<String>> generateTicketList(){
    ListGenerator generator = new ListGenerator();
    List<List<String>> ticket = generator.populateList();
    _ogList = generator.populatingList;
    List<List<int>> numbersUsed = [[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1],[-1,-1,-1]];
    Random rand = new Random();
    for(int row = 0; row<rows;row++){
      for(int col = 0; col < cols; col++){
        if(ticket[row][col] == '*'){
          bool numberChosen = false;
          while(!numberChosen){
            int additer = rand.nextInt(10);
            bool numberAlreadyChosen = false;
            if(additer > 10-3+row){
              continue;
            }
            if(row != 0){
              numbersUsed[col].forEach((element) {
                if(additer < element)
                  numberAlreadyChosen = true;
              });
            }
            for(int i=0;i<3;i++){
              if(additer == numbersUsed[col][i]){
                numberAlreadyChosen = true;
                break;
              }
//              if((i < row) && (additer < numbersUsed[col][i])){
//                numberAlreadyChosen = true;
//                break;
//              }
            }
            if(numberAlreadyChosen)
              continue;
            ticket[row][col] = (col*10 + additer + 1).toString();
            _ogList[row][col] = (col*10 + additer + 1).toString();
            numbersUsed[col][row] = additer;
            numberChosen = true;
          }
        }
      }
    }
    return ticket;
  }
  static List<List<String>> getOgList(){
    return _ogList;
  }
  List<List<String>> populateList(){
    List<List<String>> ticket = [['','','','','','','','',''],
      ['','','','','','','','',''],
      ['','','','','','','','','']];
    const int rowMax = 5;
    int rowFilled;
    Random rand = new Random();
    for(int row=0;row<rows;row++){
      rowFilled = 0;
      int col = 0;
      if(row == 2){
        List<int> emptyIndex = [];
        for(int i=0;i<9;i++){
          if(ticket[0][i] == '' && ticket[1][i] == ''){
            emptyIndex.add(i);
            rowFilled++;
          }
        }
        emptyIndex.forEach((element) {
          ticket[2][element] = '*';
          populatingList[2][element] = '*';
        });
      }
      while(rowFilled != rowMax){
        if(col == cols)
        {
          col = 0;
          continue;
        }
        if(ticket[row][col] == '*') {
          col++;
          continue;
        }
        bool shouldPopulate = rand.nextBool();
        if(shouldPopulate){
          ticket[row][col] = '*';
          populatingList[row][col] = '*';
          rowFilled++;
        }
        col++;
      }
    }
    return ticket;
  }
  static List<int> housieNumberGenerator(){
    List<int> numOrder = [];
    Random rand = new Random();
    while(numOrder.length != 90){
      int num = rand.nextInt(90) + 1;
      if(numOrder.contains(num))
        continue;
      numOrder.add(num);
    }
    return numOrder;
  }
  static List<List<String>> fillBoardNums(){
    List<List<String>> boardNums = [["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""],["","","","","","","","","",""]];
    for(int i=0;i<90;i++){
      int row = (i/10).floor();
      int col = i%10;
      boardNums[row][col] = (i+1).toString();
      _ogBoardNums[row][col] = (i+1).toString();
    }
    return boardNums;
  }
  static List<List<String>> getOgBoardNums(){
    return _ogBoardNums;
  }
}
