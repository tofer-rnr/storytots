// lib/features/home/widgets/story_card.dart
import 'package:flutter/material.dart';

// Pull in ONLY the Story type from your repo (no DB code here).
import '../../../data/repositories/stories_repository.dart' show Story;
import '../../../data/cover_assets.dart';

class StoryCard extends StatelessWidget {
  const StoryCard({
    super.key,
    required this.story,
    this.onTap,
    this.width = 110,
  });

  final Story story;
  final VoidCallback? onTap;
  final double width;

  @override
  Widget build(BuildContext context) {
    final asset = coverAssetForTitle(story.title);
    final raw = story.coverUrl?.trim();
    final isNetwork =
        raw != null &&
        (raw.startsWith('http://') || raw.startsWith('https://'));

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Builder(
          builder: (context) {
            if (isNetwork) {
              return Image.network(
                raw,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.asset(
                  asset ?? 'assets/images/arts.png',
                  fit: BoxFit.cover,
                ),
              );
            }

            // Resolve asset path if non-empty but not a URL
            String? assetPath = asset;
            if (raw != null && raw.isNotEmpty) {
              assetPath = raw.startsWith('assets/')
                  ? raw
                  : 'assets/images/covers/$raw';
            }

            return Image.asset(
              assetPath ?? 'assets/images/arts.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Image.asset('assets/images/arts.png', fit: BoxFit.cover),
            );
          },
        ),
      ),
    );
  }
}
