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
    final hasNetwork = (story.coverUrl != null && story.coverUrl!.isNotEmpty);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 4)),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: hasNetwork
            ? Image.network(story.coverUrl!, fit: BoxFit.cover)
            : Image.asset(
                asset ?? 'assets/images/book_cover_placeholder.png',
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
