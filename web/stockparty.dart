import 'package:angular/angular.dart';
import 'package:animation/animation.dart';
import 'dart:async';
import 'dart:html';
import 'stat.dart';

const PERIOD = const Duration(seconds: 1);
const a = 0.01;

// Bootstrap
main() => ngBootstrap(module: new StockExchangeModule());

/*
 * Initialize stocks here
 */
List<Stock> buildStocks()
{
  List<Stock> stocks = new List();
  stocks.add(new Stock("JGR", 200));
  stocks.add(new Stock("VDK", 150));
  stocks.add(new Stock("SAM", 200));
  stocks.add(new Stock("MCALN", 250));
  stocks.add(new Stock("LAPHR", 200));
  stocks.add(new Stock("JGR", 200));
  stocks.add(new Stock("VDK", 150));
  stocks.add(new Stock("SAM", 200));
  stocks.add(new Stock("MCALN", 250));
  stocks.add(new Stock("LAPHR", 200));
  
  return stocks;
}

/* Implementation below */

@NgController(
  selector: '[stockexchange]',
  publishAs: 'exchange')
class StockExchangeController {
  List<Stock> stocks;
  Timer timer;
  
  StockExchangeController() {
    stocks = buildStocks();
    startTimer();
  }
  
  void startTimer() {
    timer = new Timer(PERIOD, handleTick);
  }
  
  void handleTick() {
    updateStocks();
    notify();
    startTimer();
  }
  
  void updateStocks()
  {
    for (Stock stock in stocks)
    {
      // Generate new price. If it drops below zero, generate another.
      int newPrice;
      do {
        newPrice = stock.current + rnorm(mean: 0.0, std: a * stock.initialPrice).round();
      } while (newPrice < 0);
      stock.update(newPrice);
    }
  }
  
  void notify()
  {
    var element = querySelector("#exchange");
    element.
    var fade = new ElementAnimation(element)
      ..duration = 150
      ..properties = {
                      
      };
  }
}

class StockExchangeModule extends Module {  
  StockExchangeModule()
  {
    type(StockExchangeController);
  }
}

class Stock {
  final String name;
  final int    initialPrice;
  List<int>     prices;
  
  Stock(this.name, this.initialPrice) { prices = [ initialPrice ]; }
  
  int get current => prices.last;
  int get previous => prices.length > 1 ? prices[prices.length - 2] : current;
  
  void update(price)
  {
    prices.add(price);
  }
}

