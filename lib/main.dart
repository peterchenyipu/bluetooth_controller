import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'DiscoveryWidget.dart';
import 'SelectBondedDeviceWidget.dart';
import 'controller_pages/JoystickModePage.dart';
import 'controller_pages/SwitchModePage.dart';
import 'controller_pages/SliderModePage.dart';
import 'controller_pages/TerminalModePage.dart';
import 'controller_pages/TemplateModePage.dart';

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

  Timer _discoverableTimeoutTimer;
  int _discoverableTimeoutSecondsLeft = 0;

  @override
  void initState() {
    super.initState();
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
        ],
      ),
      body: Container(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: _discoverableTimeoutSecondsLeft == 0
                  ? const Text("Discoverable")
                  : Text(
                      "Discoverable for ${_discoverableTimeoutSecondsLeft}s"),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Checkbox(
                    value: _discoverableTimeoutSecondsLeft != 0,
                    onChanged: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: () async {
                      print('Discoverable requested');
                      final int timeout = await FlutterBluetoothSerial.instance
                          .requestDiscoverable(60);
                      if (timeout < 0) {
                        print('Discoverable mode denied');
                      } else {
                        print(
                            'Discoverable mode acquired for $timeout seconds');
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
            ),
            Divider(),
            SelectBondedDeviceWidget(checkAvailability: false),
            Divider(),
            DiscoveryWidget(start: false),
          ],
        ),
      ),
    );
  }
}

void startCommunicationMode(BuildContext context, BluetoothDevice server) {
  showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
            title: Text('Choose mode'),
            children: [
              joypadModePage,
              switchModePage,
              sliderModePage,
              terminalModePage
            ]
                .map<Widget>((TemplateModePage Function(BluetoothDevice) fn) =>
                    SimpleDialogItem(fn, server))
                .toList());
      });
}

class SimpleDialogItem extends StatelessWidget {
  const SimpleDialogItem(this.fn, this.server, {Key key}) : super(key: key);

  final TemplateModePage Function(BluetoothDevice) fn;
  final BluetoothDevice server;

  @override
  Widget build(BuildContext context) {
    TemplateModePage controllerPage = this.fn(server);
    return SimpleDialogOption(
      onPressed: () {
        Navigator.of(context).pop();
        Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => controllerPage));
      },
      child: Row(
        children: [
          Icon(controllerPage.icon),
          SizedBox(width: 20),
          Text(controllerPage.name, style: TextStyle(fontSize: 15))
        ],
        mainAxisAlignment: MainAxisAlignment.start,
      ),
    );
  }
}
