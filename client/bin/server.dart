import 'dart:io';
import 'package:http_server/http_server.dart';
import 'package:route/server.dart';
//import 'package:route/pattern.dart';

const PORT = 9090;

void handleRequest(HttpRequest request)
{
  
}

void main() {  
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
  });
}