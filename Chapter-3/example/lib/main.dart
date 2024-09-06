import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_native_example/flutter_native_example.dart' as flutter_native_example;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late List<flutter_native_example.UICommand> uiCommands;

  @override
  void initState() {
    super.initState();
    uiCommands = flutter_native_example.getUICommand();
  }

  @override
  Widget build(BuildContext context) {
    const textStyle = TextStyle(fontSize: 25);
    const spacerSmall = SizedBox(height: 10);

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Native Packages'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(10),
            child: Column(
              children: [
                const Text(
                  'This calls a native function through FFI that is shipped as source in the package. '
                  'The native code is built as part of the Flutter Runner build.',
                  style: textStyle,
                  textAlign: TextAlign.center,
                ),
                spacerSmall,
                ...uiCommands.map((command) {
                  return Text(
                    'UICommand[${command.data}] = (${command.data}, ${command.f})',
                    style: textStyle,
                    textAlign: TextAlign.center,
                  );
                }),
                spacerSmall,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
