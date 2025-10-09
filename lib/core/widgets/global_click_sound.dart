import 'dart:ui' show Offset;

import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import '../services/sound_service.dart';

/// A top-level widget that plays a click sound for quick tap gestures
/// anywhere in the app, without interfering with gesture handling.
class GlobalClickSound extends StatefulWidget {
  final Widget child;
  const GlobalClickSound({super.key, required this.child});

  @override
  State<GlobalClickSound> createState() => _GlobalClickSoundState();
}

class _GlobalClickSoundState extends State<GlobalClickSound> {
  final Map<int, _TapInfo> _downs = {};

  void _handle(PointerEvent e) {
    if (e is PointerDownEvent) {
      _downs[e.pointer] = _TapInfo(e.position, e.timeStamp);
    } else if (e is PointerUpEvent) {
      final info = _downs.remove(e.pointer);
      if (info == null) return;
      final dt = e.timeStamp - info.time;
      final moved = (e.position - info.position).distance;
      // Treat as a tap if it's quick and didn't move much (avoids scrolls/drags)
      if (dt <= const Duration(milliseconds: 250) && moved <= 10) {
        SoundService.instance.playClick();
      }
    } else if (e is PointerCancelEvent) {
      _downs.remove(e.pointer);
    }
  }

  @override
  void initState() {
    super.initState();
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handle);
  }

  @override
  void dispose() {
    GestureBinding.instance.pointerRouter.removeGlobalRoute(_handle);
    _downs.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _TapInfo {
  final Offset position;
  final Duration time;
  _TapInfo(this.position, this.time);
}
