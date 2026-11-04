import 'dart:async';
import 'package:flutter/services.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';

class ShareIntentService {
  ShareIntentService._();
  static final ShareIntentService instance = ShareIntentService._();

  final _controller = StreamController<String>.broadcast();
  Stream<String> get stream => _controller.stream;

  String? _initialText;

  Future<void> init() async {
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      final text = files
          .where((f) => f.type == SharedMediaType.text)
          .map((f) => f.path)
          .join('\n');
      if (text.isNotEmpty) _initialText = text;
    });

    ReceiveSharingIntent.instance.getMediaStream().listen((files) {
      final text = files
          .where((f) => f.type == SharedMediaType.text)
          .map((f) => f.path)
          .join('\n');
      if (text.isNotEmpty) _controller.add(text);
    });
  }

  String? consumeInitialText() {
    final t = _initialText;
    _initialText = null;
    return t;
  }
}