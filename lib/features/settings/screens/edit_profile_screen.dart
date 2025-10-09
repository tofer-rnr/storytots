import 'package:flutter/material.dart';
import 'package:storytots/data/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.currentInterests,
    required this.currentAvatarKeyOrPath,
  });

  final List<String> currentInterests;
  // Can be an avatar key (e.g., 'boy') or full asset path (assets/images/boy.png)
  final String currentAvatarKeyOrPath;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _repo = ProfileRepository();

  // mirror onboarding options
  static const _topics = [
    'Fun & Adventure',
    'Arts',
    'Family & Friends',
    'Nature & Animals',
    'Fantasy',
    'P.E. & Health',
  ];

  static const _avatarKeys = <String, String>{
    'boy': 'assets/images/boy.png',
    'cat': 'assets/images/cat.png',
    'chimpmuck': 'assets/images/chimpmuck.png',
    'dog': 'assets/images/dog.png',
    'girl': 'assets/images/girl.png',
    'hamster': 'assets/images/hamster.png',
  };

  late Set<String> _selectedTopics;
  String? _selectedAvatarKey; // store the key (boy, cat, ...)

  @override
  void initState() {
    super.initState();
    _selectedTopics = widget.currentInterests.toSet();
    // Try to resolve key from current path
    _selectedAvatarKey = _avatarKeys.entries
        .firstWhere(
          (e) => widget.currentAvatarKeyOrPath.endsWith(e.value),
          orElse: () => const MapEntry('boy', 'assets/images/boy.png'),
        )
        .key;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Avatar',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _avatarKeys.entries.map((e) {
                final selected = _selectedAvatarKey == e.key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedAvatarKey = e.key),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: selected ? Colors.purple : Colors.grey.shade300,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Image.asset(e.value, width: 64, height: 64),
                        const SizedBox(height: 6),
                        Text(e.key),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 20),
            const Text(
              'Select Interests (max 3)',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _topics.map((t) {
                final selected = _selectedTopics.contains(t);
                return FilterChip(
                  label: Text(t),
                  selected: selected,
                  onSelected: (v) {
                    setState(() {
                      if (v) {
                        if (_selectedTopics.length < 3) {
                          _selectedTopics.add(t);
                        }
                      } else {
                        _selectedTopics.remove(t);
                      }
                    });
                  },
                );
              }).toList(),
            ),

            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: _save, child: const Text('Save')),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    try {
      if (_selectedAvatarKey != null) {
        await _repo.updateAvatar(_selectedAvatarKey!);
      }
      await _repo.updateInterests(_selectedTopics.toList());
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to save: $e')));
    }
  }
}
