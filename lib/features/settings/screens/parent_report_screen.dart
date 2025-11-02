import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/repositories/assessment_repository.dart';
import 'package:storytots/data/repositories/auth_cache_repository.dart';
import 'package:storytots/data/repositories/role_mode_repository.dart';
import 'package:storytots/data/repositories/difficult_words_repository.dart';
import 'package:storytots/data/repositories/library_repository.dart';
import 'package:storytots/data/repositories/stories_repository.dart';
import 'package:storytots/data/services/profile_stats_service.dart';
import 'package:storytots/data/repositories/progress_repository.dart';
import 'package:storytots/data/repositories/reading_activity_repository.dart';
import 'package:storytots/data/repositories/profile_repository.dart';

class ParentReportScreen extends StatefulWidget {
  const ParentReportScreen({super.key});

  @override
  State<ParentReportScreen> createState() => _ParentReportScreenState();
}

class _ParentReportScreenState extends State<ParentReportScreen> {
  final _stats = ProfileStatsService();
  final _library = LibraryRepository();
  final _assess = AssessmentRepository();
  final _stories = StoriesRepository();
  final _difficult = DifficultWordsRepository();
  final _progressRepo = ProgressRepository();
  final _profileRepo = ProfileRepository();

  ProfileStats? _profileStats;
  List<LibraryEntry> _history = [];
  List<Story> _completedStories = [];
  List<DifficultWord> _hardWords = [];
  Map<String, Progress?> _latestProgress = {};
  bool _loading = true;
  String _childName = 'your child';

  @override
  void initState() {
    super.initState();
    _guardRole();
    _load();
  }

  Future<void> _guardRole() async {
    final isParent = await RoleModeRepository().isParentMode();
    if (!isParent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reports are available for parents only.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.of(context).maybePop();
    }
  }

  

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
  // Ensure any local data gets flushed to server first so we read fresh values
  await ReadingActivityRepository().flushQueue();
  await _progressRepo.flushPendingProgress();
      final stats = await _stats.getStatsDbFirst();
      final history = await _library.listHistory();
      final completedIds = await _assess.getCompletedStoryIds();
      final completed = await _stories.listByIds(completedIds);
      // Ensure server has local difficult words then fetch from DB for cross-device consistency
      await _difficult.flushToServer(userId: uid);
      final hard = await _difficult.topWordsDbFirst(userId: uid, limit: 50);
      // Fetch profile first name as the child's name placeholder (fallbacks handled)
      String name = 'your child';
      try {
        final raw = await _profileRepo.getMyProfileRaw();
        final first = (raw?['first_name'] as String?)?.trim();
        if (first != null && first.isNotEmpty) name = first;
      } catch (_) {}
      // Load latest progress for history items (for progress bars)
      final Map<String, Progress?> latest = {};
      for (final h in history.take(8)) {
        latest[h.storyId] = await _progressRepo.getLocalProgress(h.storyId);
      }
      if (!mounted) return;
      setState(() {
        _profileStats = stats;
        _history = history;
        _completedStories = completed;
        _hardWords = hard;
        _latestProgress = latest;
        _childName = name;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(appBg),
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('Parent Reports'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildGreeting(),
                  const SizedBox(height: 16),
                  _buildWeeklyCard(),
                  const SizedBox(height: 16),
                  _buildRecentlyOpened(),
                  const SizedBox(height: 16),
                  _buildCompletedAssessments(),
                  const SizedBox(height: 16),
                  _buildDifficultWords(),
                ],
              ),
            ),
    );
  }

  Future<void> _logout() async {
    try {
      final authCache = AuthCacheRepository();
      await authCache.clearCache();
      await Supabase.instance.client.auth.signOut();
      await RoleModeRepository().clear();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error logging out: $error'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildWeeklyCard() {
    final s = _profileStats;
    if (s == null) return const SizedBox.shrink();
    return _Card(
      title: 'Weekly Reading Overview',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _metric('Total (7d)', '${s.totalMinutes7d} min'),
              _metric('English', '${s.enMinutes7d} min'),
              _metric('Filipino', '${s.tlMinutes7d} min'),
              _metric('Streak', '${s.streakDays} days'),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 80,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final d in s.weekly)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Container(
                              height: (d.totalMinutes * 2).toDouble(),
                              decoration: BoxDecoration(
                                color: const Color(brandPurple),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _dayLabel(d.date),
                            style: const TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildSpeedRow(),
          const SizedBox(height: 6),
          FutureBuilder<LanguageStats>(
            future: ReadingActivityRepository().getTodayLanguageStats(),
            builder: (context, snap) {
              final todayWpm = snap.data?.wpm ?? 0;
              return Text(
                'Today\'s WPM: $todayWpm',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              );
            },
          ),
          if (s.lastSessionAt != null) ...[
            const SizedBox(height: 8),
            Text(
              'Last session: ${s.lastSessionAt}',
              style: TextStyle(color: Colors.grey[700], fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }

  String _dayLabel(DateTime d) {
    const days = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];
    return days[d.weekday % 7];
  }

  Widget _buildGreeting() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(brandPurple),
        borderRadius: BorderRadius.circular(12),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hello Parent 👋',
            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            'Here you can see the progress of $_childName.',
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentlyOpened() {
    if (_history.isEmpty) return const SizedBox.shrink();
    return _Card(
      title: 'Recently Opened',
      child: Column(
        children: _history.take(6).map((e) {
          final prog = _latestProgress[e.storyId];
          final total = (prog?.meta?['total_sentences'] as num?)?.toInt() ?? 0;
          final idx = prog?.sentenceIndex ?? 0;
          final pct = total > 0 ? (idx + 1) / total : 0.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                e.coverUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(e.coverUrl!, width: 44, height: 44, fit: BoxFit.cover),
                      )
                    : const Icon(Icons.menu_book, color: Colors.black54, size: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(e.storyTitle ?? e.storyId, maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: pct.clamp(0, 1),
                          backgroundColor: Colors.grey[200],
                          minHeight: 6,
                          valueColor: const AlwaysStoppedAnimation(Color(brandPurple)),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        total > 0 ? '${((pct * 100).round())}% completed' : 'Just getting started',
                        style: const TextStyle(fontSize: 11, color: Colors.black54),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FutureBuilder<LanguageStats>(
                  future: ReadingActivityRepository().getTodayLanguageStats(),
                  builder: (context, snap) {
                    final wpm = snap.data?.wpm ?? 0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'WPM $wpm',
                          textAlign: TextAlign.right,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                        if (e.lastOpened != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            _formatShort(e.lastOpened!),
                            textAlign: TextAlign.right,
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  String _formatShort(DateTime d) {
    const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    final month = months[d.month - 1];
    final day = d.day;
    final h24 = d.hour;
    final ampm = h24 >= 12 ? 'PM' : 'AM';
    var h12 = h24 % 12;
    if (h12 == 0) h12 = 12;
    final min = d.minute.toString().padLeft(2, '0');
    return '$month $day, $h12:$min $ampm';
  }

  Widget _buildCompletedAssessments() {
    if (_completedStories.isEmpty) return _Card(
      title: 'Assessments',
      child: const Text('No completed assessments yet.'),
    );
    return _Card(
      title: 'Completed Assessments',
      child: Column(
        children: _completedStories.map((s) {
          return ListTile(
            leading: s.coverUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(s.coverUrl!, width: 44, height: 44, fit: BoxFit.cover),
                  )
                : const Icon(Icons.check_circle, color: Colors.green),
            title: Text(s.title),
            subtitle: Text('Language: ${s.language.toUpperCase()}'),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDifficultWords() {
    if (_hardWords.isEmpty) return _Card(
      title: 'Challenging Words',
      child: const Text('No difficult words recorded yet.'),
    );
    return _Card(
      title: 'Challenging Words',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _hardWords.take(30).map((w) {
              return Chip(
                label: Text('${w.word} • ${w.count}x'),
                backgroundColor: Colors.orange[50],
                side: BorderSide(color: Colors.orange[200]!),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Text(
            'Tip: Practice the top 5 words daily. You can tap “Listen” in reading practice to hear correct pronunciation.',
            style: TextStyle(color: Colors.grey[700], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _metric(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: Colors.black54, fontSize: 12)),
      ],
    );
  }

  // Approximate WPM and speed band using sentencesPracticed as proxy for words (~8 words/sentence)
  Widget _buildSpeedRow() {
    final s = _profileStats;
    if (s == null) return const SizedBox.shrink();
  final todayMinFuture = ReadingActivityRepository().getTodayLanguageStats();
    return FutureBuilder<LanguageStats>(
      future: todayMinFuture,
      builder: (context, snap) {
    final wpm = snap.data?.wpm ?? 0;
        final band = wpm == 0
            ? 'No reading today'
      : (wpm < 60
        ? 'Developing pace'
        : (wpm <= 120 ? 'Comfortable pace' : 'Fast pace'));
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _metric('Estimated WPM', wpm.toString()),
            _metric('Pace', band),
          ],
        );
      },
    );
  }
}

class _Card extends StatelessWidget {
  final String title;
  final Widget child;
  const _Card({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'RustyHooks',
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.5,
                color: Color(brandPurple),
              ),
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}
