import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/calendar_event.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/recurring_task.dart';
import '../../data/models/schedule_block.dart';
import '../../data/models/todo_item.dart';
import '../../providers/app_providers.dart';
import 'widgets/day_schedule_bottom_sheet.dart';
import 'widgets/monthly_calendar_view.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedDate;
  late DateTime _visibleMonth;

  @override
  void initState() {
    super.initState();
    final today = todayDate();
    _selectedDate = today;
    _visibleMonth = DateTime(today.year, today.month);
  }

  @override
  Widget build(BuildContext context) {
    final schedule = ref.watch(scheduleBlocksProvider);
    final events = ref.watch(calendarEventsProvider);
    final todos = ref.watch(todosProvider);
    final recurringTasks = ref.watch(recurringTasksProvider);

    final firstError = _firstError([schedule, events, todos, recurringTasks]);
    final isLoading =
        schedule.isLoading ||
        events.isLoading ||
        todos.isLoading ||
        recurringTasks.isLoading;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => invalidateUserScopedData(ref),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            if (isLoading) const LinearProgressIndicator(),
            if (isLoading) const SizedBox(height: 12),
            if (firstError != null)
              EmptyState(
                icon: Icons.error_outline,
                title: 'Erro ao carregar calendario',
                message: friendlyErrorMessage(firstError),
              )
            else
              MonthlyCalendarView(
                visibleMonth: _visibleMonth,
                selectedDate: _selectedDate,
                hasItemsForDate: (date) => _hasItemsForDate(
                  date,
                  schedule.valueOrNull ?? const [],
                  events.valueOrNull ?? const [],
                  todos.valueOrNull ?? const [],
                  recurringTasks.valueOrNull ?? const [],
                ),
                onPreviousMonth: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  });
                },
                onNextMonth: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  });
                },
                onSelectDate: (date) {
                  setState(() => _selectedDate = date);
                  _openDayBottomSheet(
                    context,
                    date,
                    schedule.valueOrNull ?? const [],
                    events.valueOrNull ?? const [],
                    todos.valueOrNull ?? const [],
                  );
                },
              ),
            const SizedBox(height: 14),
            _SelectedDayPreview(
              selectedDate: _selectedDate,
              scheduleBlocks: schedule.valueOrNull ?? const [],
              events: events.valueOrNull ?? const [],
              todos: todos.valueOrNull ?? const [],
              recurringTasks: recurringTasks.valueOrNull ?? const [],
              onTap: firstError == null
                  ? () {
                      _openDayBottomSheet(
                        context,
                        _selectedDate,
                        schedule.valueOrNull ?? const [],
                        events.valueOrNull ?? const [],
                        todos.valueOrNull ?? const [],
                      );
                    }
                  : null,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEventDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Evento'),
      ),
    );
  }

  Future<void> _openDayBottomSheet(
    BuildContext context,
    DateTime date,
    List<ScheduleBlock> scheduleBlocks,
    List<CalendarEvent> events,
    List<TodoItem> todos,
  ) async {
    var visibleTodos = todos;
    try {
      await ref
          .read(recurringTasksRepositoryProvider)
          .generateTasksForDate(date);
      visibleTodos = await ref.read(todosRepositoryProvider).list();
      ref.invalidate(todosProvider);
      ref.invalidate(homeTimelineProvider);
      ref.invalidate(dashboardSummaryProvider);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }

    if (!context.mounted) {
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => DayScheduleBottomSheet(
        date: date,
        scheduleBlocks: scheduleBlocks,
        events: events,
        todos: visibleTodos,
        onEditEvent: (event) => _openEventDialog(context, ref, event),
        onDeleteEvent: (event) => _deleteEvent(context, ref, event),
      ),
    );
  }

  Future<void> _deleteEvent(
    BuildContext context,
    WidgetRef ref,
    CalendarEvent event,
  ) async {
    try {
      await ref.read(calendarRepositoryProvider).delete(event.id);
      invalidateUserScopedData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  void _openEventDialog(
    BuildContext context,
    WidgetRef ref, [
    CalendarEvent? event,
  ]) {
    showDialog<void>(
      context: context,
      builder: (_) => _EventDialog(
        event: event,
        onSubmit: (input) async {
          final repository = ref.read(calendarRepositoryProvider);
          if (event == null) {
            await repository.create(input);
          } else {
            await repository.update(event.id, input);
          }
          invalidateUserScopedData(ref);
        },
      ),
    );
  }
}

class _SelectedDayPreview extends StatelessWidget {
  const _SelectedDayPreview({
    required this.selectedDate,
    required this.scheduleBlocks,
    required this.events,
    required this.todos,
    required this.recurringTasks,
    required this.onTap,
  });

  final DateTime selectedDate;
  final List<ScheduleBlock> scheduleBlocks;
  final List<CalendarEvent> events;
  final List<TodoItem> todos;
  final List<RecurringTask> recurringTasks;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final count = _itemCountForDate(
      selectedDate,
      scheduleBlocks,
      events,
      todos,
      recurringTasks,
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.today_outlined),
        title: Text(formatDate(selectedDate)),
        subtitle: Text(
          count == 0
              ? 'Nada planeado para este dia.'
              : '$count item${count == 1 ? '' : 's'} planeado${count == 1 ? '' : 's'}',
        ),
        trailing: const Icon(Icons.expand_less),
      ),
    );
  }
}

class _EventDialog extends StatefulWidget {
  const _EventDialog({required this.onSubmit, this.event});

  final CalendarEvent? event;
  final Future<void> Function(CalendarEventInput input) onSubmit;

  @override
  State<_EventDialog> createState() => _EventDialogState();
}

class _EventDialogState extends State<_EventDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late DateTime _eventDate;
  late String _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _eventDate = event?.eventDate ?? todayDate();
    _category = event?.category ?? AppConstants.eventCategories.first;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        CalendarEventInput(
          title: _titleController.text,
          description: blankToNull(_descriptionController.text),
          eventDate: _eventDate,
          category: _category,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.event == null ? 'Novo evento' : 'Editar evento'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Titulo'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Obrigatorio.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descricao'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: AppConstants.eventCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(formatDate(_eventDate)),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: const Text('Guardar'),
        ),
      ],
    );
  }
}

Object? _firstError(List<AsyncValue<Object?>> values) {
  for (final value in values) {
    if (value.hasError) {
      return value.error;
    }
  }
  return null;
}

bool _hasItemsForDate(
  DateTime date,
  List<ScheduleBlock> scheduleBlocks,
  List<CalendarEvent> events,
  List<TodoItem> todos,
  List<RecurringTask> recurringTasks,
) {
  return _itemCountForDate(
        date,
        scheduleBlocks,
        events,
        todos,
        recurringTasks,
      ) >
      0;
}

int _itemCountForDate(
  DateTime date,
  List<ScheduleBlock> scheduleBlocks,
  List<CalendarEvent> events,
  List<TodoItem> todos,
  List<RecurringTask> recurringTasks,
) {
  final dateKey = formatDateKey(date);
  final scheduleCount = scheduleBlocks
      .where((block) => block.weekday == date.weekday)
      .length;
  final eventCount = events
      .where((event) => formatDateKey(event.eventDate) == dateKey)
      .length;
  final todoCount = todos
      .where(
        (todo) =>
            todo.dueDate != null && formatDateKey(todo.dueDate!) == dateKey,
      )
      .length;
  final generatedRecurringIds = todos
      .where(
        (todo) =>
            todo.recurringTaskId != null &&
            todo.dueDate != null &&
            formatDateKey(todo.dueDate!) == dateKey,
      )
      .map((todo) => todo.recurringTaskId!)
      .toSet();
  final recurringCount = recurringTasks
      .where(
        (task) =>
            task.appliesTo(date) && !generatedRecurringIds.contains(task.id),
      )
      .length;
  return scheduleCount + eventCount + todoCount + recurringCount;
}
