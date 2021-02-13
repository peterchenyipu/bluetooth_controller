import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';

TemplateModePage<double> sliderModePage(BluetoothDevice server) {
  return TemplateModePage<double>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnection connection,
        StateSetter setState, double sliderVal) {
      return Column(
        children: [
          Text(
            sliderVal.toInt().toString(),
            style:
                TextStyle(color: Theme.of(context).accentColor, fontSize: 40),
          ),
          Slider(
            value: sliderVal,
            onChanged: (double newVal) {
              try {
                connection.output.add(Uint8List.fromList([newVal.toInt()]));
                connection.output.allSent
                    .then((_) => setState(() => sliderVal = newVal));
              } catch (e) {}
            },
            min: 0,
            max: 255,
            divisions: 255,
          ),
          SizedBox(height: 40)
        ],
        mainAxisSize: MainAxisSize.min,
      );
    },
    name: "Slider",
    icon: Icons.swap_horizontal_circle,
    defaultValue: 0,
  );
}
