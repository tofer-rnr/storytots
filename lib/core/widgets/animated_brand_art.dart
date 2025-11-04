import 'dart:async';
import 'package:flutter/material.dart';

/// Animated brand art that cycles through StoryTots icon frames
/// Optimized to avoid flashing by precaching frames and using gapless playback.
class AnimatedBrandArt extends StatefulWidget {
  const AnimatedBrandArt({
    super.key,
    this.size = 100,
    this.withCard = false, // default no white card
    this.frameDuration = const Duration(milliseconds: 420),
    this.shadow = const [
      BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6)),
    ],
  });

  final double size;
  final bool withCard;
  final Duration frameDuration;
  final List<BoxShadow> shadow;

  @override
  State<AnimatedBrandArt> createState() => _AnimatedBrandArtState();
}

class _AnimatedBrandArtState extends State<AnimatedBrandArt> {
  final List<String> _frames = const [
    'assets/images/icon.png',
    'assets/images/icon1.png',
    'assets/images/icon2.png',
  ];

  int _frameIndex = 0;
  Timer? _timer;
  bool _precached = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Precache frames once to avoid flicker on first swaps
    if (!_precached) {
      Future.wait(
        _frames.map((p) => precacheImage(AssetImage(p), context)),
      ).then((_) {
        if (!mounted) return;
        setState(() => _precached = true);
        _startTimer();
      });
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(widget.frameDuration, (_) {
      if (!mounted) return;
      setState(() => _frameIndex = (_frameIndex + 1) % _frames.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final img = SizedBox(
      width: widget.size,
      height: widget.size,
      child: Image.asset(
        _frames[_frameIndex],
        fit: BoxFit.contain,
        gaplessPlayback: true, // keep previous frame while the new one loads
        filterQuality: FilterQuality.medium,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );

    if (!widget.withCard) return img;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: widget.shadow,
      ),
      child: img,
    );
  }
}
