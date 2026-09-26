import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Platform channel name — must match `FlutterHostBridgeChannel.channelName` on iOS.
const String kHostBridgeChannel = 'com.ilkersevim.superDemoApp/host_bridge';

/// Method name on the channel; payload is JP-P0-C JSON (UTF-8 string).
const String kInvokeHostBridge = 'invoke';

void main() => runApp(const SuperDemoFlutterHostApp());

/// Portfolio Flutter add-to-app surface hosted inside `superDemoApp`.
class SuperDemoFlutterHostApp extends StatelessWidget {
  const SuperDemoFlutterHostApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'superDemo Flutter host',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0B3D2E)),
        useMaterial3: true,
      ),
      home: const HostBridgeDemoPage(),
    );
  }
}

class HostBridgeDemoPage extends StatefulWidget {
  const HostBridgeDemoPage({super.key});

  @override
  State<HostBridgeDemoPage> createState() => _HostBridgeDemoPageState();
}

class _HostBridgeDemoPageState extends State<HostBridgeDemoPage> {
  static const _channel = MethodChannel(kHostBridgeChannel);

  String _status = 'Tap to call native feed.cacheStatus via MethodChannel.';
  bool _busy = false;

  Future<void> _pingCacheStatus() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _status = 'Calling native host…';
    });

    final request = <String, Object?>{
      'v': 1,
      'method': 'feed.cacheStatus',
      'id': 'flutter-${DateTime.now().millisecondsSinceEpoch}',
    };
    final requestJson = jsonEncode(request);

    try {
      final raw = await _channel.invokeMethod<String>(
        kInvokeHostBridge,
        requestJson,
      );
      if (!mounted) return;
      setState(() {
        _status = raw ?? '<null response>';
        _busy = false;
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _status =
            'PlatformException code=${error.code} message=${error.message}\n'
            'details=${error.details}';
        _busy = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _status = 'Error: $error';
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Flutter → native host'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Portfolio demo',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'This Flutter module is embedded in superDemoApp and calls the '
              'JP-P0-C host-bridge method feed.cacheStatus over a MethodChannel.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: _busy ? null : _pingCacheStatus,
              child: Text(_busy ? 'Calling…' : 'Ping feed.cacheStatus'),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  border: Border.all(color: theme.dividerColor),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: SelectableText(
                    _status,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
