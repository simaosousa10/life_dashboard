import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../core/widgets/app_snackbars.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/model_helpers.dart';
import '../../../providers/app_providers.dart';
import 'habit_form_dialog.dart';

class TodayHabitsCheckIn extends ConsumerWidget {
  const TodayHabitsCheckIn({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entries = ref.watch(todayHabitEntriesProvider);

    return entries.when(
      loading: () => const _HabitShell(
        child: LinearProgressIndicator(color: Color(0xFFFFA726)),
      ),
      error: (error, _) => _HabitShell(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFFD166)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                friendlyErrorMessage(error),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
      data: (items) {
        final completed = items
            .where((entry) => entry.log?.isCompleted == true)
            .length;

        return _HabitShell(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.fact_check_outlined,
                    color: Color(0xFFFFD166),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Fecho do dia',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          items.isEmpty
                              ? 'Sem habitos planeados hoje'
                              : '$completed/${items.length} habitos cumpridos',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.68),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Novo habito',
                    onPressed: () => _openHabitForm(context, ref),
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              if (items.isNotEmpty) ...[
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: items.isEmpty ? 0 : completed / items.length,
                  color: const Color(0xFFFFA726),
                  backgroundColor: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                const SizedBox(height: 8),
                ...items.map(
                  (entry) => _HabitCheckRow(
                    entry: entry,
                    onToggle: (value) =>
                        _toggleHabit(context, ref, entry, value),
                    onLogTap: () => _openLogDialog(context, ref, entry),
                    onEdit: () => _openHabitForm(context, ref, entry.habit),
                    onDelete: () => _deleteHabit(context, ref, entry.habit),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  void _openHabitForm(BuildContext context, WidgetRef ref, [Habit? habit]) {
    showDialog<void>(
      context: context,
      builder: (_) => HabitFormDialog(
        habit: habit,
        onSubmit: (input) async {
          final repository = ref.read(habitsRepositoryProvider);
          if (habit == null) {
            await repository.createHabit(input);
          } else {
            await repository.updateHabit(habit.id, input);
          }
          invalidateHabitData(ref);
        },
      ),
    );
  }

  Future<void> _toggleHabit(
    BuildContext context,
    WidgetRef ref,
    TodayHabitEntry entry,
    bool value,
  ) async {
    try {
      await ref
          .read(habitsRepositoryProvider)
          .upsertHabitLog(
            HabitLogInput(
              habitId: entry.habit.id,
              date: todayDate(),
              isCompleted: value,
              value: entry.log?.value,
              note: entry.log?.note,
            ),
          );
      invalidateHabitData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  Future<void> _deleteHabit(
    BuildContext context,
    WidgetRef ref,
    Habit habit,
  ) async {
    try {
      await ref.read(habitsRepositoryProvider).deleteHabit(habit.id);
      invalidateHabitData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  void _openLogDialog(
    BuildContext context,
    WidgetRef ref,
    TodayHabitEntry entry,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _HabitLogDialog(
        entry: entry,
        onSubmit: (input) async {
          await ref.read(habitsRepositoryProvider).upsertHabitLog(input);
          invalidateHabitData(ref);
        },
      ),
    );
  }
}

class _HabitShell extends StatelessWidget {
  const _HabitShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

class _HabitCheckRow extends StatelessWidget {
  const _HabitCheckRow({
    required this.entry,
    required this.onToggle,
    required this.onLogTap,
    required this.onEdit,
    required this.onDelete,
  });

  final TodayHabitEntry entry;
  final ValueChanged<bool> onToggle;
  final VoidCallback onLogTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final habit = entry.habit;
    final log = entry.log;

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Checkbox(
            value: log?.isCompleted ?? false,
            onChanged: (value) => onToggle(value ?? false),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.62)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  _habitSubtitle(habit, log),
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
          TextButton(
            onPressed: onLogTap,
            child: Text(
              habit.targetType == HabitTargetType.boolean ? 'Nota' : 'Valor',
            ),
          ),
          PopupMenuButton<String>(
            iconColor: Colors.white.withValues(alpha: 0.82),
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
    );
  }
}

class _HabitLogDialog extends StatefulWidget {
  const _HabitLogDialog({required this.entry, required this.onSubmit});

  final TodayHabitEntry entry;
  final Future<void> Function(HabitLogInput input) onSubmit;

  @override
  State<_HabitLogDialog> createState() => _HabitLogDialogState();
}

class _HabitLogDialogState extends State<_HabitLogDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _valueController;
  late final TextEditingController _noteController;
  late bool _isCompleted;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final log = widget.entry.log;
    _valueController = TextEditingController(
      text: log?.value == null ? '' : _formatNumber(log!.value!),
    );
    _noteController = TextEditingController(text: log?.note ?? '');
    _isCompleted = log?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _valueController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    final habit = widget.entry.habit;
    final value = habit.targetType == HabitTargetType.boolean
        ? null
        : tryParseDecimal(_valueController.text);

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        HabitLogInput(
          habitId: habit.id,
          date: todayDate(),
          isCompleted: _isCompleted || _valueMeetsTarget(habit, value),
          value: value,
          note: blankToNull(_noteController.text),
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
    final habit = widget.entry.habit;

    return AlertDialog(
      title: Text(habit.title),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (habit.targetType != HabitTargetType.boolean) ...[
                TextFormField(
                  controller: _valueController,
                  decoration: InputDecoration(
                    labelText: habit.targetType == HabitTargetType.duration
                        ? 'Minutos realizados'
                        : 'Valor realizado',
                    suffixText: habit.targetUnit,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalPositiveDecimal,
                ),
                const SizedBox(height: 12),
              ],
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _isCompleted,
                onChanged: (value) => setState(() => _isCompleted = value),
                title: const Text('Cumprido'),
              ),
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Nota opcional'),
                maxLines: 2,
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

String _habitSubtitle(Habit habit, HabitLog? log) {
  final parts = <String>[
    if (habit.category != null) habit.category!,
    habit.targetType.label,
    if (habit.targetValue != null)
      '${_formatNumber(habit.targetValue!)} ${habit.targetUnit ?? ''}'.trim(),
    if (log?.value != null) 'feito ${_formatNumber(log!.value!)}',
  ];
  return parts.join(' - ');
}

bool _valueMeetsTarget(Habit habit, double? value) {
  if (value == null || habit.targetValue == null) {
    return false;
  }
  return value >= habit.targetValue!;
}

String? _optionalPositiveDecimal(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final parsed = tryParseDecimal(trimmed);
  if (parsed == null || parsed < 0) {
    return 'Valor invalido.';
  }
  return null;
}

String _formatNumber(double value) {
  if (value == value.roundToDouble()) {
    return value.round().toString();
  }
  return value.toString();
}
