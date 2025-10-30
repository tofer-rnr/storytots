import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/core/services/background_music_service.dart';
import 'package:storytots/core/services/sound_service.dart';

class SoundSettingsScreen extends StatefulWidget {
  const SoundSettingsScreen({super.key});

  @override
  State<SoundSettingsScreen> createState() => _SoundSettingsScreenState();
}

class _SoundSettingsScreenState extends State<SoundSettingsScreen> {
  double _music = BackgroundMusicService.instance.currentVolume;
  double _sfx = SoundService.instance.currentSfxVolume;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(appBg),
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        elevation: 0,
        title: const Text(
          'SOUND',
          style: TextStyle(
            color: Colors.white,
            fontFamily: 'RustyHooks',
            letterSpacing: 3,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _CuteCard(
                title: 'Background Music',
                emoji: '🎵',
                color: const Color(0xFFB39DDB),
                child: Column(
                  children: [
                    _LabeledSlider(
                      value: _music,
                      onChanged: (v) async {
                        setState(() => _music = v);
                        await BackgroundMusicService.instance.setVolume(v);
                      },
                      onChangeEnd: (v) async {
                        if (v > 0 &&
                            !BackgroundMusicService.instance.isPlaying) {
                          await BackgroundMusicService.instance.start();
                        } else if (v == 0 &&
                            BackgroundMusicService.instance.isPlaying) {
                          await BackgroundMusicService.instance.pause();
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    _CuteToggle(
                      labelOn: 'Music ON',
                      labelOff: 'Music OFF',
                      isOn: _music > 0,
                      onChanged: (on) async {
                        if (on) {
                          setState(() => _music = _music == 0 ? 0.35 : _music);
                          await BackgroundMusicService.instance.setVolume(
                            _music,
                          );
                          await BackgroundMusicService.instance.start();
                        } else {
                          setState(() => _music = 0);
                          await BackgroundMusicService.instance.setVolume(0);
                          await BackgroundMusicService.instance.pause();
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _CuteCard(
                title: 'Pop Sound',
                emoji: '🔔',
                color: const Color(0xFFFFCC80),
                child: Column(
                  children: [
                    _LabeledSlider(
                      value: _sfx,
                      onChanged: (v) async {
                        setState(() => _sfx = v);
                        await SoundService.instance.setSfxVolume(v);
                      },
                      onChangeEnd: (v) async {
                        await SoundService.instance.playClick();
                      },
                    ),
                    const SizedBox(height: 8),
                    _CuteToggle(
                      labelOn: 'Pop ON',
                      labelOff: 'Pop OFF',
                      isOn: _sfx > 0,
                      onChanged: (on) async {
                        if (on) {
                          setState(() => _sfx = _sfx == 0 ? 0.7 : _sfx);
                          await SoundService.instance.setSfxVolume(_sfx);
                          await SoundService.instance.playClick();
                        } else {
                          setState(() => _sfx = 0);
                          await SoundService.instance.setSfxVolume(0);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(brandPurple),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 6,
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'DONE',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFamily: 'RustyHooks',
                      fontSize: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CuteCard extends StatelessWidget {
  final String title;
  final String emoji;
  final Color color;
  final Widget child;
  const _CuteCard({
    required this.title,
    required this.emoji,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: color, width: 2),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: const Color(brandPurple),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    fontFamily: 'RustyHooks',
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double>? onChangeEnd;
  const _LabeledSlider({
    required this.value,
    required this.onChanged,
    this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _CutePill(label: '0'),
        Expanded(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: const Color(brandPurple),
              inactiveTrackColor: const Color(0xFFE0E0E0),
              trackHeight: 8,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 14),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              thumbColor: const Color(brandPurple),
              overlayColor: const Color(brandPurple).withOpacity(0.2),
            ),
            child: Slider(
              value: value,
              min: 0,
              max: 1,
              divisions: 10,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
        ),
        const _CutePill(label: '10'),
      ],
    );
  }
}

class _CutePill extends StatelessWidget {
  final String label;
  const _CutePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(brandPurple),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.2,
          fontFamily: 'RustyHooks',
        ),
      ),
    );
  }
}

class _CuteToggle extends StatelessWidget {
  final String labelOn;
  final String labelOff;
  final bool isOn;
  final ValueChanged<bool> onChanged;
  const _CuteToggle({
    required this.labelOn,
    required this.labelOff,
    required this.isOn,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isOn ? const Color(0xFFB2DFDB) : const Color(0xFFFFCDD2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isOn ? labelOn : labelOff,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontFamily: 'RustyHooks',
                letterSpacing: 1.2,
                color: Color(brandPurple),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Switch(
          value: isOn,
          activeColor: const Color(brandPurple),
          onChanged: onChanged,
        ),
      ],
    );
  }
}
