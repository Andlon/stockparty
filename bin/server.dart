import 'dart:io';
import 'dart:convert';
import 'dart:async';
import 'package:http_server/http_server.dart';
import 'package:route/server.dart';
import '../lib/stock.dart';
//import 'package:route/pattern.dart';

/* CONFIGURATION */
const PORT = 80;
const PERIOD = const Duration(seconds: 5);
const a = 0.02;
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

class StockExchange {
  List<Stock> stocks;
  Timer _timer;
  
  StockExchange(this.stocks) {
    _timer = new Timer(const Duration(seconds: 0), _handleTick);
  }
  
  void updateStocks() {
    for (Stock stock in stocks)
    {
      // Generate new price. If it drops below zero, generate another.
      int newPrice;
      do {
        //newPrice = stock.current + rnorm(mean: 0.0, std: a * stock.initial).round();
        newPrice = stock.current + rnorm(mean: a * (stock.initial - stock.current), std: a * stock.initial).round();
      } while (newPrice < 0);
      
      stock.current = newPrice;
    }
    
    onStocksUpdated();
  }
  
  void _handleTick() {
    updateStocks();
    _startTimer();
  }
  
  void _startTimer() {
    _timer = new Timer(PERIOD, _handleTick);
  }
  
  onStocksUpdated() { }
}

class WebSocketsExchange extends StockExchange {
  List<WebSocket> _sockets;
  
  WebSocketsExchange(var stocks) : super(stocks) {
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
  WebSocketsExchange exchange = new WebSocketsExchange(buildStocks());
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