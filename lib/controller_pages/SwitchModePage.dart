import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';

TemplateModePage<bool> switchModePage(BluetoothDevice server) {
  return TemplateModePage<bool>(
    server: server,
    bodyBuilder:
        (_, BluetoothConnection connection, StateSetter setState, bool state) {
      bool isConnected = connection != null && connection.isConnected;
      return IconButton(
        icon: Icon(
          Icons.power_settings_new,
          color: state ? Colors.green : Colors.red,
        ),
        iconSize: 130,
        onPressed: isConnected
            ? () {
                try {
                  connection.output.add(Uint8List.fromList([!state ? 1 : 0]));
                  connection.output.allSent
                      .then((_) => setState(() => state = !state));
                } catch (e) {}
              }
            : null,
        splashColor: Colors.transparent,
      );
    },
    name: "Switch",
    icon: Icons.toggle_off,
    defaultValue: false,
  );
}
