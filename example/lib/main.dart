import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:screenshot_detect/screenshot_detect.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ScreenshotDetect screenshotDetect = ScreenshotDetect();
  var screenshotKey = GlobalKey();
  Uint8List? latestImage;

  @override
  void initState() {
    super.initState();
    initScreenshotCallback();
  }

  @override
  void dispose() {
    screenshotDetect.dispose();
    super.dispose();
  }

  Future<void> initScreenshotCallback() async {
    screenshotDetect.addListener(() {
      screenshot();
    });
  }

  void screenshot() async {
    await Future.delayed(const Duration(milliseconds: 20), () async {
      RenderRepaintBoundary? boundary = screenshotKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary?;
      ui.Image image = await boundary!.toImage();

      ByteData? byteData =
          await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();
      setState(() {
        latestImage = pngBytes;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: screenshotKey,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.indigoAccent,
            title: const Text('Screenshot callback demo'),
          ),
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Padding(
                padding: const EdgeInsets.all(8),
                child: Center(
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                        border: Border.all(color: Colors.black54, width: 3),
                        borderRadius: BorderRadius.circular(20)),
                    height: 400,
                    child: latestImage == null
                        ? const Text(
                            "Take a screenshot and it will show up here")
                        : Image.memory(Uint8List.view(latestImage!.buffer)),
                  ),
                ),
              ),
              TextButton(
                  onPressed: () => setState(() {
                        latestImage = null;
                      }),
                  child: const Text(
                    "Reset image",
                    style: TextStyle(color: Colors.indigoAccent),
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
