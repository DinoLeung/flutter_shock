import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:flutter_shock/utils/gshock_manager.dart';

const CASIO_SERVICE_UUID = "00001804-0000-1000-8000-00805f9b34fb";

class ScanScreen extends StatefulWidget {
  const ScanScreen({Key? key}) : super(key: key);

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  BluetoothDevice? _watch = null;
  bool _isScanning = false;
  bool _isConnected = false;
  Map<String, List<int>> _characteristics = {};

  GShockManager manager = GShockManager();

  @override
  void initState() {
    super.initState();

    manager.connectedWatchStream.listen((watch) {
      _watch = watch;
      if (mounted) {
        setState(() {});
      }
    });

    manager.isScanningStream.listen((isScanning) {
      _isScanning = isScanning;
      if (mounted) {
        setState(() {});
      }
    });

    manager.connectionStateStream.listen((status) async {
      _isConnected = status == BluetoothConnectionState.connected;
      if (_isConnected && manager.connectedWatch != null) {
        var services = await manager.discoverServices(manager.connectedWatch!);
        services.forEach((service) {
          service.characteristics.forEach((c) async {
            if (c.properties.read) {
              List<int> value = await c.read();
              print("${c.characteristicUuid}: ${value}");
              _characteristics.addAll({c.characteristicUuid.toString(): value});
            }
          });
        });
      } else {
        _characteristics.clear();
      }
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    manager.dispose();
    super.dispose();
  }

  Future onScanPressed() async {
    await manager.scanAndConnect();

    if (mounted) {
      setState(() {});
    }
  }

  Future onDisconnectPressed() async {
    await manager.disconnect();

    if (mounted) {
      setState(() {});
    }
  }

  Future onStopPressed() async {
    try {
      await manager.stopScanning();
    } catch (e) {
      // Snackbar.show(ABC.b, prettyException("Stop Scan Error:", e), success: false);
    }
    if (mounted) {
      setState(() {});
    }
  }

  Widget buildScanButton(BuildContext context) {
    // if (FlutterBluePlus.isScanningNow) {
    if (_isScanning) {
      return FloatingActionButton(
        child: const Icon(Icons.stop),
        onPressed: onStopPressed,
        backgroundColor: Colors.red,
      );
    } else if (_isConnected) {
      return FloatingActionButton(
          child: const Text("DISCONNECT"),
          onPressed: onDisconnectPressed,
          backgroundColor: Colors.blue);
    } else {
      return FloatingActionButton(
          child: const Text("SCAN"), onPressed: onScanPressed);
    }
  }

  Widget buildBody(BuildContext context) {
    return Text("isScanning: ${_isScanning}, isConnected: ${_isConnected}");
  }

  Widget buildList(BuildContext context) {
    return ListView(
        children: _characteristics.keys
            .map((key) => Text("${key}: ${_characteristics[key]}"))
            .toList());
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      // key: Snackbar.snackBarKeyB,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Find Devices'),
        ),
        body: buildList(context),
        // body: RefreshIndicator(
        //   onRefresh: onRefresh,
        //   child: ListView(
        //     children: <Widget>[
        //       // ..._buildSystemDeviceTiles(context),
        //       // ..._buildScanResultTiles(context),
        //     ],
        //   ),
        // ),
        floatingActionButton: buildScanButton(context),
      ),
    );
  }
}
