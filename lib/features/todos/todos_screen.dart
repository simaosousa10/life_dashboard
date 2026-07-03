import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/recurring_task.dart';
import '../../data/models/todo_item.dart';
import '../../providers/app_providers.dart';
import 'widgets/weekday_selector.dart';

class TodosScreen extends ConsumerWidget {
  const TodosScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todos = ref.watch(todosProvider);
    final recurringTasks = ref.watch(recurringTasksProvider);
    final firstError = _firstError([todos, recurringTasks]);
    final todoItems = todos.valueOrNull ?? const <TodoItem>[];
    final recurringItems =
        recurringTasks.valueOrNull ?? const <RecurringTask>[];
    final isLoading = todos.isLoading || recurringTasks.isLoading;

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
                title: 'Erro ao carregar tarefas',
                message: friendlyErrorMessage(firstError),
              )
            else if (todoItems.isEmpty && recurringItems.isEmpty)
              const EmptyState(
                icon: Icons.checklist_outlined,
                title: 'Sem tarefas',
                message: 'Cria tarefas simples ou recorrentes.',
              )
            else ...[
              if (recurringItems.isNotEmpty) ...[
                const _SectionHeader('Recorrentes'),
                ...recurringItems.map(
                  (item) => _RecurringTaskCard(
                    item: item,
                    onEdit: () => _openTaskDialog(context, ref, item: item),
                    onDelete: () => _deleteRecurringTask(context, ref, item),
                    onActiveChanged: (value) =>
                        _setRecurringTaskActive(context, ref, item, value),
                  ),
                ),
                const SizedBox(height: 14),
              ],
              if (todoItems.isNotEmpty) ...[
                const _SectionHeader('Tarefas'),
                ...todoItems.map(
                  (item) => _TodoCard(
                    item: item,
                    onEdit: () => _openTaskDialog(context, ref, todo: item),
                    onDelete: () => _deleteTodo(context, ref, item),
                    onCompletedChanged: (value) =>
                        _setTodoCompleted(context, ref, item, value),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openTaskDialog(context, ref),
        icon: const Icon(Icons.add_task),
        label: const Text('Tarefa'),
      ),
    );
  }

  void _openTaskDialog(
    BuildContext context,
    WidgetRef ref, {
    TodoItem? todo,
    RecurringTask? item,
  }) {
    showDialog<void>(
      context: context,
      builder: (_) => _TaskDialog(
        todo: todo,
        recurringTask: item,
        onTodoSubmit: (input) async {
          final repository = ref.read(todosRepositoryProvider);
          if (todo == null) {
            await repository.create(input);
          } else {
            await repository.update(todo.id, input);
          }
          invalidateDashboardData(ref);
        },
        onRecurringSubmit: (input) async {
          final repository = ref.read(recurringTasksRepositoryProvider);
          if (item == null) {
            await repository.create(input);
          } else {
            await repository.update(item.id, input);
          }
          invalidateDashboardData(ref);
        },
      ),
    );
  }

  Future<void> _setTodoCompleted(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
    bool value,
  ) async {
    try {
      await ref.read(todosRepositoryProvider).setCompleted(item.id, value);
      invalidateDashboardData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _deleteTodo(
    BuildContext context,
    WidgetRef ref,
    TodoItem item,
  ) async {
    if (item.recurringTaskId != null) {
      showSuccessSnackBar(
        context,
        'Esta tarefa e gerada por recorrencia. Desativa a recorrencia para remover.',
      );
      return;
    }

    try {
      await ref.read(todosRepositoryProvider).delete(item.id);
      invalidateDashboardData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _setRecurringTaskActive(
    BuildContext context,
    WidgetRef ref,
    RecurringTask item,
    bool value,
  ) async {
    try {
      await ref
          .read(recurringTasksRepositoryProvider)
          .update(item.id, _inputFromRecurringTask(item, isActive: value));
      invalidateDashboardData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _deleteRecurringTask(
    BuildContext context,
    WidgetRef ref,
    RecurringTask item,
  ) async {
    try {
      await ref.read(recurringTasksRepositoryProvider).delete(item.id);
      invalidateDashboardData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _TodoCard extends StatelessWidget {
  const _TodoCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onCompletedChanged,
  });

  final TodoItem item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onCompletedChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: item.isCompleted,
        onChanged: (value) => onCompletedChanged(value ?? false),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            decoration: item.isCompleted ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          _todoSubtitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        secondary: PopupMenuButton<String>(
          onSelected: (value) {
            if (value == 'edit') {
              onEdit();
            } else {
              onDelete();
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(value: 'edit', child: Text('Editar')),
            PopupMenuItem(value: 'delete', child: Text('Eliminar')),
          ],
        ),
      ),
    );
  }
}

class _RecurringTaskCard extends StatelessWidget {
  const _RecurringTaskCard({
    required this.item,
    required this.onEdit,
    required this.onDelete,
    required this.onActiveChanged,
  });

  final RecurringTask item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onActiveChanged;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Icon(
          item.isActive ? Icons.repeat : Icons.pause_circle_outline,
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Text(
          _recurringSubtitle(item),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(value: item.isActive, onChanged: onActiveChanged),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  onEdit();
                } else {
                  onDelete();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'edit', child: Text('Editar')),
                PopupMenuItem(value: 'delete', child: Text('Eliminar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TaskDialog extends StatefulWidget {
  const _TaskDialog({
    required this.onTodoSubmit,
    required this.onRecurringSubmit,
    this.todo,
    this.recurringTask,
  });

  final TodoItem? todo;
  final RecurringTask? recurringTask;
  final Future<void> Function(TodoItemInput input) onTodoSubmit;
  final Future<void> Function(RecurringTaskInput input) onRecurringSubmit;

  @override
  State<_TaskDialog> createState() => _TaskDialogState();
}

class _TaskDialogState extends State<_TaskDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late String _priority;
  late bool _isRecurring;
  DateTime? _dueDate;
  String? _dueTime;
  late DateTime _startDate;
  DateTime? _endDate;
  String? _recurringTime;
  late bool _isActive;
  late Set<int> _weekdays;
  bool _saving = false;
  String? _error;

  bool get _isEditing => widget.todo != null || widget.recurringTask != null;

  @override
  void initState() {
    super.initState();
    final todo = widget.todo;
    final recurringTask = widget.recurringTask;
    _isRecurring = recurringTask != null;
    _titleController = TextEditingController(
      text: todo?.title ?? recurringTask?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: todo?.description ?? recurringTask?.description ?? '',
    );
    _priority = todo?.priority ?? recurringTask?.priority ?? 'normal';
    _dueDate = todo?.dueDate;
    _dueTime = todo?.dueTime;
    _startDate = recurringTask?.startDate ?? todayDate();
    _endDate = recurringTask?.endDate;
    _recurringTime = recurringTask?.time;
    _isActive = recurringTask?.isActive ?? true;
    _weekdays = recurringTask == null
        ? {DateTime.now().weekday}
        : recurringTask.weekdays.toSet();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTodoDate() async {
    final picked = await _pickDate(_dueDate ?? todayDate());
    if (picked != null) {
      setState(() => _dueDate = picked);
    }
  }

  Future<void> _pickStartDate() async {
    final picked = await _pickDate(_startDate);
    if (picked != null) {
      setState(() => _startDate = picked);
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await _pickDate(_endDate ?? _startDate);
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<DateTime?> _pickDate(DateTime initialDate) {
    return showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
  }

  Future<void> _pickTodoTime() async {
    final picked = await _pickTime(_dueTime);
    if (picked != null) {
      setState(() => _dueTime = _formatTime(picked));
    }
  }

  Future<void> _pickRecurringTime() async {
    final picked = await _pickTime(_recurringTime);
    if (picked != null) {
      setState(() => _recurringTime = _formatTime(picked));
    }
  }

  Future<TimeOfDay?> _pickTime(String? value) {
    return showTimePicker(
      context: context,
      initialTime: _parseTime(value) ?? TimeOfDay.now(),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_isRecurring && _weekdays.isEmpty) {
      setState(() => _error = 'Escolhe pelo menos um dia da semana.');
      return;
    }
    if (_isRecurring && _endDate != null && _endDate!.isBefore(_startDate)) {
      setState(() => _error = 'A data de fim deve ser depois do inicio.');
      return;
    }
    if (!_isRecurring && _dueTime != null && _dueDate == null) {
      setState(() => _error = 'Escolhe uma data para usar hora.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      if (_isRecurring) {
        await widget.onRecurringSubmit(
          RecurringTaskInput(
            title: _titleController.text,
            description: blankToNull(_descriptionController.text),
            weekdays: _weekdays.toList(),
            time: _recurringTime,
            startDate: _startDate,
            endDate: _endDate,
            priority: _priority,
            isActive: _isActive,
          ),
        );
      } else {
        await widget.onTodoSubmit(
          TodoItemInput(
            title: _titleController.text,
            description: blankToNull(_descriptionController.text),
            dueDate: _dueDate,
            dueTime: _dueTime,
            priority: _priority,
            isCompleted: widget.todo?.isCompleted ?? false,
          ),
        );
      }
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
      title: Text(_dialogTitle),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isEditing) ...[
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Unica')),
                    ButtonSegment(value: true, label: Text('Recorrente')),
                  ],
                  selected: {_isRecurring},
                  onSelectionChanged: (value) {
                    setState(() => _isRecurring = value.first);
                  },
                ),
                const SizedBox(height: 14),
              ],
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
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Prioridade'),
                items: AppConstants.priorities
                    .map(
                      (priority) => DropdownMenuItem(
                        value: priority,
                        child: Text(priority),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _priority = value!),
              ),
              const SizedBox(height: 12),
              if (_isRecurring) _recurringFields() else _singleTaskFields(),
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

  Widget _singleTaskFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OutlinedButton.icon(
          onPressed: _pickTodoDate,
          icon: const Icon(Icons.event_outlined),
          label: Text(formatDate(_dueDate)),
        ),
        if (_dueDate != null)
          TextButton(
            onPressed: () => setState(() {
              _dueDate = null;
              _dueTime = null;
            }),
            child: const Text('Remover data'),
          ),
        OutlinedButton.icon(
          onPressed: _pickTodoTime,
          icon: const Icon(Icons.schedule_outlined),
          label: Text(_timeButtonLabel(_dueTime)),
        ),
        if (_dueTime != null)
          TextButton(
            onPressed: () => setState(() => _dueTime = null),
            child: const Text('Remover hora'),
          ),
      ],
    );
  }

  Widget _recurringFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Dias da semana',
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        WeekdaySelector(
          selectedWeekdays: _weekdays,
          onChanged: (value) => setState(() => _weekdays = value),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _pickRecurringTime,
          icon: const Icon(Icons.schedule_outlined),
          label: Text(_timeButtonLabel(_recurringTime)),
        ),
        if (_recurringTime != null)
          TextButton(
            onPressed: () => setState(() => _recurringTime = null),
            child: const Text('Remover hora'),
          ),
        OutlinedButton.icon(
          onPressed: _pickStartDate,
          icon: const Icon(Icons.event_outlined),
          label: Text('Inicio: ${formatDate(_startDate)}'),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _pickEndDate,
          icon: const Icon(Icons.event_available_outlined),
          label: Text(
            _endDate == null
                ? 'Sem data de fim'
                : 'Fim: ${formatDate(_endDate)}',
          ),
        ),
        if (_endDate != null)
          TextButton(
            onPressed: () => setState(() => _endDate = null),
            child: const Text('Remover fim'),
          ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          value: _isActive,
          onChanged: (value) => setState(() => _isActive = value),
          title: const Text('Ativa'),
        ),
      ],
    );
  }

  String get _dialogTitle {
    if (widget.todo != null) {
      return 'Editar tarefa';
    }
    if (widget.recurringTask != null) {
      return 'Editar recorrencia';
    }
    return 'Nova tarefa';
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

RecurringTaskInput _inputFromRecurringTask(
  RecurringTask item, {
  required bool isActive,
}) {
  return RecurringTaskInput(
    title: item.title,
    description: item.description,
    weekdays: item.weekdays,
    time: item.time,
    startDate: item.startDate,
    endDate: item.endDate,
    priority: item.priority,
    isActive: isActive,
  );
}

String _todoSubtitle(TodoItem item) {
  final parts = <String>[
    formatDate(item.dueDate),
    if (item.dueTime != null) compactTime(item.dueTime!),
    item.priority,
    if (item.recurringTaskId != null) 'recorrente',
    if (item.description != null) item.description!,
  ];
  return parts.join(' - ');
}

String _recurringSubtitle(RecurringTask item) {
  final weekdays = item.weekdays
      .map((weekday) => AppConstants.weekdays[weekday] ?? '$weekday')
      .join(', ');
  final parts = <String>[
    weekdays,
    if (item.time != null) compactTime(item.time!),
    item.priority,
    item.isActive ? 'ativa' : 'inativa',
  ];
  return parts.join(' - ');
}

String _timeButtonLabel(String? value) {
  if (value == null) {
    return 'Sem hora';
  }
  return compactTime(value);
}

String _formatTime(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

TimeOfDay? _parseTime(String? value) {
  if (value == null) {
    return null;
  }
  final parts = value.split(':');
  if (parts.length < 2) {
    return null;
  }
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) {
    return null;
  }
  return TimeOfDay(hour: hour, minute: minute);
}
