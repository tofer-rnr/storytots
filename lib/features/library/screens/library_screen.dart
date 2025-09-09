import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/data/cover_assets.dart';
import 'package:storytots/data/repositories/library_repository.dart';
import 'package:storytots/features/reader/story_details_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen>
    with SingleTickerProviderStateMixin {
  final _repo = LibraryRepository();

  late Future<List<LibraryEntry>> _fAll;
  late Future<List<LibraryEntry>> _fFav;
  late Future<List<LibraryEntry>> _fHist;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    _fAll = _repo.listAll();
    _fFav = _repo.listFavorites();
    _fHist = _repo.listHistory();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: const Color(brandPurple),
          foregroundColor: Colors.white,
          title: const Text('LIBRARY'),
          bottom: const TabBar(
            indicatorColor: Colors.white,
            tabs: [
              Tab(text: 'ALL'),
              Tab(text: 'FAVORITE'),
              Tab(text: 'HISTORY'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
            Container(color: Colors.white.withOpacity(0.94)),
            TabBarView(
              children: [
                _GridFuture(future: _fAll, onPullToRefresh: _refresh),
                _GridFuture(future: _fFav, onPullToRefresh: _refresh),
                _HistoryGridFuture(future: _fHist, onPullToRefresh: _refresh),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ---------------- ALL / FAVORITE (grid, no timestamp) ----------------

class _GridFuture extends StatelessWidget {
  const _GridFuture({required this.future, required this.onPullToRefresh});
  final Future<List<LibraryEntry>> future;
  final Future<void> Function() onPullToRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryEntry>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const <LibraryEntry>[];
        if (items.isEmpty) {
          return const Center(child: Text('Nothing here yet'));
        }
        return RefreshIndicator(
          onRefresh: onPullToRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: .72,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _BookTile(entry: items[i]),
          ),
        );
      },
    );
  }
}

class _BookTile extends StatelessWidget {
  const _BookTile({required this.entry});
  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = entry.storyTitle ?? '';
    final localAsset = coverAssetForTitle(title);

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryDetailsScreen(storyId: entry.storyId)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: _CoverImage(
                  networkUrl: entry.coverUrl, // full URL if available
                  assetFallback: localAsset ?? 'assets/images/book_cover_placeholder.png',
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title.isNotEmpty ? title : 'Untitled',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ---------------- HISTORY (grid with human-readable timestamp) ----------------

class _HistoryGridFuture extends StatelessWidget {
  const _HistoryGridFuture({required this.future, required this.onPullToRefresh});
  final Future<List<LibraryEntry>> future;
  final Future<void> Function() onPullToRefresh;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LibraryEntry>>(
      future: future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snap.data ?? const <LibraryEntry>[];
        if (items.isEmpty) {
          return const Center(child: Text('No reading history yet'));
        }
        return RefreshIndicator(
          onRefresh: onPullToRefresh,
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: .72,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) => _HistoryTile(entry: items[i]),
          ),
        );
      },
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({required this.entry});
  final LibraryEntry entry;

  @override
  Widget build(BuildContext context) {
    final title = entry.storyTitle ?? '';
    final localAsset = coverAssetForTitle(title);
    final label = entry.lastOpened != null ? _humanize(entry.lastOpened!) : '—';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => StoryDetailsScreen(storyId: entry.storyId)),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: const [
                      BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _CoverImage(
                      networkUrl: entry.coverUrl,
                      assetFallback: localAsset ?? 'assets/images/book_cover_placeholder.png',
                    ),
                  ),
                ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title.isNotEmpty ? title : 'Untitled',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// ---------------- cover image helper ----------------

class _CoverImage extends StatelessWidget {
  const _CoverImage({required this.networkUrl, required this.assetFallback});

  final String? networkUrl;
  final String assetFallback;

  @override
  Widget build(BuildContext context) {
    if (networkUrl != null && networkUrl!.isNotEmpty) {
      return Image.network(
        networkUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) {
          return Image.asset(
            assetFallback,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
          );
        },
      );
    }
    return Image.asset(
      assetFallback,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
    );
  }
}

/// ---------------- helpers ----------------

String _humanize(DateTime when) {
  final now = DateTime.now();
  final diff = now.difference(when);

  if (diff.inSeconds < 15) return 'just now';
  if (diff.inMinutes < 1) return '${diff.inSeconds}s ago';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';

  final startOfToday = DateTime(now.year, now.month, now.day);
  final startOfYesterday = startOfToday.subtract(const Duration(days: 1));

  if (when.isAfter(startOfToday)) {
    return 'Today ${_formatHm(when)}';
  } else if (when.isAfter(startOfYesterday)) {
    return 'Yesterday ${_formatHm(when)}';
  } else {
    return _formatDateTime(when);
  }
}

String _formatHm(DateTime dt) {
  var h = dt.hour % 12;
  if (h == 0) h = 12;
  final m = dt.minute.toString().padLeft(2, '0');
  final ampm = dt.hour < 12 ? 'AM' : 'PM';
  return '$h:$m $ampm';
}

String _formatDateTime(DateTime dt) {
  const months = [
    'Jan','Feb','Mar','Apr','May','Jun',
    'Jul','Aug','Sep','Oct','Nov','Dec'
  ];
  final month = months[dt.month - 1];
  final day = dt.day;
  final year = dt.year;
  return '$month $day, $year ${_formatHm(dt)}';
}
