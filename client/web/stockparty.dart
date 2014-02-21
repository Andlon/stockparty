import 'package:angular/angular.dart';
import 'dart:async';
import '../lib/stock.dart';
import 'exchangeclient.dart';

const PERIOD = const Duration(seconds: 2);
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
  
  return stocks;
}

/* Implementation below */

@NgController(selector: '[stockexchange]', publishAs: 'exchange')
class StockExchangeController {
  List<Stock> stocks;
  Timer timer;
  ExchangeClient exchange;
  
  StockExchangeController() {
    stocks = buildStocks();
    exchange = new ExchangeClient();
    exchange.connect('ws://${Uri.base.host}:${Uri.base.port}/ws');
    exchange.onConnected.listen( (e) => print('Connected to Exchange.'));
    //startTimer();
  }
  
  void startTimer() {
    timer = new Timer(PERIOD, handleTick);
  }
  
  void handleTick() {
    updateStocks();
    notify();
    startTimer();
  }
  
  void updateStocks() {
    for (Stock stock in stocks)
    {
      // Generate new price. If it drops below zero, generate another.
      int newPrice;
      do {
        newPrice = stock.current + rnorm(mean: 0.0, std: a * stock.initial).round();
      } while (newPrice < 0);
      
      stock.current = newPrice;
    }
  }
  
  void notify() {
    // Do some animation or something here
  }
}

class StockExchangeModule extends Module {  
  StockExchangeModule()
  {
    type(StockExchangeController);
  }
}

