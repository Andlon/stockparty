import 'package:angular/angular.dart';
import 'dart:async';
import '../lib/stock.dart';
import 'exchangeclient.dart';

// Bootstrap
main() => ngBootstrap(module: new StockExchangeModule());

/* Implementation below */

@NgController(selector: '[stockexchange]', publishAs: 'exchange')
class StockExchangeController {
  List<Stock> stocks;
  ExchangeClient exchange;
  
  StockExchangeController() {
    stocks = new List();
    exchange = new ExchangeClient();
    exchange.connect('ws://${Uri.base.host}:${Uri.base.port}/ws');
    exchange.onConnected.listen( (e) => print('Connected to Exchange.'));
    exchange.onStocksReceived.listen( (s) => this.stocks = s );
  }
}

class StockExchangeModule extends Module {  
  StockExchangeModule()
  {
    type(StockExchangeController);
  }
}

