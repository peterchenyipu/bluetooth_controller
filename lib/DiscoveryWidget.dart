import 'dart:async';
import 'package:bluetooth_controller/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'BluetoothDeviceListEntry.dart';

class DiscoveryWidget extends StatefulWidget {
  /// If true, discovery starts on page start, otherwise user must press action button.
  final bool start;

  const DiscoveryWidget({this.start = true});

  @override
  _DiscoveryWidget createState() => new _DiscoveryWidget();
}

class _DiscoveryWidget extends State<DiscoveryWidget> {
  StreamSubscription<BluetoothDiscoveryResult> _streamSubscription;
  List<BluetoothDiscoveryResult> results = List<BluetoothDiscoveryResult>();
  bool _isDiscovering;

  _DiscoveryWidget();

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.start;
    if (_isDiscovering) {
      _startDiscovery();
    }
  }

  void _restartDiscovery() {
    setState(() {
      results.clear();
      _isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _streamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        results.add(r);
      });
    });

    Future.delayed(Duration(seconds: 10), () {
      if (_isDiscovering) {
        _streamSubscription.cancel();
        setState(() {
          _isDiscovering = false;
        });
      }
    });

    _streamSubscription.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });
  }

  // @TODO . One day there should be `_pairDevice` on long tap on something... ;)

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _streamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
            ListTile(
              title: Text(_isDiscovering
                  ? 'Discovering devices'
                  : 'Discovered devices'),
              trailing: _isDiscovering
                  ? FittedBox(
                      child: Container(
                        margin: new EdgeInsets.all(16.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  : IconButton(
                      icon: Icon(Icons.replay),
                      onPressed: _restartDiscovery,
                    ),
            ),
          ] +
          (results.isNotEmpty
              ? results.map((BluetoothDiscoveryResult result) {
                  return BluetoothDeviceListEntry(
                    device: result.device,
                    rssi: result.rssi,
                    onTap: () {
                      startCommunicationMode(context, result.device);
                    },
                    onLongPress: () async {
                      try {
                        bool bonded = false;
                        if (result.device.isBonded) {
                          print('Unbonding from ${result.device.address}...');
                          await FlutterBluetoothSerial.instance
                              .removeDeviceBondWithAddress(
                                  result.device.address);
                          print(
                              'Unbonding from ${result.device.address} has succed');
                        } else {
                          print('Bonding with ${result.device.address}...');
                          bonded = await FlutterBluetoothSerial.instance
                              .bondDeviceAtAddress(result.device.address);
                          print(
                              'Bonding with ${result.device.address} has ${bonded ? 'succeeded' : 'failed'}.');
                        }
                        setState(() {
                          results[results.indexOf(result)] =
                              BluetoothDiscoveryResult(
                                  device: BluetoothDevice(
                                    name: result.device.name ?? '',
                                    address: result.device.address,
                                    type: result.device.type,
                                    bondState: bonded
                                        ? BluetoothBondState.bonded
                                        : BluetoothBondState.none,
                                  ),
                                  rssi: result.rssi);
                        });
                      } catch (ex) {
                        showDialog(
                          context: context,
                          builder: (BuildContext context) {
                            return AlertDialog(
                              title: const Text('Error occured while bonding'),
                              content: Text("${ex.toString()}"),
                              actions: <Widget>[
                                new FlatButton(
                                  child: new Text("Close"),
                                  onPressed: () {
                                    Navigator.of(context).pop();
                                  },
                                ),
                              ],
                            );
                          },
                        );
                      }
                    },
                  );
                }).toList()
              : [
                  ListTile(
                    title: Center(
                        child: Text(
                      'No devices found',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    )),
                  )
                ]),
    );
  }
}
