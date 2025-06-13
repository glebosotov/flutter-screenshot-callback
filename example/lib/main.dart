import 'dart:async';
import 'dart:developer';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:screenshot_detect/screenshot_detect.dart';

void main() {
  runApp(const ScreenshotApp());
}

/// Controller to handle screenshot detection and image capture
class ScreenshotController {
  final ScreenshotDetect _screenshotDetect = ScreenshotDetect();
  final GlobalKey repaintKey = GlobalKey();
  final ValueNotifier<Uint8List?> latestImage = ValueNotifier<Uint8List?>(null);
  StreamSubscription? _subscription;

  void init() {
    _screenshotDetect.addListener(_onScreenshot);
  }

  void dispose() {
    _screenshotDetect.dispose();
    _subscription?.cancel();
    latestImage.dispose();
  }

  void _onScreenshot() {
    _captureScreenshot();
  }

  Future<void> _captureScreenshot() async {
    try {
      final context = repaintKey.currentContext;
      if (context == null || !context.mounted) return;
      final boundary = context.findRenderObject() as RenderRepaintBoundary?;
      if (boundary == null) return;
      final image = await boundary.toImage();
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      latestImage.value = byteData.buffer.asUint8List();
    } catch (e) {
      log(e.toString());
    }
  }

  void resetImage() {
    latestImage.value = null;
  }
}

class ScreenshotApp extends StatefulWidget {
  const ScreenshotApp({super.key});

  @override
  State<ScreenshotApp> createState() => _ScreenshotAppState();
}

class _ScreenshotAppState extends State<ScreenshotApp> {
  late final ScreenshotController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ScreenshotController();
    _controller.init();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        key: _controller.repaintKey,
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.indigoAccent,
            title: const Text('Screenshot callback demo'),
          ),
          body: ScreenshotDisplay(controller: _controller),
        ),
      ),
    );
  }
}

class ScreenshotDisplay extends StatelessWidget {
  final ScreenshotController controller;
  const ScreenshotDisplay({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Center(
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black54, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
              height: 400,
              child: ValueListenableBuilder<Uint8List?>(
                valueListenable: controller.latestImage,
                builder: (context, image, _) {
                  if (image == null) {
                    return const Text(
                      "Take a screenshot and it will show up here",
                    );
                  }
                  return Image.memory(image);
                },
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: controller.resetImage,
          child: const Text(
            "Reset image",
            style: TextStyle(color: Colors.indigoAccent),
          ),
        ),
      ],
    );
  }
}
