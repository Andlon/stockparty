import 'dart:io';
import 'dart:convert';
import 'package:http_server/http_server.dart';
import 'package:route/server.dart';
import '../lib/stock.dart';
//import 'package:route/pattern.dart';

/* CONFIGURATION */
const PORT = 9090;
var STOCKS = const {
  "JGR": 200,
  "VDK": 150,
  
};

/* IMPLEMENTATION */

List<Stock> buildStocks() {
  List<Stock> stocks = new List();
  STOCKS.forEach((k, v) => stocks.add(new Stock(k, v)));
  return stocks;
}

class StockExchange {
  List<Stock> stocks;
  
  StockExchange(this.stocks);
}

class WebSocketsExchange extends StockExchange {
  List<WebSocket> _sockets;
  
  WebSocketsExchange(var stocks) : super(stocks);
  
  void handleConnection(WebSocket socket) {
    print("Got WS connection!");
    _sockets.add(socket);
    socket
      .map((string) => JSON.decode(string))
      .listen( (json) {
        // Don't really need to do anything here yet...
      }, 
      onDone: () { _sockets.remove(socket); });
  }
  
  void broadcastStocks() {
    for (WebSocket socket in _sockets)
    {
      Map json;
      json['stocks'] = stocks.map( (element) => element.toJson());
      socket.add(JSON.encode(json));
    }
  }
}

void main() { 
  WebSocketsExchange exchange = new WebSocketsExchange(buildStocks());
  var webPath = Platform.script.resolve('../web').toFilePath();
  
  HttpServer.bind('127.0.0.1', PORT).then((HttpServer server) {
    Router router = new Router(server);
    
    VirtualDirectory vd = new VirtualDirectory(webPath);
    vd.jailRoot = false;
    vd.allowDirectoryListing = true; // Disable this
    vd.directoryHandler = (dir, request) {
      var indexUri = new Uri.file(dir.path).resolve('stockparty.html');
      print(indexUri.toFilePath());  
      vd.serveFile(new File(indexUri.toFilePath()), request);
    };
    
    vd.serve(router.defaultStream);
    router.serve('/ws')
      .transform(new WebSocketTransformer())
        .listen(exchange.handleConnection);
    
    print("Web server running on port " + PORT.toString() + ".");
  });
  
  
}