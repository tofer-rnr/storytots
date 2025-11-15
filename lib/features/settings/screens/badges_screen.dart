import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/repositories/achievements_repository.dart' as ach;
import 'package:storytots/data/repositories/reading_activity_repository.dart';
import 'package:storytots/data/services/profile_stats_service.dart';

class BadgesScreen extends StatefulWidget {
  const BadgesScreen({super.key});

  @override
  State<BadgesScreen> createState() => _BadgesScreenState();
}

class _BadgesScreenState extends State<BadgesScreen> {
  final repo = ach.AchievementsRepository();
  List<ach.Badge> _earned = [];
  List<ach.Badge> _locked = [];
  int _points = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
    try {
      final stats = await ProfileStatsService().getStatsDbFirst();
      final today = await ReadingActivityRepository().getTodayLanguageStats();
  await repo.evaluateAndSave(
        userId: uid,
        stats: stats,
        today: today,
        practicedTrickyWords: 0,
      );
  // Include custom badges as well
  final earned = await repo.listEarned(uid);
  final locked = await repo.listLocked(uid); // static only
  final pts = earned.fold<int>(0, (sum, b) => sum + b.points);
      if (!mounted) return;
      setState(() {
        _earned = earned;
        _locked = locked;
        _points = pts;
        _loading = false;
      });
    } catch (_) {
      // Fallback: still attempt to list locally earned badges (guest/offline)
      try {
        final earned = await repo.listEarned(uid);
        final locked = await repo.listLocked(uid);
        final pts = earned.fold<int>(0, (sum, b) => sum + b.points);
        if (!mounted) return;
        setState(() {
          _earned = earned;
          _locked = locked;
          _points = pts;
          _loading = false;
        });
      } catch (_) {
        if (!mounted) return;
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(brandPurple);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: const Text('Badges & Rewards'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _header(purple),
                  const SizedBox(height: 12),
                  _sectionTitle('Unlocked Badges'),
                  const SizedBox(height: 8),
                  _badgesGrid(_earned, unlocked: true),
                  const SizedBox(height: 16),
                  _sectionTitle('Keep Going!'),
                  const SizedBox(height: 8),
                  _badgesGrid(_locked, unlocked: false),
                ],
              ),
            ),
    );
  }

  Widget _header(Color purple) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: purple,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset('assets/images/icon.png', fit: BoxFit.contain),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Great work! 🎉',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'You have ${_earned.length} badge${_earned.length == 1 ? '' : 's'} and ${_points} points!',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(
        t,
        style: const TextStyle(fontWeight: FontWeight.w800, letterSpacing: 1.2),
      );

  Widget _badgesGrid(List<ach.Badge> list, {required bool unlocked}) {
    if (list.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          unlocked ? 'No badges yet. Let\'s read a story!' : 'More badges are waiting for you!',
          style: const TextStyle(color: Colors.black54),
        ),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: list.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: .78,
      ),
      itemBuilder: (_, i) {
        final b = list[i];
        return _badgeTile(b, unlocked: unlocked);
      },
    );
  }

  Widget _badgeTile(ach.Badge b, {required bool unlocked}) {
    final color = unlocked ? Colors.white : Colors.white;
    final shadow = unlocked ? Colors.black12 : Colors.black12;
    return AnimatedOpacity(
      opacity: unlocked ? 1.0 : 0.6,
      duration: const Duration(milliseconds: 200),
      child: Container(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(color: shadow, blurRadius: 8, offset: const Offset(0, 4)),
          ],
          border: unlocked ? Border.all(color: const Color(brandPurple), width: 1) : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: unlocked ? const Color(0xFFFFF3CD) : Colors.grey.shade200,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.asset(b.iconAsset, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                b.title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '+${b.points} pts',
              style: TextStyle(
                color: unlocked ? const Color(brandPurple) : Colors.black45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
