import 'dart:html';
import 'dart:async';
import 'dart:convert';
import '../lib/stock.dart';

class ExchangeClient {
  WebSocket _socket;
  
  StreamController _onConnectedController;
  StreamController _onDisconnectedController;
  StreamController<List<Stock>> _onStocksReceivedController;
  
  Stream get onConnected => _onConnectedController.stream;
  Stream get onDisconnected => _onDisconnectedController.stream;
  Stream get onStocksReceived => _onStocksReceivedController.stream;
  
  ExchangeClient() {
    _onConnectedController = new StreamController();
    _onDisconnectedController = new StreamController();
    _onStocksReceivedController = new StreamController();
  }
  
  void connect(String uri) {
    _socket = new WebSocket(uri);
    _socket.onOpen.listen( (e) => _onConnectedController.add(e) );
    _socket.onMessage.listen( (e) => _handleMessage(JSON.decode(e.data)) );
    _socket.onClose.listen( (e) {
      _onDisconnectedController.add(e);
      // Immediately reconnect upon disconnection
      connect(uri);
    });
  }
  
  void _handleMessage(message) {
    List<Stock> stocks = message['stocks'].map( (e) => Stock.fromJson(e));
    _onStocksReceivedController.add(stocks);
  }
  
  
}