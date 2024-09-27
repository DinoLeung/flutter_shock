import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CasioManager {
  // Singleton setup
  static final CasioManager _instance = CasioManager._();
  factory CasioManager() => _instance;
  CasioManager._() {
    _scanResultsSubscription = FlutterBluePlus.onScanResults
        .listen(_onScanResultOnData, onError: (e) => print(e));
    _isScanningSubscription = FlutterBluePlus.isScanning
        .listen(_isScanningOnData, onError: (e) => print(e));

    FlutterBluePlus.cancelWhenScanComplete(_scanResultsSubscription);
  }

  final String CASIO_SERVICE_UUID = "00001804-0000-1000-8000-00805f9b34fb";

  BluetoothDevice? _connectedWatch;
  bool get isConnected => _connectedWatch != null;

  // bool get isScanningNow => FlutterBluePlus.isScanningNow;
  bool _isScanning = false;

  late StreamSubscription<List<ScanResult>> _scanResultsSubscription;
  void _onScanResultOnData(List<ScanResult> results) {
    if (results.isNotEmpty) {
      FlutterBluePlus.stopScan();
      connect(results.first.device);
    }
  }

  late StreamSubscription<bool> _isScanningSubscription;
  void _isScanningOnData(bool isScanning) => _isScanning = isScanning;

  // late StreamSubscription<BluetoothConnectionState>
  //     _watchConnectionStateSubscription;
  // void watchConnectionStateOnData(BluetoothConnectionState state) {}

  // late StreamSubscription<BluetoothAdapterState> _adapterStateSubscription;
  // void _adapterStateOnData(BluetoothAdapterState state) {
  //   switch (state) {
  //     case BluetoothAdapterState.on:
  //       print("We good");
  //     default:
  //       print("poop");
  //   }
  // }

  // Future<BluetoothAdapterState> grantBluetoothPermissions() {
  //   TODO: Need to listen and handle different bluetooth adapter state
  //   await FlutterBluePlus.adapterState.listen((BluetoothAdapterState state) {});
  // }

  Future<void> startScanning({timeout = const Duration(seconds: 15)}) =>
      FlutterBluePlus.startScan(
          timeout: timeout, withServices: [Guid(CASIO_SERVICE_UUID)]);

  Future<void> stopScanning() async {
    await FlutterBluePlus.stopScan();
    _scanResultsSubscription.cancel();
    _isScanningSubscription.cancel();
    // Just incase the value is not updated immediately
    _isScanning = false;
  }

  Future<void> connect(BluetoothDevice watch) async {
    try {
      await watch.connect();
      _connectedWatch = watch;
    } catch (e) {}
  }

  Future<void> disconnect() async {
    if (isConnected) {
      await _connectedWatch!.disconnect();
      _connectedWatch = null;
    }
  }

  // void test() async {
  //   // let say bluetooth is enabled
  //   await FlutterBluePlus.adapterState
  //       .where((state) => state == BluetoothAdapterState.on)
  //       .first;

  //   var onScanDevicesStream = onScanDevices().listen((devices) {
  //     if (devices.isNotEmpty) {
  //       connect(devices.first);
  //     }
  //   });
  // }
}
