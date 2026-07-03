import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/calendar_event.dart';
import '../../../data/models/schedule_block.dart';
import '../../../data/models/todo_item.dart';
import 'day_agenda_item_card.dart';

class DayScheduleBottomSheet extends StatelessWidget {
  const DayScheduleBottomSheet({
    required this.date,
    required this.scheduleBlocks,
    required this.events,
    required this.todos,
    required this.onEditEvent,
    required this.onDeleteEvent,
    super.key,
  });

  final DateTime date;
  final List<ScheduleBlock> scheduleBlocks;
  final List<CalendarEvent> events;
  final List<TodoItem> todos;
  final void Function(CalendarEvent event) onEditEvent;
  final Future<void> Function(CalendarEvent event) onDeleteEvent;

  @override
  Widget build(BuildContext context) {
    final daySchedule =
        scheduleBlocks.where((block) => block.weekday == date.weekday).toList()
          ..sort(
            (left, right) => _timeToMinutes(
              left.startTime,
            ).compareTo(_timeToMinutes(right.startTime)),
          );
    final dateKey = formatDateKey(date);
    final dayEvents = events
        .where((event) => formatDateKey(event.eventDate) == dateKey)
        .toList();
    final dayTodos = todos
        .where(
          (todo) =>
              todo.dueDate != null && formatDateKey(todo.dueDate!) == dateKey,
        )
        .toList();
    final hasItems =
        daySchedule.isNotEmpty || dayEvents.isNotEmpty || dayTodos.isNotEmpty;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.38,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
          children: [
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              formatDate(date),
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 14),
            if (!hasItems)
              const _DayEmptyState()
            else ...[
              DayAgendaSection(
                title: 'Horario',
                icon: Icons.schedule_outlined,
                isEmpty: daySchedule.isEmpty,
                emptyMessage: 'Sem blocos de horario.',
                children: daySchedule.map((block) {
                  return DayAgendaItemCard(
                    title: block.title,
                    category: block.category,
                    description: block.description,
                    time:
                        '${compactTime(block.startTime)} - ${compactTime(block.endTime)}',
                    icon: Icons.calendar_view_day_outlined,
                  );
                }).toList(),
              ),
              DayAgendaSection(
                title: 'Eventos',
                icon: Icons.event_outlined,
                isEmpty: dayEvents.isEmpty,
                emptyMessage: 'Sem eventos.',
                children: dayEvents.map((event) {
                  return DayAgendaItemCard(
                    title: event.title,
                    category: event.category,
                    description: event.description,
                    time: 'Dia inteiro',
                    icon: Icons.event_available_outlined,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'edit') {
                          Navigator.of(context).pop();
                          onEditEvent(event);
                        } else {
                          Navigator.of(context).pop();
                          onDeleteEvent(event);
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'edit', child: Text('Editar')),
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  );
                }).toList(),
              ),
              DayAgendaSection(
                title: 'Tarefas',
                icon: Icons.checklist_outlined,
                isEmpty: dayTodos.isEmpty,
                emptyMessage: 'Sem tarefas.',
                children: dayTodos.map((todo) {
                  return DayAgendaItemCard(
                    title: todo.title,
                    category: todo.priority,
                    description: todo.description,
                    time: todo.dueTime == null
                        ? null
                        : compactTime(todo.dueTime!),
                    status: todo.isCompleted ? 'Concluida' : 'Pendente',
                    icon: todo.isCompleted
                        ? Icons.task_alt
                        : Icons.radio_button_unchecked,
                  );
                }).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class DayAgendaSection extends StatelessWidget {
  const DayAgendaSection({
    required this.title,
    required this.icon,
    required this.isEmpty,
    required this.emptyMessage,
    required this.children,
    super.key,
  });

  final String title;
  final IconData icon;
  final bool isEmpty;
  final String emptyMessage;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            Text(emptyMessage, style: Theme.of(context).textTheme.bodySmall)
          else
            ...children,
        ],
      ),
    );
  }
}

class _DayEmptyState extends StatelessWidget {
  const _DayEmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.event_busy_outlined),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Nada planeado para este dia.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

int _timeToMinutes(String value) {
  final parts = value.split(':');
  final hours = int.tryParse(parts.first) ?? 0;
  final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return hours * 60 + minutes;
}
