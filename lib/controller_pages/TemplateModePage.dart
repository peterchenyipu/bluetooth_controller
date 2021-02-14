import 'dart:typed_data';
import 'package:bluetooth_controller/controller_pages/TerminalModePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TemplateModePage<T> extends StatefulWidget {
  final BluetoothDevice server;
  final Widget Function(BuildContext, BluetoothConnectionInfo, StateSetter, T)
      bodyBuilder;
  final void Function(Uint8List, StateSetter, T) receiver;
  final String name;
  final IconData icon;
  final T defaultValue;
  final List<DeviceOrientation> allowedOrientations;

  const TemplateModePage({
    @required this.server,
    @required this.bodyBuilder,
    @required this.name,
    @required this.icon,
    @required this.defaultValue,
    this.receiver,
    this.allowedOrientations = DeviceOrientation.values,
    key,
  }) : super(key: key);

  @override
  TemplateModePageState<T> createState() => new TemplateModePageState<T>();
}

class TemplateModePageState<T> extends State<TemplateModePage<T>> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  // BluetoothConnection connection;
  var connectionInfo = BluetoothConnectionInfo(null);
  String name;
  IconData icon;

  T data;

  // bool isConnecting = true;
  // bool get isConnected => connection != null && connection.isConnected;

  // bool isDisconnecting = false;

  @override
  void initState() {
    super.initState();

    SystemChrome.setPreferredOrientations(widget.allowedOrientations);

    data = widget.defaultValue;

    try {
      BluetoothConnection.toAddress(widget.server.address).catchError((error) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _showError("Unable to connect to ${widget.server.name}",
              _scaffoldKey.currentContext);
        });
      }).then((_connection) {
        print('Connected to the device');
        connectionInfo.connection = _connection;
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            connectionInfo.isConnecting = false;
            connectionInfo.isDisconnecting = false;
          });
        });

        if (widget.receiver != null) {
          connectionInfo.connection.input
              .listen(
                  (Uint8List _data) => widget.receiver(_data, setState, data))
              .onDone(() {
            if (connectionInfo.isDisconnecting) {
              print('Disconnecting locally!');
            } else {
              print('Disconnected remotely!');
            }
            if (this.mounted) {
              setState(() {});
            }
          });
        }
      });
    } on PlatformException {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        _showError("Unable to connect to ${widget.server.name}",
            _scaffoldKey.currentContext);
      });
    }
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);

    // Avoid memory leak (`setState` after dispose) and disconnect
    if (connectionInfo.isConnected) {
      connectionInfo.isDisconnecting = true;
      connectionInfo.connection.dispose();
      connectionInfo.connection = null;
    }

    if (T == MessageWrapper) (data as MessageWrapper).dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Widget body = widget.bodyBuilder(context, connectionInfo, setState, data);
    return WillPopScope(
      onWillPop: () async {
        return await showDialog<bool>(
            context: context,
            builder: (BuildContext context) => AlertDialog(
                  title: Text("Are you sure you want to exit?"),
                  // content: Text(
                  //     "Exiting will disconnect from ${widget.server.name}"),
                  contentPadding: EdgeInsets.zero,
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: Text("No")),
                    TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child:
                            Text("Yes", style: TextStyle(color: Colors.red))),
                  ],
                ));
      },
      child: Scaffold(
        key: _scaffoldKey,
        appBar: AppBar(
            toolbarHeight: 45,
            title: (connectionInfo.isConnecting
                ? Text('Connecting to ' + widget.server.name)
                : Text(widget.server.name))),
        body: SafeArea(
            child: connectionInfo.isConnecting
                ? Center(child: CircularProgressIndicator())
                : () {
                    if (connectionInfo.isConnected)
                      return body;
                    else {
                      _showError(
                          "Lost connection to ${widget.server.name}", context);
                      return Container();
                    }
                  }()),
      ),
    );
  }

  void _showError(String message, BuildContext context) {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(message),
            contentPadding: EdgeInsets.zero,
            actions: [
              TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(false);
                    Navigator.of(context).pop(false);
                  },
                  child: Text(
                    'Ok',
                    style: TextStyle(color: Colors.red),
                  ))
            ],
          );
        });
  }
}

class BluetoothConnectionInfo {
  BluetoothConnection connection;
  bool get isConnected => connection != null && connection.isConnected;
  bool isConnecting;
  bool isDisconnecting;

  BluetoothConnectionInfo(
    this.connection, {
    this.isConnecting = true,
    this.isDisconnecting = false,
  });
}
