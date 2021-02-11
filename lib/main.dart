import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'DiscoveryPage.dart';
import 'SelectBondedDevicePage.dart';
import 'controller_pages/TerminalModePage.dart';

void main() {
  runApp(App());
}

class App extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  @override
  _MainPage createState() => new _MainPage();
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  String _address = "...";
  String _name = "...";

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  @override
  void initState() {
    print("super.initState:");
    super.initState();

    print("initState");
    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;

        // Discoverable mode is disabled when Bluetooth gets disabled
        _discoverableTimeoutTimer = null;
        _discoverableTimeoutSecondsLeft = 0;
      });
    });
  }

  @override
  void dispose() {
    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    // _collectingTask?.dispose();
    _discoverableTimeoutTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Controller'),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: InkWell(
              child: () {
                if (_bluetoothState == BluetoothState.STATE_OFF ||
                    _bluetoothState == BluetoothState.STATE_TURNING_OFF) {
                  return Icon(Icons.bluetooth_disabled, color: Colors.red);
                } else if (_bluetoothState == BluetoothState.STATE_ON ||
                    _bluetoothState == BluetoothState.STATE_TURNING_ON) {
                  return Icon(Icons.bluetooth, color: Colors.green);
                } else if (_bluetoothState == BluetoothState.ERROR ||
                    _bluetoothState == BluetoothState.UNKNOWN) {
                  return Icon(Icons.settings_bluetooth, color: Colors.grey);
                }
              }(),
              onTap: () {
                future() async {
                  // async lambda seems to not working
                  if (_bluetoothState.isEnabled)
                    await FlutterBluetoothSerial.instance.requestDisable();
                  else
                    await FlutterBluetoothSerial.instance.requestEnable();
                }

                future().then((_) {
                  setState(() {});
                });
              },
              onLongPress: FlutterBluetoothSerial.instance.openSettings,
            ),
          ),
          IconButton(
            icon: Icon(Icons.refresh, color: Colors.grey),
            onPressed: () async {
              print('Discoverable requested');
              final int timeout =
                  await FlutterBluetoothSerial.instance.requestDiscoverable(60);
              if (timeout < 0) {
                print('Discoverable mode denied');
              } else {
                print('Discoverable mode acquired for $timeout seconds');
              }
              setState(() {
                _discoverableTimeoutTimer?.cancel();
                _discoverableTimeoutSecondsLeft = timeout;
                _discoverableTimeoutTimer =
                    Timer.periodic(Duration(seconds: 1), (Timer timer) {
                  setState(() {
                    if (_discoverableTimeoutSecondsLeft < 0) {
                      FlutterBluetoothSerial.instance.isDiscoverable
                          .then((isDiscoverable) {
                        if (isDiscoverable) {
                          print(
                              "Discoverable after timeout... might be infinity timeout :F");
                          _discoverableTimeoutSecondsLeft += 1;
                        }
                      });
                      timer.cancel();
                      _discoverableTimeoutSecondsLeft = 0;
                    } else {
                      _discoverableTimeoutSecondsLeft -= 1;
                    }
                  });
                });
              });
            },
          )
        ],
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: RaisedButton(
                  child: const Text('Explore discovered devices'),
                  onPressed: () async {
                    final BluetoothDevice selectedDevice =
                        await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) {
                          return DiscoveryPage();
                        },
                      ),
                    );
                    if (selectedDevice != null) {
                      print('Discovery -> selected ' + selectedDevice.address);
                    } else {
                      print('Discovery -> no device selected');
                    }
                  }),
            ),
            ListTile(
              title: RaisedButton(
                child: const Text('Connect to paired device to chat'),
                onPressed: () async {
                  final BluetoothDevice selectedDevice =
                      await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) {
                        return SelectBondedDevicePage(checkAvailability: false);
                      },
                    ),
                  );
                  if (selectedDevice != null) {
                    print('Connect -> selected ' + selectedDevice.address);
                    _startCommunicationMode(context, selectedDevice);
                  } else {
                    print('Connect -> no device selected');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _startCommunicationMode(BuildContext context, BluetoothDevice server) {
    // Show dialog which asks which type of mode to enter
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return TerminalModePage(server: server);
        },
      ),
    );
  }
}
