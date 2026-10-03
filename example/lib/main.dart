import 'dart:async';

import 'package:flutter/material.dart';
import 'package:screenshot_detect/screenshot_detect.dart';

void main() => runApp(const ScreenshotApp());

class ScreenshotApp extends StatelessWidget {
  const ScreenshotApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      home: const ScreenshotPage(),
    );
  }
}

class ScreenshotPage extends StatefulWidget {
  const ScreenshotPage({super.key});

  @override
  State<ScreenshotPage> createState() => _ScreenshotPageState();
}

class _ScreenshotPageState extends State<ScreenshotPage> {
  final _detector = ScreenshotDetect();
  StreamSubscription<void>? _subscription;
  int _streamCount = 0;
  int _callbackCount = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _subscription = _detector.onScreenshot.listen(
      (_) => setState(() => _streamCount++),
      onError: (Object error) => setState(() => _error = error.toString()),
    );
    _detector.addListener(_onScreenshot);
  }

  void _onScreenshot() => setState(() => _callbackCount++);

  @override
  void dispose() {
    _detector.removeListener(_onScreenshot);
    unawaited(_subscription?.cancel());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Screenshot detection')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.screenshot, size: 72),
              const SizedBox(height: 24),
              Text(
                'Take a screenshot',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              const Text(
                'Use the device screenshot buttons. On Android 14+, the system '
                'will notify you that this app detected the screenshot.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Text('Stream events: $_streamCount'),
              Text('Callback events: $_callbackCount'),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.tonal(
                onPressed: () => setState(() {
                  _streamCount = 0;
                  _callbackCount = 0;
                }),
                child: const Text('Reset counters'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
