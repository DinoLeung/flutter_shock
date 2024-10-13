import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_shock/utils/constants.dart';

class Connection {
  Connection() {
    _adapterStateSubscription = FlutterBluePlus.adapterState
        .listen(_onAdapterStateChange, onError: (e) => print(e));

    _scanResultsSubscription = FlutterBluePlus.onScanResults
        .listen(_onScanResultsChange, onError: (e) => print(e));
    // FlutterBluePlus.cancelWhenScanComplete(_scanResultsSubscription);

    _isScanningStreamController.addStream(FlutterBluePlus.isScanning);
  }

  void dispose() {
    _adapterStateSubscription.cancel();
    _scanResultsSubscription.cancel();
    _watchConnectionStateSubscription?.cancel();

    _isScanningStreamController.close();
    _connectedWatchStreamController.close();
    _watchServicesStreamController.close();
    _connectionStateStreamController.close();
  }

  late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
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

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  void _onScanResultsChange(List<ScanResult> results) async {
    if (results.isNotEmpty) {
      await stopScanning();
      var watch = results.first.device;
      await connect(watch);
    }
  }

  // Scanning states
  final StreamController<bool> _isScanningStreamController =
      StreamController<bool>.broadcast();
  Stream<bool> get isScanningStream => _isScanningStreamController.stream;

  // Connected watch
  final StreamController<BluetoothDevice?> _connectedWatchStreamController =
      StreamController.broadcast();
  Stream<BluetoothDevice?> get connectedWatchStream =>
      _connectedWatchStreamController.stream;

  final StreamController<List<BluetoothService>>
      _watchServicesStreamController = StreamController.broadcast();
  Stream<List<BluetoothService>> get watchServicesStream =>
      _watchServicesStreamController.stream;

  BluetoothDevice? _connectedWatch;
  BluetoothDevice? get connectedWatch => _connectedWatch;
  void _setConnectedWatch(BluetoothDevice? watch) {
    _connectedWatch = watch;
    _connectedWatchStreamController.add(watch);
  }

  List<BluetoothService> get watchServices =>
      _connectedWatch?.servicesList ?? [];

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
          timeout: timeout, withServices: [casioServiceUUID]);

  Future<void> stopScanning() async => FlutterBluePlus.stopScan();

  Future<void> connect(BluetoothDevice watch) async {
    try {
      await watch.connect();
      await discoverServices(watch);
      _watchConnectionStateSubscription = watch.connectionState
          .listen(_watchConnectionStateOnData, onError: (e) => print(e));
      _setConnectedWatch(watch);
    } catch (e) {
      print("Error while connecting: ${e.toString()}");
    }
  }

  Future<void> disconnect() async {
    await _connectedWatch?.disconnect();
    _connectedWatch = null;
    // _watchConnectionStateSubscription?.cancel();
  }

  Future<List<BluetoothService>> discoverServices(BluetoothDevice watch) async {
    var services = await watch.discoverServices();

    services.forEach((s) {
      print("Service: ${s.uuid}");
      s.characteristics.forEach((c) {
        if (c.uuid == readCharacteristicUUID) {
          print("READ CHARACTERISTIC: $c");
        }
        if (c.uuid == writeCharacteristicUUID) {
          print("WRITE CHARACTERISTIC: $c");
        }
        // print("Characteristic: ${c.uuid} ${c.properties}");
      });
    });

    _watchServicesStreamController.add(watch.servicesList);
    return services;
  }

  // Future<void> getSettings(BluetoothDevice watch) async {
  //   watch.
  // }
}
