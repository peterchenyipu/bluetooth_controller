import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';

TemplateModePage<BoolWrapper> switchModePage(BluetoothDevice server) {
  return TemplateModePage<BoolWrapper>(
    server: server,
    bodyBuilder: (_, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, BoolWrapper state) {
      return Center(
        child: IconButton(
          icon: Icon(
            Icons.power_settings_new,
            color: state.val ? Colors.green : Colors.red,
          ),
          iconSize: 130,
          onPressed: connectionInfo.isConnected
              ? () {
                  // try {
                  connectionInfo.connection.output
                      .add(Uint8List.fromList([!state.val ? 1 : 0]));
                  setState(() => state.val = !state.val);
                  // } catch (e) {
                  //   print(e);
                  // }
                }
              : null,
          splashColor: Colors.transparent,
        ),
      );
    },
    name: "Switch",
    icon: Icons.toggle_off,
    defaultValue: BoolWrapper(false),
  );
}

class BoolWrapper {
  bool val;
  BoolWrapper(this.val);
}
