import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'TemplateModePage.dart';
import 'dart:typed_data';
import 'dart:convert';

TemplateModePage terminalModePage(BluetoothDevice server) {
  return TemplateModePage<MessageWrapper>(
    server: server,
    bodyBuilder: (BuildContext context, BluetoothConnectionInfo connectionInfo,
        StateSetter setState, MessageWrapper messageWrapper) {
      return Column(
        children: <Widget>[
          Flexible(
            child: ListView(
                padding: const EdgeInsets.all(12.0),
                controller: messageWrapper.scrollController,
                children: messageWrapper.messages.map((_message) {
                  return Row(
                    children: <Widget>[
                      Container(
                        child: Text(
                            (text) {
                              return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                            }(_message.text.trim()),
                            style: TextStyle(color: Colors.white)),
                        padding: EdgeInsets.all(12.0),
                        margin:
                            EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
                        width: 222.0,
                        decoration: BoxDecoration(
                            color: _message.id == 0
                                ? Colors.blueAccent
                                : Colors.grey,
                            borderRadius: BorderRadius.circular(7.0)),
                      ),
                    ],
                    mainAxisAlignment: _message.id == 0
                        ? MainAxisAlignment.end
                        : MainAxisAlignment.start,
                  );
                }).toList()),
          ),
          Row(
            children: <Widget>[
              Flexible(
                child: Container(
                  margin: const EdgeInsets.only(left: 16.0),
                  child: TextField(
                    style: const TextStyle(fontSize: 15.0),
                    controller: messageWrapper.textEditingController,
                    decoration: InputDecoration.collapsed(
                      hintText: connectionInfo.isConnected
                          ? 'Type your message...'
                          : 'Chat got disconnected',
                      hintStyle: const TextStyle(color: Colors.grey),
                    ),
                    enabled: connectionInfo.isConnected,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(8.0),
                child: IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: connectionInfo.isConnected
                        ? () {
                            String text = messageWrapper
                                .textEditingController.text
                                .trim();
                            messageWrapper.textEditingController.clear();

                            if (text.length > 0) {
                              try {
                                connectionInfo.connection.output
                                    .add(utf8.encode(text));
                                connectionInfo.connection.output.allSent
                                    .then((value) {
                                  setState(() => messageWrapper.messages
                                      .add(Message(0, text)));
                                  messageWrapper.scrollController.animateTo(
                                      messageWrapper.scrollController.position
                                          .maxScrollExtent,
                                      duration: Duration(milliseconds: 333),
                                      curve: Curves.easeOut);
                                });
                              } catch (e) {}
                            }
                          }
                        : null),
              ),
            ],
          )
        ],
      );
    },
    receiver:
        (Uint8List data, StateSetter setState, MessageWrapper messageWrapper) {
      // Allocate buffer for parsed data
      int backspacesCounter = 0;
      data.forEach((byte) {
        if (byte == 8 || byte == 127) {
          backspacesCounter++;
        }
      });
      Uint8List buffer = Uint8List(data.length - backspacesCounter);
      int bufferIndex = buffer.length;

      // Apply backspace control character
      backspacesCounter = 0;
      for (int i = data.length - 1; i >= 0; i--) {
        if (data[i] == 8 || data[i] == 127) {
          backspacesCounter++;
        } else {
          if (backspacesCounter > 0) {
            backspacesCounter--;
          } else {
            buffer[--bufferIndex] = data[i];
          }
        }
      }

      // Create message if there is new line character
      String dataString = String.fromCharCodes(buffer);
      int index = buffer.indexOf(13);
      if (~index != 0) {
        setState(() {
          messageWrapper.messages.add(
            Message(
              1,
              backspacesCounter > 0
                  ? messageWrapper.messageBuffer.substring(0,
                      messageWrapper.messageBuffer.length - backspacesCounter)
                  : messageWrapper.messageBuffer +
                      dataString.substring(0, index),
            ),
          );
          messageWrapper.messageBuffer = dataString.substring(index);
        });
      } else {
        messageWrapper.messageBuffer = (backspacesCounter > 0
            ? messageWrapper.messageBuffer.substring(
                0, messageWrapper.messageBuffer.length - backspacesCounter)
            : messageWrapper.messageBuffer + dataString);
      }
    },
    name: "Terminal",
    icon: Icons.keyboard,
    defaultValue: MessageWrapper(),
  );
}

class MessageWrapper {
  final textEditingController = new TextEditingController();
  final scrollController = new ScrollController();
  var messages = List<Message>();
  var messageBuffer = '';

  MessageWrapper();

  void dispose() {
    textEditingController.dispose();
    scrollController.dispose();
  }
}

class Message {
  int id;
  String text;
  Message(this.id, this.text);
}
