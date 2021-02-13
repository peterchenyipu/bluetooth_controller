import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';
import 'dart:math';
import 'package:control_pad/control_pad.dart';

TemplateModePage<Point> joypadModePage(BluetoothDevice server) {
  return TemplateModePage<Point>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnection connection,
        StateSetter setState, _) {
      return JoystickView(
          onDirectionChanged: (double degrees, double distanceFromCenter) {
            degrees *= pi / 180; // convert to radians
            double temp = distanceFromCenter * 127;
            Point npoint = Point(sin(degrees) * temp, cos(degrees) * temp);
            try {
              connection.output.add(
                  Uint8List.fromList([npoint.x.toInt(), npoint.y.toInt()]));
            } catch (e) {}
          },
          interval: Duration(milliseconds: 150),
          showArrows: false,
          size: 300);
    },
    name: "Joystick",
    icon: Icons.radio_button_checked,
    defaultValue: null,
  );
}
