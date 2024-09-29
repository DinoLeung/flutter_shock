import 'dart:async';
import 'dart:io';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

class CasioManager {
	// Singleton setup
	static final CasioManager _instance = CasioManager._();
	factory CasioManager() => _instance;
	CasioManager._() {
		FlutterBluePlus.setLogLevel(LogLevel.verbose, color: true);
		FlutterBluePlus.cancelWhenScanComplete(_scanResultsSubscription);
	}

	void dispose() {
		_adapterStateSubscription.cancel();
		_scanResultsSubscription.cancel();
		_isScanningSubscription.cancel();
		_watchConnectionStateSubscription?.cancel();
	}

	final String casioServiceUuid = "00001804-0000-1000-8000-00805f9b34fb";

	// Bluetooth Adapter state
	StreamSubscription<BluetoothAdapterState> get _adapterStateSubscription {
		void onData(BluetoothAdapterState state) async {
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
		return FlutterBluePlus.adapterState
				.listen(onData, onError: (e) => print(e));
	}

	// Scanning states
	bool _isScanningNow = false;
	bool get isScanningNow => _isScanningNow;
	Stream<bool> get isScanning => _isScanning.stream;

	StreamController<bool> get _isScanning {
		StreamController<bool> controller = StreamController<bool>();
		controller.addStream(FlutterBluePlus.isScanning);
		return controller;
	}

	StreamSubscription<bool> get _isScanningSubscription {
		void onData(bool isScanning) {
			_isScanningNow = isScanning;
		}
		return FlutterBluePlus.isScanning.listen(onData, onError: (e) => print(e));
	}

	StreamSubscription<List<ScanResult>> get _scanResultsSubscription {
		void onData(List<ScanResult> results) async {
			if (results.isNotEmpty) {
				await stopScanning();
				var watch = results.first.device;
				await connect(watch);
				_services = await discoverServices(watch);
			}
		}
		return FlutterBluePlus.onScanResults
				.listen(onData, onError: (e) => print(e));
	}
	
	// Connection States
	BluetoothDevice? _connectedWatch;
	BluetoothDevice? get connectedWatch => _connectedWatch;
	BluetoothConnectionState _connectionStateNow =
			BluetoothConnectionState.disconnected;
	BluetoothConnectionState get connectionStateNow => _connectionStateNow;
	bool get isConnectedNow =>
			_connectionStateNow == BluetoothConnectionState.connected;
	final StreamController<bool> _isConnectedController =
			StreamController<bool>.broadcast();
	Stream<bool> get isConnected => _isConnectedController.stream;
	StreamSubscription<BluetoothConnectionState>?
			_watchConnectionStateSubscription;
	void _watchConnectionStateOnData(BluetoothConnectionState state) {
		_connectionStateNow = state;
		_isConnectedController.add(state == BluetoothConnectionState.connected);
	}

	// Available services from watch, maybe we don't need to expose it publicly.
	List<BluetoothService>? _services;
	List<BluetoothService>? get services => _services;

	// The connection logic is in _scanResultsSubscription
	Future<void> scanAndConnect({timeout = const Duration(seconds: 15)}) =>
			FlutterBluePlus.startScan(
					timeout: timeout, withServices: [Guid(casioServiceUuid)]);

	Future<void> stopScanning() async => FlutterBluePlus.stopScan();

	Future<void> connect(BluetoothDevice watch) async {
		try {
			await watch.connect();
			_watchConnectionStateSubscription = watch.connectionState
					.listen(_watchConnectionStateOnData, onError: (e) => print(e));
			// _connectionStateController.addStream(watch.connectionState);
			_connectedWatch = watch;
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
