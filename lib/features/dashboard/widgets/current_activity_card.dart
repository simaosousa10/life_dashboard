import 'package:flutter/material.dart';

import '../../../data/models/today_timeline_item.dart';
import '../timeline_helpers.dart';
import 'time_progress_bar.dart';

class CurrentActivityCard extends StatelessWidget {
  const CurrentActivityCard({required this.item, required this.now, super.key});

  final TodayTimelineItem item;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final progress = timeProgress(item, now).clamp(0.0, 1.0).toDouble();
    final progressColor = Color.lerp(
      const Color(0xFFFFD166),
      const Color(0xFFFF7A1A),
      progress,
    )!;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: progressColor.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            const Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF2A3341), Color(0xFF151C27)],
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: progress,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFFFFD166).withValues(alpha: 0.95),
                          progressColor.withValues(alpha: 0.90),
                          const Color(0xFFFF7A1A).withValues(alpha: 0.78),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.20),
                      Colors.black.withValues(alpha: 0.36),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: _CurrentActivityContent(
                item: item,
                now: now,
                progress: progress,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CurrentActivityContent extends StatelessWidget {
  const _CurrentActivityContent({
    required this.item,
    required this.now,
    required this.progress,
  });

  final TodayTimelineItem item;
  final DateTime now;
  final double progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                item.category,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Spacer(),
            Text(
              '${(progress * 100).round()}%',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w900,
            height: 1.05,
          ),
        ),
        if (item.description != null) ...[
          const SizedBox(height: 4),
          Text(
            item.description!,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 12,
            ),
          ),
        ],
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(Icons.schedule, size: 15, color: Colors.white),
            const SizedBox(width: 6),
            Text(
              timelineTimeLabel(item),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              remainingTimeLabel(item, now),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        TimeProgressBar(value: progress),
      ],
    );
  }
}
