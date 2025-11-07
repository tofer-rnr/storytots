import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:storytots/data/repositories/profile_repository.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({
    super.key,
    required this.currentInterests,
    required this.currentAvatarKeyOrPath,
    this.currentBirthDate,
  });

  final List<String> currentInterests;
  // Can be an avatar key (e.g., 'boy') or full asset path (assets/images/boy.png)
  final String currentAvatarKeyOrPath;
  // New: provide current birth date for editing
  final DateTime? currentBirthDate;

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

  DateTime? _birthDate;
  final TextEditingController _ageController = TextEditingController();

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
    _birthDate = widget.currentBirthDate;
    // Initialize age text from birthdate if available
    if (_birthDate != null) {
      _ageController.text = _ageFrom(_birthDate!).toString();
    }
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
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
            const Text('Age', style: TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.cake),
                hintText: 'Enter age (2-18)',
              ),
              onChanged: _onAgeChanged,
            ),

            const SizedBox(height: 20),
            const Text(
              'Birthdate',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickBirthDate,
              child: InputDecorator(
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.cake_outlined),
                ),
                child: Text(
                  _birthDate == null
                      ? 'Select birthdate'
                      : _fmtDate(_birthDate!),
                ),
              ),
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

  void _onAgeChanged(String value) {
    final now = DateTime.now();
    final age = int.tryParse(value);
    if (age == null) return;
    // Keep within a reasonable child range
    if (age < 2 || age > 18) return;
    final baseMonth = _birthDate?.month ?? now.month;
    final baseDay = _birthDate?.day ?? now.day;
    final year = now.year - age;
    setState(() {
      _birthDate = _withSafeDay(year, baseMonth, baseDay);
    });
  }

  DateTime _withSafeDay(int year, int month, int day) {
    final lastDay = DateTime(year, month + 1, 0).day;
    final safeDay = day.clamp(1, lastDay);
    return DateTime(year, month, safeDay);
  }

  int _ageFrom(DateTime b) {
    final now = DateTime.now();
    int age = now.year - b.year;
    if (now.month < b.month || (now.month == b.month && now.day < b.day)) {
      age--;
    }
    return age;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 7, now.month, now.day);
    final first = DateTime(now.year - 18, 1, 1); // min age ~ 2-18 years range
    final last = DateTime(now.year - 2, 12, 31);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      setState(() {
        _birthDate = picked;
        _ageController.text = _ageFrom(picked).toString();
      });
    }
  }

  String _fmtDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  Future<void> _save() async {
    try {
      if (_selectedAvatarKey != null) {
        await _repo.updateAvatar(_selectedAvatarKey!);
      }
      await _repo.updateInterests(_selectedTopics.toList());
      if (_birthDate != null) {
        await _repo.updateBirthDate(_birthDate!);
      }
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
