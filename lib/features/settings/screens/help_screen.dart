import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('Help & FAQs'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _Faq(
            q: 'How do I start reading a story?',
            a: 'From Home, tap any story cover. On the details page, tap Read to open the reader.',
          ),
          _Faq(
            q: 'How do I change the avatar?',
            a: 'Go to Settings > Profile > Edit, then choose an avatar and Save.',
          ),
          _Faq(
            q: 'Why is there no sound?',
            a: 'Please check your device volume and ensure microphone permissions are granted when prompted.',
          ),
          _Faq(
            q: 'How do I contact support?',
            a: 'Email support@storytots.app and we will get back to you soon.',
          ),
          SizedBox(height: 12),
          _ContactCard(),
        ],
      ),
    );
  }
}

class _Faq extends StatelessWidget {
  final String q;
  final String a;
  const _Faq({required this.q, required this.a});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            q,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(a),
        ],
      ),
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Need more help?',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          SizedBox(height: 8),
          Text('Email: support@storytots.app'),
          SizedBox(height: 4),
          Text('Version: 1.0.0'),
        ],
      ),
    );
  }
}
