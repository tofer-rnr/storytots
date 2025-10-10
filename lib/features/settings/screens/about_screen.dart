import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('About'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/icon.png',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Text(
                  'StoryTots',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'RustyHooks',
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Version 1.0.0',
            style: TextStyle(color: Colors.black.withOpacity(0.6)),
          ),
          const SizedBox(height: 16),

          // About text
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Text(
              'StoryTots is a reading companion for kids. It features kid-friendly stories, karaoke-style reading, and gentle feedback to build confidence and fluency.',
              style: TextStyle(height: 1.4),
            ),
          ),
          const SizedBox(height: 12),

          // Features
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Highlights',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                _Bullet('Fun, beautifully illustrated stories'),
                _Bullet('Read-along karaoke-style guidance'),
                _Bullet('Kid-safe environment and simple controls'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Contact
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Contact',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text('Have feedback or need help? Email us at support@storytots.app'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      );
}

class _Bullet extends StatelessWidget {
  final String text;
  const _Bullet(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('• '),
            Expanded(child: Text(text)),
          ],
        ),
      );
}
