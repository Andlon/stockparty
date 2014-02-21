import 'dart:html';
import 'dart:async';

class ExchangeClient {
  WebSocket _socket;
  
  StreamController _onConnectedController;
  
  Stream get onConnected => _onConnectedController.stream;
  
  ExchangeClient() {
    _onConnectedController = new StreamController();
  }
  
  void connect(String uri) {
    _socket = new WebSocket(uri);
    _socket.onOpen.listen( (e) => _onConnectedController.add(e) );
  }
  
  
}