import 'dart:typed_data';
import 'package:bluetooth_controller/controller_pages/TerminalModePage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';

class TemplateModePage<T> extends StatefulWidget {
  final BluetoothDevice server;
  final Widget Function(BuildContext, BluetoothConnection, StateSetter, T)
      bodyBuilder;
  final void Function(Uint8List, StateSetter, T) receiver;
  final String name;
  final IconData icon;
  final T defaultValue;

  const TemplateModePage({
    @required this.server,
    @required this.bodyBuilder,
    @required this.name,
    @required this.icon,
    @required this.defaultValue,
    this.receiver,
    key,
  }) : super(key: key);

  @override
  TemplateModePageState<T> createState() => new TemplateModePageState<T>();
}

class TemplateModePageState<T> extends State<TemplateModePage<T>> {
  var _scaffoldKey = new GlobalKey<ScaffoldState>();

  BluetoothConnection connection;
  String name;
  IconData icon;

  T data;

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  @override
  void initState() {
    data = widget.defaultValue;
    super.initState();

    try {
      BluetoothConnection.toAddress(widget.server.address).catchError((error) {
        SchedulerBinding.instance.addPostFrameCallback((_) {
          _showError("Unable to connect to ${widget.server.name}",
              _scaffoldKey.currentContext);
        });
      }).then((_connection) {
        print('Connected to the device');
        connection = _connection;
        SchedulerBinding.instance.addPostFrameCallback((timeStamp) {
          setState(() {
            isConnecting = false;
            isDisconnecting = false;
          });
        });

        if (widget.receiver != null) {
          connection.input
              .listen(
                  (Uint8List _data) => widget.receiver(_data, setState, data))
              .onDone(() {
            if (isDisconnecting) {
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
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    if (T == MessageWrapper) (data as MessageWrapper).dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
            title: (isConnecting
                ? Text('Connecting to ' + widget.server.name)
                : Text(widget.server.name))),
        body: SafeArea(
            child: isConnecting
                ? Center(child: CircularProgressIndicator())
                : () {
                    if (isConnected)
                      return widget.bodyBuilder(
                          context, connection, setState, data);
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
