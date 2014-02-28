import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'package:route/server.dart';
import '../lib/stock.dart';
import '../config.dart';

// Use a factor of the mean of the stock prices as the standard deviation
final DEV = B * STOCKS.values.reduce( (a, b) => a + b ) / STOCKS.length;

// Load history relative to configuration file
final Uri HISTORYURL = Platform.script.resolve("../config.dart").resolve(HISTORYFILE);

/* IMPLEMENTATION */

num roundToMultipleOf(num x, num multipleOf)
{
  return (x / multipleOf).round() * multipleOf;
}

num generatePrice(Stock stock) {
  num change = rnorm(mean: A * (stock.initial - stock.current), std: DEV);
  return stock.current + roundToMultipleOf(change, ROUNDTO);
}

List<Stock> buildStocks() {
  List<Stock> stocks = new List();
  STOCKS.forEach((k, v) => stocks.add(new Stock(k, v)));
  return stocks;
}

class StockStorage {
  Map<String, List<num>> _history;
  File _file;
   
  StockStorage(uri) {
    _file = new File.fromUri(uri);
    _history = new Map();
      
    if (_file.existsSync()) {
      _parseFile();
    }
  }
  
  void _parseFile() {
    String content = _file.readAsStringSync();
    _history = JSON.decode(content);
  }
  
  List<Stock> createStocks() {
    List<Stock> stocks = new List();
    if (_history.isEmpty) {
      stocks = buildStocks();
    }
    else
    {
      _history.forEach( (K, V) {
        stocks.add(new Stock.fromHistory(K, V.first, V.last));
      });
    }
    
    return stocks;
  }  
  
  void synchronize() {
    _file.writeAsStringSync(JSON.encode(_history), mode: FileMode.WRITE, flush: true);
  }
  
  void store(List<Stock> stocks) {
    stocks.forEach( (e) {
      List<num> prices = _history.putIfAbsent(e.name, () => new List() );
      prices.add(e.current);
    });
  }
}

class StockExchange {
  List<Stock> stocks;
  Timer _timer;
  StockStorage _storage;
  
  StockExchange() {
    _storage = new StockStorage(HISTORYURL);
    stocks = _storage.createStocks();
    synchronize();
    scheduleMicrotask(onStocksUpdated);
    _startTimer();
  }
  
  void updateStocks() {
    for (Stock stock in stocks)
    {
      // Generate new price. If it drops below zero, generate another. Round to multiples of
      int newPrice;
      do {
        newPrice = generatePrice(stock);
      } while (newPrice < 0);
      
      stock.current = newPrice;
    }
    
    synchronize();
    onStocksUpdated();
  }
  
  void synchronize() {
    _storage.store(stocks);
    _storage.synchronize();
  }
  
  void _handleTick() {
    updateStocks();
    _startTimer();
  }
  
  void _startTimer({ period: PERIOD }) {
    _timer = new Timer(period, _handleTick);
  }
  
  onStocksUpdated() { }
}

class WebSocketsExchange extends StockExchange {
  List<WebSocket> _sockets;
  
  WebSocketsExchange() {
    _sockets = new List();
  }
  
  void handleConnection(WebSocket socket) {
    _sockets.add(socket);
    print("Client connected. Number of clients: " + _sockets.length.toString());
    socket
      .map((string) => JSON.decode(string))
      .listen( (json) {
        // Don't really need to do anything here yet...
      }, 
      onDone: () => handleDisconnection(socket));
    
    sendStocks(socket);
  }
  
  void handleDisconnection(WebSocket socket) {
    _sockets.remove(socket);
    print("Client disconnected. Number of clients: " + _sockets.length.toString());
  }
  
  void broadcastStocks() {
    for (WebSocket socket in _sockets)
    {
      sendStocks(socket);
    }
  }
  
  void sendStocks(WebSocket socket)
  {
    Map json = new Map<String, dynamic>();
    json['stocks'] = stocks.map( (element) => element.toJson()).toList();
    socket.add(JSON.encode(json));
  }
  
  onStocksUpdated() {
    broadcastStocks();
  }
}

void main() { 
  WebSocketsExchange exchange = new WebSocketsExchange();
  var webPath = Platform.script.resolve('../web').toFilePath();
  
  HttpServer.bind(InternetAddress.ANY_IP_V4, PORT).then((HttpServer server) {
    Router router = new Router(server);
    
    VirtualDirectory vd = new VirtualDirectory(webPath);
    vd.jailRoot = false;
    vd.allowDirectoryListing = true; // Disable this
    vd.directoryHandler = (dir, request) {
      var indexUri = new Uri.file(dir.path).resolve('stockparty.html');  
      vd.serveFile(new File(indexUri.toFilePath()), request);
    };
    
    vd.serve(router.defaultStream);
    router.serve('/ws')
      .transform(new WebSocketTransformer())
        .listen(exchange.handleConnection);
    
    print("Web server running on port " + PORT.toString() + ".");
  });
}
