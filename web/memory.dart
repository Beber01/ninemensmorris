import 'package:web_ui/web_ui.dart';
import 'dart:html';

class Memory {
  
  List tables = new List();
  TableSectionElement lastTable;
  
  void addTable(TableSectionElement table) {
    tables.add(table.clone(true));
    lastTable = table;
  }
  
  /**
   * Retourne true si l'on a enregistré trois fois les mêmes positions
   */
  bool threeTimesSameTable() {
    int count = 0;
    var t = tables;
    for (TableSectionElement table in tables) {
      if (compare(table, lastTable))
        count++;
    }
    return (count >= 3);
  }
  
  /**
   * Retourne true si les deux tables sont identiques
   */
  bool compare(TableSectionElement table1, TableSectionElement table2) {
    for(int i = 0; i < 13; i++) {
      TableRowElement row1 = table1.children[i];
      TableRowElement row2 = table2.children[i];
      
      for(int y = 0; y < 13; y++) {
        TableCellElement cell1 = row1.children[y];
        TableCellElement cell2 = row2.children[y];
        
        if (cell1.classes.length > 0 && cell2.classes.length > 0) {
          if (cell1.classes.first != cell2.classes.first)
            return false;
        }
      }
    }
    return true; 
  }
}