import '../../core/constants/app_constants.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/schedule_block.dart';
import '../../data/models/today_timeline_item.dart';
import '../../data/models/todo_item.dart';

List<TodayTimelineItem> buildTodayTimelineItems({
  required DateTime date,
  required List<ScheduleBlock> scheduleBlocks,
  required List<CalendarEvent> events,
  required List<TodoItem> todos,
}) {
  final dateKey = formatDateKey(date);
  final items = <TodayTimelineItem>[];

  for (final block in scheduleBlocks) {
    if (block.weekday != date.weekday) {
      continue;
    }

    items.add(
      TodayTimelineItem(
        id: block.id,
        title: block.title,
        description: block.description,
        category: _titleCase(block.category),
        start: combineDateAndTime(date, block.startTime),
        end: combineDateAndTime(date, block.endTime),
        type: TodayItemType.schedule,
        hasTime: true,
      ),
    );
  }

  for (final event in events) {
    if (formatDateKey(event.eventDate) != dateKey) {
      continue;
    }

    items.add(
      TodayTimelineItem(
        id: event.id,
        title: event.title,
        description: event.description,
        category: _titleCase(event.category),
        start: date,
        type: TodayItemType.calendarEvent,
        hasTime: false,
      ),
    );
  }

  for (final todo in todos) {
    if (todo.isCompleted ||
        todo.dueDate == null ||
        formatDateKey(todo.dueDate!) != dateKey) {
      continue;
    }

    final hasTime = todo.dueTime != null;
    items.add(
      TodayTimelineItem(
        id: todo.id,
        title: todo.title,
        description: todo.description,
        category: 'Tarefa ${_titleCase(todo.priority)}',
        start: hasTime ? combineDateAndTime(date, todo.dueTime!) : date,
        type: TodayItemType.todo,
        hasTime: hasTime,
      ),
    );
  }

  return sortTimelineItems(items);
}

List<TodayTimelineItem> sortTimelineItems(List<TodayTimelineItem> items) {
  return [...items]..sort((left, right) {
    if (left.hasTime != right.hasTime) {
      return left.hasTime ? -1 : 1;
    }
    final startCompare = left.start.compareTo(right.start);
    if (startCompare != 0) {
      return startCompare;
    }
    return left.title.compareTo(right.title);
  });
}

TodayTimelineItem? currentTimelineItem(
  List<TodayTimelineItem> items,
  DateTime now,
) {
  for (final item in sortTimelineItems(items)) {
    if (!item.hasTime || item.end == null) {
      continue;
    }
    if (!now.isBefore(item.start) && !now.isAfter(item.end!)) {
      return item;
    }
  }
  return null;
}

List<TodayTimelineItem> upcomingTimelineItems(
  List<TodayTimelineItem> items,
  DateTime now,
) {
  final current = currentTimelineItem(items, now);
  return sortTimelineItems(
    items.where((item) {
      if (item.id == current?.id && item.type == current?.type) {
        return false;
      }
      if (item.type == TodayItemType.todo) {
        return true;
      }
      if (!item.hasTime) {
        return true;
      }
      return item.start.isAfter(now);
    }).toList(),
  );
}

double timeProgress(TodayTimelineItem item, DateTime now) {
  final end = item.end;
  if (end == null || !item.hasTime) {
    return 0;
  }

  final total = end.difference(item.start).inSeconds;
  if (total <= 0) {
    return 1;
  }

  final elapsed = now.difference(item.start).inSeconds;
  return (elapsed / total).clamp(0.0, 1.0);
}

String remainingTimeLabel(TodayTimelineItem item, DateTime now) {
  final end = item.end;
  if (end == null) {
    return '';
  }

  final remaining = end.difference(now);
  if (remaining.inMinutes <= 0) {
    return 'A terminar';
  }
  if (remaining.inMinutes < 60) {
    return 'Faltam ${remaining.inMinutes} min';
  }

  final hours = remaining.inHours;
  final minutes = remaining.inMinutes.remainder(60);
  if (minutes == 0) {
    return 'Faltam ${hours}h';
  }
  return 'Faltam ${hours}h ${minutes}min';
}

String timelineTimeLabel(TodayTimelineItem item) {
  if (!item.hasTime) {
    return 'Hoje';
  }
  final start = _formatDateTimeTime(item.start);
  final end = item.end == null ? null : _formatDateTimeTime(item.end!);
  return end == null ? start : '$start - $end';
}

DateTime combineDateAndTime(DateTime date, String time) {
  final parts = time.split(':');
  final hour = int.tryParse(parts.first) ?? 0;
  final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return DateTime(date.year, date.month, date.day, hour, minute);
}

String _formatDateTimeTime(DateTime value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _titleCase(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) {
    return trimmed;
  }
  return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
}
