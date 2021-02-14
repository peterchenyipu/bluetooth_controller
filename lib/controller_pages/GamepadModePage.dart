import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:control_pad/control_pad.dart';

TemplateModePage<GamepadData> gamepadModePage(BluetoothDevice server) {
  const padSize = 200.0;
  return TemplateModePage<GamepadData>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, GamepadData data) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ButtonPad(
            size: padSize,
            onPressed: (Direction dir) {
              if (dir == Direction.up) {
                data.buttonUp = true;
              } else if (dir == Direction.right) {
                data.buttonRight = true;
              } else if (dir == Direction.left) {
                data.buttonLeft = true;
              } else if (dir == Direction.down) {
                data.buttonDown = true;
              }
              _sendData(connectionInfo, data);
            },
          ),
          JoystickView(
            size: padSize,
            onDirectionChanged: (double degrees, double distanceFromCenter) {
              data.setJoystickPos(degrees, distanceFromCenter);
              _sendData(connectionInfo, data);
            },
            interval: Duration(milliseconds: 150),
            showArrows: false,
          ),
        ],
      );
    },
    name: "Gamepad",
    icon: Icons.gamepad,
    defaultValue: GamepadData(),
    allowedOrientations: [
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight
    ],
  );
}

void _sendData(BluetoothConnectionInfo connectionInfo, GamepadData data) async {
  try {
    connectionInfo.connection.output.add(data.getBytes());
    connectionInfo.connection.output.allSent.then((_) {});
  } catch (e) {} finally {
    data.resetButtons();
  }
}

class ButtonPad extends StatelessWidget {
  final void Function(Direction) onPressed;
  final double size;
  ButtonPad({this.onPressed, this.size = 96});

  @override
  Widget build(BuildContext context) {
    const offset = -8.0;
    final iconSize = this.size / 3;
    final splashRadius = this.size / 5;
    return Container(
      decoration: BoxDecoration(shape: BoxShape.circle),
      height: this.size,
      width: this.size,
      child: Stack(
        children: [
          Positioned(
            top: offset,
            left: 0,
            right: 0,
            child: IconButton(
              onPressed: () => onPressed(Direction.up),
              icon: Icon(Icons.keyboard_arrow_up),
              iconSize: iconSize,
              splashRadius: splashRadius,
            ),
          ),
          Positioned(
            right: offset,
            top: 0,
            bottom: 0,
            child: IconButton(
              onPressed: () => onPressed(Direction.right),
              icon: Icon(Icons.keyboard_arrow_right),
              iconSize: iconSize,
              splashRadius: splashRadius,
            ),
          ),
          Positioned(
            left: offset,
            top: 0,
            bottom: 0,
            child: IconButton(
              onPressed: () => onPressed(Direction.left),
              icon: Icon(Icons.keyboard_arrow_left),
              iconSize: iconSize,
              splashRadius: splashRadius,
            ),
          ),
          Positioned(
            bottom: offset,
            left: 0,
            right: 0,
            child: IconButton(
              onPressed: () => onPressed(Direction.down),
              icon: Icon(Icons.keyboard_arrow_down),
              iconSize: iconSize,
              splashRadius: splashRadius,
            ),
          ),
        ],
      ),
    );
  }
}

enum Direction { up, right, left, down }

class GamepadData {
  bool buttonUp;
  bool buttonRight;
  bool buttonLeft;
  bool buttonDown;
  math.Point joystickPos;

  GamepadData() {
    this.resetButtons();
    joystickPos = math.Point(0, 0);
  }

  void setJoystickPos(double degrees, double distanceFromCenter) {
    double rad = degrees * math.pi / 180;
    joystickPos = math.Point(math.sin(rad) * distanceFromCenter * 127,
        math.cos(rad) * distanceFromCenter * 127);
  }

  int buttonToBytes() {
    int byte = 0;
    if (buttonUp) {
      byte = byte | 8;
    }
    if (buttonRight) {
      byte = byte | 4;
    }
    if (buttonLeft) {
      byte = byte | 2;
    }
    if (buttonDown) {
      byte = byte | 1;
    }
    return byte;
  }

  Uint8List getBytes() {
    return Uint8List.fromList([
      this.buttonToBytes(),
      this.joystickPos.x.toInt(),
      this.joystickPos.y.toInt()
    ]);
  }

  void resetButtons() {
    buttonUp = false;
    buttonRight = false;
    buttonLeft = false;
    buttonDown = false;
  }
}
