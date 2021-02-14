import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:control_pad/control_pad.dart';

TemplateModePage<math.Point> joypadModePage(BluetoothDevice server) {
  return TemplateModePage<math.Point>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, _) {
      return Center(
        child: JoystickView(
            onDirectionChanged: (double degrees, double distanceFromCenter) {
              degrees *= math.pi / 180; // convert to radians
              double temp = distanceFromCenter * 127;
              math.Point npoint = math.Point(
                  math.sin(degrees) * temp, math.cos(degrees) * temp);
              try {
                connectionInfo.connection.output.add(
                    Uint8List.fromList([npoint.x.toInt(), npoint.y.toInt()]));
              } catch (e) {}
            },
            interval: Duration(milliseconds: 150),
            showArrows: false,
            size: 300),
      );
    },
    name: "Joystick",
    icon: Icons.radio_button_checked,
    defaultValue: null,
  );
}
