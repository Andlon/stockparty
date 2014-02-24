library stock;

import 'dart:math';
part 'src/stat.dart';

class Stock {
  final String name;
  final num initial;
  num current;
  
  Stock(this.name, this.initial) { current = initial; }
  Stock.fromHistory(this.name, this.initial, this.current); 
  
  num get change => 100 * ((current / initial) - 1);
  
  Map toJson() {
    return { 'name': name, 'initial': initial, 'current': current };
  }
  
  static Stock fromJson(json)
  {
    Stock s = new Stock(json["name"], json["initial"]);
    s.current = json["current"];
    return s;
  }
}
