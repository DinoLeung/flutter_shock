import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class GShockManager {
  // Singleton
  static final GShockManager _instance = GShockManager._();
  factory GShockManager() => _instance;
  GShockManager._() {
    FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
    _initSubscriptions();
  }

  void dispose() {
    _adapterStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _watchConnectionStateSubscription?.cancel();

    _isScanningStreamController.close();
    _connectedWatchStreamController.close();
    _connectionStateStreamController.close();
  }

  final String gshockServiceUuid = "00001804-0000-1000-8000-00805f9b34fb";

  void _initSubscriptions() {
    _adapterStateSubscription = FlutterBluePlus.adapterState
        .listen(_onAdapterStateChange, onError: (e) => print(e));
        
    _scanResultsSubscription = FlutterBluePlus.onScanResults
        .listen(_onScanResultsChange, onError: (e) => print(e));
    FlutterBluePlus.cancelWhenScanComplete(_scanResultsSubscription);

    _isScanningStreamController.addStream(FlutterBluePlus.isScanning);
  }

  void _onAdapterStateChange(BluetoothAdapterState state) async {
    switch (state) {
      case BluetoothAdapterState.on:
        print("We good");
      case BluetoothAdapterState.off:
        if (Platform.isAndroid) await FlutterBluePlus.turnOn();
      case BluetoothAdapterState.unauthorized:
        print("BT permission deny");
      case BluetoothAdapterState.unavailable:
        print("BT hardware is not avilable");
      default:
        print("poop");
    }
  }

  void _onScanResultsChange(List<ScanResult> results) async {
    if (results.isNotEmpty) {
      await stopScanning();
      var watch = results.first.device;
      await connect(watch);
      // _services = await discoverServices(watch);
    }
  }

  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;

  // Scanning states
  final StreamController<bool> _isScanningStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningStreamController.stream;

  // Connected watch
  final StreamController<BluetoothDevice?> _connectedWatchStreamController =
      StreamController.broadcast();
  Stream<BluetoothDevice?> get connectedWatchStream =>
      _connectedWatchStreamController.stream;

  BluetoothDevice? _connectedWatch;
  BluetoothDevice? get connectedWatch => _connectedWatch;
  void _setConnectedWatch(BluetoothDevice? watch) {
    _connectedWatch = watch;
    _connectedWatchStreamController.add(watch);
  }

  // Connection States
  final StreamController<BluetoothConnectionState>
      _connectionStateStreamController =
      StreamController<BluetoothConnectionState>.broadcast();
  Stream<BluetoothConnectionState> get connectionStateStream =>
      _connectionStateStreamController.stream;

  BluetoothConnectionState _connectionState =
      BluetoothConnectionState.disconnected;
  BluetoothConnectionState get connectionState => _connectionState;
  bool get isConnected =>
      _connectionState == BluetoothConnectionState.connected;

  StreamSubscription<BluetoothConnectionState>?
      _watchConnectionStateSubscription;
  void _watchConnectionStateOnData(BluetoothConnectionState state) {
    _connectionState = state;
    _connectionStateStreamController.add(state);
    if (state == BluetoothConnectionState.disconnected) {
      disconnect();
    }
  }

  // The connection logic is in _scanResultsSubscription
  Future<void> scanAndConnect({timeout = const Duration(seconds: 15)}) =>
      FlutterBluePlus.startScan(
          timeout: timeout, withServices: [Guid(gshockServiceUuid)]);

  Future<void> stopScanning() async => FlutterBluePlus.stopScan();

  Future<void> connect(BluetoothDevice watch) async {
    try {
      await watch.connect();
      _watchConnectionStateSubscription = watch.connectionState
          .listen(_watchConnectionStateOnData, onError: (e) => print(e));
      _setConnectedWatch(watch);
    } catch (e) {
      print("Error while connecting: ${e.toString()}");
    }
  }

  Future<void> disconnect() async {
    await connectedWatch?.disconnect();
    _connectedWatch = null;
    _watchConnectionStateSubscription?.cancel();
  }

  Future<List<BluetoothService>> discoverServices(BluetoothDevice watch) =>
      watch.discoverServices();
}
