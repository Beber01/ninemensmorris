import 'package:web_ui/web_ui.dart';
import 'dart:html';

class Mouvement {
  TableCellElement depart = null;
  TableCellElement arrive = null;
  
  Mouvement(TableCellElement depart, TableCellElement arrive) {
    this.depart = depart;
    this.arrive = arrive;
  }
  
  TableCellElement getDepart() {
    return depart;
  }
  
  TableCellElement getArrive() {
    return arrive;
  }
}