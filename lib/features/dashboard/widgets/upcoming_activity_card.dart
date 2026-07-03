import 'package:flutter/material.dart';

import '../../../data/models/today_timeline_item.dart';
import '../timeline_helpers.dart';

class UpcomingActivityCard extends StatelessWidget {
  const UpcomingActivityCard({required this.item, super.key});

  final TodayTimelineItem item;

  @override
  Widget build(BuildContext context) {
    final icon = switch (item.type) {
      TodayItemType.schedule => Icons.calendar_view_week_outlined,
      TodayItemType.calendarEvent => Icons.event_outlined,
      TodayItemType.todo => Icons.check_circle_outline,
      TodayItemType.recurringTask => Icons.repeat,
      TodayItemType.habit => Icons.fact_check_outlined,
    };

    return Container(
      constraints: const BoxConstraints(minHeight: 72),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: const Color(0xFFFFD166).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFFFFD166), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.description?.isNotEmpty == true
                      ? '${item.category} - ${item.description}'
                      : item.category,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.62),
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            timelineTimeLabel(item),
            style: const TextStyle(
              color: Color(0xFFFFD166),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
