import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'package:route/server.dart';
import '../lib/stock.dart';
//import 'package:route/pattern.dart';

/* CONFIGURATION */
const HISTORYFILE = '../history.json';
const PORT = 9090;
const PERIOD = const Duration(seconds: 5);
const ROUNDTO = 5;
const a = 0.02;
const b = a;
const STOCKS = const {
  "JGR": 200,
  "VDK": 150,
  "MCALN": 300,
  "LAPHR": 300,
  "SAMB": 200,
  "GINT": 250,
  "CKRM": 250,
  "BENR": 300
};

/* IMPLEMENTATION */

List<Stock> buildStocks() {
  List<Stock> stocks = new List();
  STOCKS.forEach((k, v) => stocks.add(new Stock(k, v)));
  return stocks;
}

num roundToMultipleOf(num x, num multipleOf)
{
  return (x / multipleOf).round() * multipleOf;
}

class StockStorage {
  Map<String, List<num>> _history;
  File _file;
   
  StockStorage(filepath) {
    _file = new File(filepath);
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
    _storage = new StockStorage(HISTORYFILE);
    stocks = _storage.createStocks();
    _startTimer(period: const Duration(seconds: 0));
  }
  
  void updateStocks() {
    for (Stock stock in stocks)
    {
      // Generate new price. If it drops below zero, generate another. Round to multiples of
      int newPrice;
      do {
        num change = rnorm(mean: b * (stock.initial - stock.current), std: a * stock.initial);
        newPrice = stock.current + roundToMultipleOf(change, ROUNDTO);
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
