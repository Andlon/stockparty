library stock;

import 'dart:math';
part 'src/stat.dart';

class Stock {
  final String name;
  final num initial;
  num current;
  
  Stock(this.name, this.initial) { current = initial; }
  
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
