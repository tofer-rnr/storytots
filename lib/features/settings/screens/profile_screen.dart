// lib/features/settings/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/core/constants.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _f;

  @override
  void initState() {
    super.initState();
    _f = _loadProfile();
  }

  Future<_ProfileData> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) {
      throw Exception('Not signed in.');
    }

    final Map<String, dynamic>? row = await client
        .from('profiles')
        .select('id, email, first_name, last_name, birth_date, avatar_key, interests')
        .eq('id', user.id)
        .maybeSingle();

    // If the row doesn't exist yet, return a safe skeleton
    if (row == null) {
      return _ProfileData(
        displayName: _nameFrom(null, user.email),
        email: user.email ?? '',
        birthday: null,
        ageLabel: '—',
        avatarAsset: 'assets/images/avatar_placeholder.png',
        interests: const [],
        englishProgress: 0.75,
        filipinoProgress: 0.75,
        activityProgress: 0.80,
        gameMinutes: 18,
        readingMinutes: 83,
      );
    }

    final birthday = _parseDate(row['birth_date']);
    final ageText = birthday != null ? _ageFrom(birthday).toString() : '—';

    return _ProfileData(
      displayName: _nameFrom(row, user.email),
      email: (row['email'] as String?) ?? (user.email ?? ''),
      birthday: birthday,
      ageLabel: ageText,
      avatarAsset: _avatarAssetFromKey(row['avatar_key'] as String?),
      interests: (row['interests'] is List)
          ? List<String>.from(row['interests'] as List)
          : const <String>[],
      // Static progress placeholders for now
      englishProgress: 0.75,
      filipinoProgress: 0.75,
      activityProgress: 0.80,
      gameMinutes: 18,
      readingMinutes: 83,
    );
  }

  // --- mappers / helpers -----------------------------------------------------

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is String && v.isNotEmpty) return DateTime.tryParse(v);
    return null;
  }

  static int _ageFrom(DateTime bd) {
    final now = DateTime.now();
    var age = now.year - bd.year;
    if (now.month < bd.month || (now.month == bd.month && now.day < bd.day)) {
      age--;
    }
    return age;
  }

  static String _nameFrom(Map<String, dynamic>? row, String? emailFallback) {
    final first = (row?['first_name'] as String?)?.trim();
    final last = (row?['last_name'] as String?)?.trim();
    if ((first ?? '').isNotEmpty || (last ?? '').isNotEmpty) {
      return [first, last].where((s) => (s ?? '').isNotEmpty).join(' ');
    }
    if ((emailFallback ?? '').isNotEmpty) {
      final at = emailFallback!.indexOf('@');
      return at > 0 ? emailFallback.substring(0, at) : emailFallback;
    }
    return 'User';
  }

  /// Unified avatar key mapping (matches HomeScreen and supports legacy keys).
  static String _avatarAssetFromKey(String? key) {
    switch (key) {
      case 'boy':
        return 'assets/images/boy.png';
      case 'girl':
        return 'assets/images/girl.png';

      // dog family (supports legacy)
      case 'dog':
      case 'pup':
        return 'assets/images/dog.png';

      // cat family (supports legacy)
      case 'cat':
      case 'owl':
        return 'assets/images/cat.png';

      // hamster family (supports legacy)
      case 'hamster':
      case 'bunny':
      case 'cub':
        return 'assets/images/hamster.png';

      // custom
      case 'chimpmuck':
        return 'assets/images/chimpmuck.png';

      default:
        return 'assets/images/avatar_placeholder.png';
    }
  }

  void _refresh() => setState(() => _f = _loadProfile());

  // --- UI --------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final purple = const Color(brandPurple);
    final deepPurple =
        HSLColor.fromColor(purple).withLightness(0.25).toColor();
    final lightPurple = purple.withOpacity(.08);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: Image.asset(
          'assets/images/storytots_logo_front.png',
          height: 22,
          fit: BoxFit.contain,
        ),
        actions: [
          IconButton(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          )
        ],
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/storytots_background.png',
              fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.94)),
          FutureBuilder<_ProfileData>(
            future: _f,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snap.hasError) {
                return _ErrorState(
                  message: 'Error loading profile:\n${snap.error}',
                  onRetry: _refresh,
                );
              }
              final p = snap.data!;
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with avatar overlap
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding:
                              const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          margin: const EdgeInsets.only(left: 32),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 10,
                                  offset: Offset(0, 6)),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 36), // space under avatar
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      p.displayName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      p.email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 6,
                                      children: [
                                        _pill(text: 'Age ${p.ageLabel}'),
                                        if (p.birthday != null)
                                          _pill(
                                              text:
                                                  'Birthday ${_fmtDate(p.birthday!)}'),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () => ScaffoldMessenger.of(
                                        context)
                                    .showSnackBar(const SnackBar(
                                        content: Text(
                                            'Edit profile coming soon'))),
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor:
                                      Colors.white.withOpacity(.12),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Edit'),
                              ),
                            ],
                          ),
                        ),
                        Positioned(
                          left: -4,
                          top: -14,
                          child: _Avatar(path: p.avatarAsset, size: 68),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Interests
                    const _SectionTitle('INTERESTS'),
                    const SizedBox(height: 8),
                    if (p.interests.isEmpty)
                      _ghostChip('—')
                    else
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: p.interests.map(_ghostChip).toList(),
                      ),

                    const SizedBox(height: 12),

                    // Languages progress
                    Row(
                      children: [
                        Expanded(
                          child: _GaugeCard(
                            title: 'English\nLanguage',
                            value: p.englishProgress,
                            bg: deepPurple,
                            fg: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _GaugeCard(
                            title: 'Filipino\nLanguage',
                            value: p.filipinoProgress,
                            bg: deepPurple,
                            fg: Colors.white,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Activity
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: const [
                          BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 6)),
                        ],
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('ACTIVITY',
                                    style: TextStyle(
                                        letterSpacing: 3,
                                        fontWeight: FontWeight.w800)),
                                SizedBox(height: 6),
                                Text('REPORT'),
                              ],
                            ),
                          ),
                          _CircleGauge(
                              value: p.activityProgress,
                              size: 76,
                              color: purple),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Time spent
                    const _SectionTitle('TIME SPENT'),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _TimeCard(
                            icon: Icons.videogame_asset_rounded,
                            label: 'GAME',
                            minutes: p.gameMinutes,
                            accent: lightPurple,
                            iconColor: purple,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _TimeCard(
                            icon: Icons.menu_book_rounded,
                            label: 'READING',
                            minutes: p.readingMinutes,
                            accent: lightPurple,
                            iconColor: purple,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Badges & Rewards CTA
                    SizedBox(
                      height: 48,
                      child: Material(
                        color: purple,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => ScaffoldMessenger.of(context)
                              .showSnackBar(const SnackBar(
                                  content:
                                      Text('Badges & Rewards coming soon'))),
                          borderRadius: BorderRadius.circular(12),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: const [
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 14),
                                child: Text('Badges & Rewards',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Padding(
                                padding:
                                    EdgeInsets.symmetric(horizontal: 12),
                                child: Icon(Icons.chevron_right_rounded,
                                    color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // --- tiny UI helpers -------------------------------------------------------

  static Widget _pill({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child:
          Text(text, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  static String _fmtDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  static Widget _ghostChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.04),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
    );
  }
}

// ---- Models & components ----------------------------------------------------

class _ProfileData {
  _ProfileData({
    required this.displayName,
    required this.email,
    required this.birthday,
    required this.ageLabel,
    required this.avatarAsset,
    required this.interests,
    required this.englishProgress,
    required this.filipinoProgress,
    required this.activityProgress,
    required this.gameMinutes,
    required this.readingMinutes,
  });

  final String displayName;
  final String email;
  final DateTime? birthday;
  final String ageLabel;
  final String avatarAsset;
  final List<String> interests;

  final double englishProgress;
  final double filipinoProgress;
  final double activityProgress;

  final int gameMinutes;
  final int readingMinutes;
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.path, this.size = 68});
  final String path;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4))
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          path,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: Colors.grey.shade200,
            child: const Icon(Icons.person, size: 32, color: Colors.black38),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800));
  }
}

class _GaugeCard extends StatelessWidget {
  const _GaugeCard({
    required this.title,
    required this.value,
    required this.bg,
    required this.fg,
  });

  final String title;
  final double value; // 0..1
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _CircleGauge(value: value, color: fg),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              maxLines: 2,
              style:
                  TextStyle(color: fg, fontWeight: FontWeight.w800, height: 1.1),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimeCard extends StatelessWidget {
  const _TimeCard({
    required this.icon,
    required this.label,
    required this.minutes,
    required this.accent,
    required this.iconColor,
  });

  final IconData icon;
  final String label;
  final int minutes;
  final Color accent;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final text = _formatMinutes(minutes);
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6))
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration:
                BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(label,
                  style: const TextStyle(
                      letterSpacing: 2.5, fontWeight: FontWeight.w800)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }

  static String _formatMinutes(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }
}

class _CircleGauge extends StatelessWidget {
  const _CircleGauge({required this.value, this.size = 64, required this.color});
  final double value; // 0..1
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).round();
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        fit: StackFit.expand,
        children: [
          CircularProgressIndicator(
            value: 1,
            strokeWidth: 8,
            valueColor:
                AlwaysStoppedAnimation<Color>(Colors.black12.withOpacity(.08)),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
            duration: const Duration(milliseconds: 900),
            curve: Curves.easeOutCubic,
            builder: (_, v, __) => CircularProgressIndicator(
              value: v,
              strokeWidth: 8,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              backgroundColor: Colors.transparent,
            ),
          ),
          Center(
            child: Text('$pct%',
                style: const TextStyle(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded,
            color: Colors.redAccent, size: 42),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(message, textAlign: TextAlign.center),
        ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onRetry,
          style: FilledButton.styleFrom(
              backgroundColor: const Color(brandPurple)),
          child: const Text('Try again'),
        ),
      ]),
    );
  }
}
