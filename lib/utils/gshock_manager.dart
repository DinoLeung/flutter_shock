import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_shock/utils/connection.dart';

class GShockManager {
  // Singleton
  static final GShockManager _instance = GShockManager._();
  factory GShockManager() => _instance;
  GShockManager._() {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);

    connection = Connection();
  }

  void dispose() {
    connection.dispose();
  }

  late Connection connection;

  Future<void> connect() => connection.scanAndConnect();

  Future<void> disconnect() => connection.disconnect();

  // Future<void> discoverServices() async {
  //   connection.connectedWatch.discoverServices()
  // }

}
