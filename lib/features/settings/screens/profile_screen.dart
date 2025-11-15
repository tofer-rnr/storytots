// lib/features/settings/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/repositories/reading_activity_repository.dart';
import 'package:storytots/data/services/profile_stats_service.dart';
import 'package:storytots/data/repositories/game_activity_repository.dart';
import 'edit_profile_screen.dart';
import 'badges_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<_ProfileData> _future;
  final _activityRepo = ReadingActivityRepository();
  LanguageStats? _today;
  ProfileStats? _stats;
  int _gameMin = 0;

  @override
  void initState() {
    super.initState();
    _future = _loadProfile();
  _loadActivity();
  _loadStats();
    GameActivityRepository().getTodayGameMinutes().then((v) {
      if (!mounted) return;
      setState(() => _gameMin = v);
    });
  }

  Future<_ProfileData> _loadProfile() async {
    final client = Supabase.instance.client;
    final user = client.auth.currentUser;
    if (user == null) throw Exception('Not signed in');

    final Map<String, dynamic>? row = await client
        .from('profiles')
        .select(
          'email, first_name, last_name, birth_date, avatar_key, interests',
        )
        .eq('id', user.id)
        .maybeSingle();

    final birthday = _parseDate(row?['birth_date']);
    final age = birthday == null ? '\u2014' : _ageFrom(birthday).toString();

    return _ProfileData(
      displayName: _nameFrom(row, user.email),
      email: (row?['email'] as String?) ?? (user.email ?? ''),
      birthday: birthday,
      ageLabel: age,
      avatarAsset: _avatarAssetFromKey(row?['avatar_key'] as String?),
      interests: (row?['interests'] is List)
          ? List<String>.from(row?['interests'] as List)
          : const <String>[],
    );
  }

  Future<void> _loadActivity() async {
    // Flush any pending reads first so DB view is fresh
    try { await _activityRepo.flushQueue(); } catch (_) {}
    final stats = await _activityRepo.getTodayLanguageStatsDbFirst();
    if (!mounted) return;
    setState(() => _today = stats);
  }

  Future<void> _loadStats() async {
    await _activityRepo.flushQueue();
    final s = await ProfileStatsService().getStatsDbFirst();
    if (!mounted) return;
    setState(() => _stats = s);
  }

  void _refresh() {
    setState(() => _future = _loadProfile());
    _loadActivity();
    _loadStats();
    GameActivityRepository().getTodayGameMinutes().then((v) {
      if (!mounted) return;
      setState(() => _gameMin = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(brandPurple);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        centerTitle: true,
        title: const Text(
          'storytots',
          style: TextStyle(
            fontFamily: 'Growback',
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: FutureBuilder<_ProfileData>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return _ErrorState(
              message: 'Error loading profile\n${snap.error}',
              onRetry: _refresh,
            );
          }
          final p = snap.data!;
          final stats = _stats; // may be null on first frame
          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/storytots_background.png',
                fit: BoxFit.cover,
              ),
              Container(color: Colors.white.withOpacity(0.94)),
              SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with avatar
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
                          margin: const EdgeInsets.only(left: 32),
                          decoration: BoxDecoration(
                            color: purple,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 10,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(width: 36),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              TextButton(
                                onPressed: () async {
                                  final changed = await Navigator.push<bool>(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => EditProfileScreen(
                                        currentInterests: p.interests,
                                        currentAvatarKeyOrPath: p.avatarAsset,
                                        currentBirthDate: p.birthday,
                                      ),
                                    ),
                                  );
                                  if (changed == true) _refresh();
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.white.withOpacity(
                                    .12,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
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
                        children: p.interests
                            .map((t) => _ghostChip(t))
                            .toList(),
                      ),

                    const SizedBox(height: 12),

                    // Language progress (today)
                    Row(
                      children: [
                        Expanded(
                          child: _pillStat(
                            'English (today)',
                            _fmtMinutes(_today?.englishMinutes ?? 0),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _pillStat(
                            'Filipino (today)',
                            _fmtMinutes(_today?.filipinoMinutes ?? 0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Reading Metrics summary
                    if (stats != null)
                      _metricsSummary(stats)
                    else
                      _skeletonMetrics(),

                    const SizedBox(height: 12),

                    // Weekly bars and EN/TL split
                    if (stats != null) _weeklySection(stats),

                    const SizedBox(height: 12),

                    // Activity Report (DB-first today percent)
                    _activityCard((_today?.activityPercent ?? 0.0)),
                    if ((_today?.totalMinutes ?? 0) == 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tip: Start a reading session to see today\'s stats update here.',
                        style: TextStyle(color: Colors.black54, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 12),

                    // Time Spent (reading today) + WPM
                    _timeSpent(
                      game: _gameMin,
                      reading: _today?.totalMinutes ?? 0,
                    ),
                    const SizedBox(height: 10),
                    if (_today != null) _wpmCard(_today!.wpm),

                    const SizedBox(height: 12),

                    _badgesCta(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const BadgesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricsSummary(ProfileStats s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'READING METRICS',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _miniStat(
                Icons.timer,
                'All-time',
                _fmtMinutes(s.totalMinutesAllTime),
              ),
              _miniStat(
                Icons.update,
                'Last 7 days',
                _fmtMinutes(s.totalMinutes7d),
              ),
              _miniStat(Icons.language, 'EN 7d', _fmtMinutes(s.enMinutes7d)),
              _miniStat(Icons.translate, 'TL 7d', _fmtMinutes(s.tlMinutes7d)),
              _miniStat(
                Icons.check_circle,
                'Completed',
                s.storiesCompleted.toString(),
              ),
              _miniStat(
                Icons.text_fields,
                'Sentences',
                s.sentencesPracticed.toString(),
              ),
              _miniStat(
                Icons.local_fire_department,
                'Streak',
                '${s.streakDays} days',
              ),
              _miniStat(
                Icons.access_time,
                'Last session',
                _fmtLast(s.lastSessionAt),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeletonMetrics() {
    return Container(
      height: 92,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const CircularProgressIndicator(strokeWidth: 3),
          const SizedBox(width: 12),
          Expanded(child: Container(height: 16, color: Colors.black12)),
        ],
      ),
    );
  }

  Widget _weeklySection(ProfileStats s) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LAST 7 DAYS',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 8),
          _weeklyBars(s.weekly),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _chipCard(
                  Icons.language,
                  'EN (7d)',
                  _fmtMinutes(s.enMinutes7d),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _chipCard(
                  Icons.translate,
                  'TL (7d)',
                  _fmtMinutes(s.tlMinutes7d),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _weeklyBars(List<DayStat> days) {
    final maxMin = days
        .map((d) => d.totalMinutes)
        .fold<int>(0, (a, b) => a > b ? a : b);
    final labels = const ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    return SizedBox(
      height: 110,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (int i = 0; i < days.length; i++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        width: 14,
                        height: maxMin == 0
                            ? 4
                            : (days[i].totalMinutes / maxMin) * 80 + 4,
                        decoration: BoxDecoration(
                          color: const Color(brandPurple),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    labels[i],
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            if (i != days.length - 1) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }

  static Widget _miniStat(IconData icon, String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 6),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  static String _fmtMinutes(int mins) {
    if (mins < 60) return '${mins}m';
    final h = mins ~/ 60;
    final m = mins % 60;
    return '${h}h ${m}m';
  }

  static String _fmtLast(DateTime? dt) {
    if (dt == null) return '—';
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  // --- helpers --------------------------------------------------------------

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

  static String _avatarAssetFromKey(String? key) {
    if (key == null || key.isEmpty) {
      return 'assets/images/avatar_placeholder.png';
    }
    // Allow storing full asset path in DB
    if (key.startsWith('assets/')) return key;
    switch (key) {
      case 'boy':
        return 'assets/images/boy.png';
      case 'girl':
        return 'assets/images/girl.png';
      case 'dog':
      case 'pup':
        return 'assets/images/dog.png';
      case 'cat':
      case 'owl':
        return 'assets/images/cat.png';
      case 'hamster':
      case 'bunny':
      case 'cub':
        return 'assets/images/hamster.png';
      case 'chimpmuck':
        return 'assets/images/chimpmuck.png';
      default:
        return 'assets/images/avatar_placeholder.png';
    }
  }

  static Widget _pill({required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static Widget _pillStat(String title, String value) {
    return Container(
      // Use flexible height to avoid overflow on some devices
      constraints: const BoxConstraints(minHeight: 84),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.language,
            color: const Color(brandPurple).withOpacity(0.9),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _activityCard(double percent) {
    final p = percent.clamp(0.0, 1.0).toDouble();
    return Container(
      height: 98,
      decoration: BoxDecoration(
        color: const Color(brandPurple),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          _CircleGauge(value: p, color: const Color(brandPurple)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'ACTIVITY\nREPORT',
              maxLines: 2,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _timeSpent({required int game, required int reading}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TIME SPENT',
            style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.5),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _chipCard(
                  Icons.videogame_asset_rounded,
                  'GAME',
                  _fmtMinutes(game),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _chipCard(
                  Icons.menu_book_rounded,
                  'READING',
                  _fmtMinutes(reading),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _badgesCta({required VoidCallback onTap}) {
    return SizedBox(
      height: 48,
      child: Material(
        color: const Color(brandPurple),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Text(
                  'Badges & Rewards',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Icon(Icons.chevron_right_rounded, color: Colors.white),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _chipCard(IconData icon, String title, String subtitle) {
    return Container(
      height: 70,
      decoration: BoxDecoration(
        color: const Color(brandPurple),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(width: 10),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(subtitle, style: const TextStyle(color: Colors.white70)),
            ],
          ),
        ],
      ),
    );
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

  static Widget _wpmCard(int wpm) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          const Icon(Icons.speed, color: Color(brandPurple)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Reading is fun! Your pace today',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          Text('$wpm WPM', style: const TextStyle(fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
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
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
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
    return Text(
      text,
      style: const TextStyle(letterSpacing: 3, fontWeight: FontWeight.w800),
    );
  }
}

class _CircleGauge extends StatelessWidget {
  const _CircleGauge({required this.value, required this.color});
  final double value; // 0..1
  final Color color;

  @override
  Widget build(BuildContext context) {
    const double size = 64;
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
            valueColor: AlwaysStoppedAnimation<Color>(
              Colors.black12.withOpacity(.08),
            ),
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
            child: Text(
              '$pct%',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.redAccent,
            size: 42,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Text(message, textAlign: TextAlign.center),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onRetry,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(brandPurple),
            ),
            child: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _ProfileData {
  _ProfileData({
    required this.displayName,
    required this.email,
    required this.birthday,
    required this.ageLabel,
    required this.avatarAsset,
    required this.interests,
  });

  final String displayName;
  final String email;
  final DateTime? birthday;
  final String ageLabel;
  final String avatarAsset;
  final List<String> interests;
}
