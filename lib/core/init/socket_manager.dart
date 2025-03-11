import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../constants/app_constants.dart';

class SocketManager {
  static SocketManager? _instance;
  static SocketManager get instance {
    _instance ??= SocketManager._init();
    return _instance!;
  }

  late final IO.Socket socket;

  SocketManager._init() {
    socket = IO.io(AppConstants.wsUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
  }

  void connect() {
    socket.connect();
  }

  void disconnect() {
    socket.disconnect();
  }

  void emit(String event, dynamic data) {
    socket.emit(event, data);
  }

  void on(String event, Function(dynamic) handler) {
    socket.on(event, handler);
  }
}