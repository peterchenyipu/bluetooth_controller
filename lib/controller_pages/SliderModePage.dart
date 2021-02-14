import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';

TemplateModePage<DoubleWrapper> sliderModePage(BluetoothDevice server) {
  return TemplateModePage<DoubleWrapper>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, DoubleWrapper sliderVal) {
      return Center(
        child: Column(
          children: [
            Text(
              sliderVal.val.toInt().toString(),
              style:
                  TextStyle(color: Theme.of(context).accentColor, fontSize: 40),
            ),
            Slider(
              value: sliderVal.val,
              onChanged: (double newVal) {
                try {
                  connectionInfo.connection.output
                      .add(Uint8List.fromList([newVal.toInt()]));
                  connectionInfo.connection.output.allSent
                      .then((_) => setState(() => sliderVal.val = newVal));
                } catch (e) {}
              },
              min: 0,
              max: 255,
              divisions: 255,
            ),
            SizedBox(height: 40)
          ],
          mainAxisSize: MainAxisSize.min,
        ),
      );
    },
    name: "Slider",
    icon: Icons.swap_horizontal_circle,
    defaultValue: DoubleWrapper(0),
  );
}

class DoubleWrapper {
  double val;
  DoubleWrapper(this.val);
}
