import 'dart:async';
import 'package:bluetooth_controller/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

import 'BluetoothDeviceListEntry.dart';

class SelectBondedDeviceWidget extends StatefulWidget {
  /// If true, on page start there is performed discovery upon the bonded devices.
  /// Then, if they are not avaliable, they would be disabled from the selection.
  final bool checkAvailability;

  const SelectBondedDeviceWidget({this.checkAvailability = true});

  @override
  _SelectBondedDeviceWidget createState() => new _SelectBondedDeviceWidget();
}

class _DeviceWithAvailability extends BluetoothDevice {
  BluetoothDevice device;
  bool availability;
  int rssi;

  _DeviceWithAvailability(this.device, this.availability, [this.rssi]);
}

class _SelectBondedDeviceWidget extends State<SelectBondedDeviceWidget> {
  List<_DeviceWithAvailability> devices = List<_DeviceWithAvailability>();

  // Availability
  StreamSubscription<BluetoothDiscoveryResult> _discoveryStreamSubscription;
  bool _isDiscovering;

  _SelectBondedDeviceWidget();

  @override
  void initState() {
    super.initState();

    _isDiscovering = widget.checkAvailability;

    if (_isDiscovering) {
      _startDiscovery();
    }

    // Setup a list of the bonded devices
    FlutterBluetoothSerial.instance
        .getBondedDevices()
        .then((List<BluetoothDevice> bondedDevices) {
      setState(() {
        devices = bondedDevices
            .map(
              (device) =>
                  _DeviceWithAvailability(device, !widget.checkAvailability),
            )
            .toList();
      });
    });
  }

  void _restartDiscovery() {
    setState(() {
      _isDiscovering = true;
    });

    _startDiscovery();
  }

  void _startDiscovery() {
    _discoveryStreamSubscription =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        Iterator i = devices.iterator;
        while (i.moveNext()) {
          var _device = i.current;
          if (_device.device == r.device) {
            _device.availability = true;
            _device.rssi = r.rssi;
          }
        }
      });
    });

    _discoveryStreamSubscription.onDone(() {
      setState(() {
        _isDiscovering = false;
      });
    });

    Future.delayed(Duration(seconds: 10), () {
      if (_isDiscovering) {
        _discoveryStreamSubscription.cancel();
        setState(() {
          _isDiscovering = false;
        });
      }
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and cancel discovery
    _discoveryStreamSubscription?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
            ListTile(
              title: Text('Select Device'),
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
            )
          ] +
          (devices.isNotEmpty
              ? devices
                  .map((_DeviceWithAvailability _device) =>
                      BluetoothDeviceListEntry(
                        device: _device.device,
                        rssi: _device.rssi,
                        enabled: _device.availability == true,
                        onTap: () {
                          startCommunicationMode(context, _device.device);
                        },
                      ))
                  .toList()
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
  // @override
  // Widget build(BuildContext context) {
  //   List<BluetoothDeviceListEntry> list = devices
  //       .map((_device) => BluetoothDeviceListEntry(
  //             device: _device.device,
  //             rssi: _device.rssi,
  //             enabled: _device.availability == _DeviceAvailability.yes,
  //             onTap: () {
  //               Navigator.of(context).pop(_device.device);
  //             },
  //           ))
  //       .toList();
  //   return Scaffold(
  //     appBar: AppBar(
  //       title: Text('Select device'),
  //       actions: <Widget>[
  //         _isDiscovering
  //             ? FittedBox(
  //                 child: Container(
  //                   margin: new EdgeInsets.all(16.0),
  //                   child: CircularProgressIndicator(
  //                     valueColor: AlwaysStoppedAnimation<Color>(
  //                       Colors.white,
  //                     ),
  //                   ),
  //                 ),
  //               )
  //             : IconButton(
  //                 icon: Icon(Icons.replay),
  //                 onPressed: _restartDiscovery,
  //               )
  //       ],
  //     ),
  //     body: ListView(children: list),
  //   );
  // }
}
