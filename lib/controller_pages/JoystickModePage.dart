import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:control_pad/control_pad.dart';

TemplateModePage<math.Point> joypadModePage(BluetoothDevice server) {
  double left_x = 0;
  double left_y = 0;
  double right_x = 0;
  double right_y = 0;
  bool laState = false;
  bool lbState = false;
  bool raState = false;
  bool rbState = false;
  bool midPushed = false;
  return TemplateModePage<math.Point>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, _) {
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      Timer.periodic(Duration(milliseconds: 50), (timer) {
        try {
          int buttons = 0;
          if (laState)
            buttons = buttons | 1;
          if (lbState)
            buttons = buttons | (1 << 1);
          if (raState)
            buttons = buttons | (1 << 2);
          if (rbState)
            buttons = buttons | (1 << 3);
          if (midPushed)
            buttons = buttons | (1 << 4);

          connectionInfo.connection.output.add(
              Uint8List.fromList([left_x.round() + 127, left_y.round() + 127,
                right_x.round() + 127, right_y.round() + 127, buttons, 1]));
          if (!connectionInfo.isConnected) {
            // reconnect
            
          }
        } catch (e) {

        }
      });
      return Center(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              margin: const EdgeInsets.all(15.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ButtonBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTapDown: (_) {
                              laState = true;
                            },
                            onTapCancel: () {
                              laState = false;
                            },
                            onTapUp: (_) {
                              laState = false;
                            },
                            child: AbsorbPointer(
                              child: ElevatedButton(
                                  onPressed: () {}, child: Text("LA")),
                            )),
                        GestureDetector(
                            onTapDown: (_) {
                              lbState = true;
                            },
                            onTapCancel: () {
                              lbState = false;
                            },
                            onTapUp: (_) {
                              lbState = false;
                            },
                            child: AbsorbPointer(
                              child: ElevatedButton(
                                  onPressed: () {}, child: Text("LB")),
                            ))
                      ],
                    ),
                    JoystickView(
                        onDirectionChanged:
                            (double degrees, double distanceFromCenter) {
                          degrees *= pi / 180; // convert to radians
                          double temp = distanceFromCenter * sqrt(2) * 127;
                          left_x = sin(degrees) * temp;
                          if (left_x < -127)
                            left_x = -127;
                          else if (left_x > 127) left_x = 127;
                          left_y = cos(degrees) * temp;
                          if (left_y < -127)
                            left_y = -127;
                          else if (left_y > 127) left_y = 127;
                        },
                        interval: Duration(milliseconds: 5),
                        showArrows: false,
                        size: 200)
                  ]),
            ),
            GestureDetector(
                onTapDown: (_) {
                  midPushed = true;
                },
                onTapCancel: () {
                  midPushed = false;
                },
                onTapUp: (_) {
                  midPushed = false;
                },
                child: AbsorbPointer(
                  child: ElevatedButton(
                      onPressed: () {}, child: Text("MID")),
                )),
            Container(
                margin: const EdgeInsets.all(15.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    ButtonBar(
                      alignment: MainAxisAlignment.end,
                      children: [
                        GestureDetector(
                            onTapDown: (_) {
                              raState = true;
                            },
                            onTapCancel: () {
                              raState = false;
                            },
                            onTapUp: (_) {
                              raState = false;
                            },
                            child: AbsorbPointer(
                              child: ElevatedButton(
                                  onPressed: () {}, child: Text("RA")),
                            )),
                        GestureDetector(
                            onTapDown: (_) {
                              rbState = true;
                            },
                            onTapCancel: () {
                              rbState = false;
                            },
                            onTapUp: (_) {
                              rbState = false;
                            },
                            child: AbsorbPointer(
                              child: ElevatedButton(
                                  onPressed: () {}, child: Text("RB")),
                            ))
                      ],
                    ),
                    JoystickView(
                        onDirectionChanged:
                            (double degrees, double distanceFromCenter) {
                          degrees *= pi / 180; // convert to radians
                          double temp = distanceFromCenter * sqrt(2) * 127;
                          right_x = sin(degrees) * temp;
                          if (right_x < -127)
                            right_x = -127;
                          else if (right_x > 127) right_x = 127;
                          right_y = cos(degrees) * temp;
                          if (right_y < -127)
                            right_y = -127;
                          else if (right_y > 127) right_y = 127;
                        },
                        interval: Duration(milliseconds: 5),
                        showArrows: false,
                        size: 200)
                  ],
                )),
          ],
        )
        // Row (
        //   mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        //   children: [
        //     JoystickView(
        //         onDirectionChanged: (double degrees, double distanceFromCenter) {
        //           degrees *= pi / 180; // convert to radians
        //           double temp = distanceFromCenter * sqrt(2) * 127;
        //           left_x = sin(degrees) * temp;
        //           if (left_x < -128)
        //             left_x = -128;
        //           else if (left_x > 127)
        //             left_x = 127;
        //           left_y = cos(degrees) * temp;
        //           if (left_y < -128)
        //             left_y = -128;
        //           else if (left_y > 127)
        //             left_y = 127;
        //         },
        //         interval: Duration(milliseconds: 5),
        //         showArrows: false,
        //         size: 150),
        //     JoystickView(
        //         onDirectionChanged: (double degrees, double distanceFromCenter) {
        //           degrees *= pi / 180; // convert to radians
        //           double temp = distanceFromCenter * sqrt(2) * 127;
        //           right_x = sin(degrees) * temp;
        //           if (right_x < -128)
        //             right_x = -128;
        //           else if (right_x > 127)
        //             right_x = 127;
        //           right_y = cos(degrees) * temp;
        //           if (right_y < -128)
        //             right_y = -128;
        //           else if (right_y > 127)
        //             right_y = 127;
        //         },
        //         interval: Duration(milliseconds: 10),
        //         showArrows: false,
        //         size: 150)],
        // )
      );
    },
    name: "Joystick",
    icon: Icons.radio_button_checked,
    defaultValue: null,
  );
}
