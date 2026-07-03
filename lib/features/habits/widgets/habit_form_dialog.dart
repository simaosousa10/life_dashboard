import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/utils/app_error.dart';
import '../../../data/models/habit.dart';
import '../../../data/models/model_helpers.dart';
import '../../todos/widgets/weekday_selector.dart';

class HabitFormDialog extends StatefulWidget {
  const HabitFormDialog({required this.onSubmit, super.key, this.habit});

  final Habit? habit;
  final Future<void> Function(HabitInput input) onSubmit;

  @override
  State<HabitFormDialog> createState() => _HabitFormDialogState();
}

class _HabitFormDialogState extends State<HabitFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _categoryController;
  late final TextEditingController _targetValueController;
  late final TextEditingController _targetUnitController;
  late HabitTargetType _targetType;
  late Set<int> _weekdays;
  late DateTime _startDate;
  DateTime? _endDate;
  late bool _isActive;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    _titleController = TextEditingController(text: habit?.title ?? '');
    _descriptionController = TextEditingController(
      text: habit?.description ?? '',
    );
    _categoryController = TextEditingController(text: habit?.category ?? '');
    _targetValueController = TextEditingController(
      text: habit?.targetValue == null
          ? ''
          : _formatNumber(habit!.targetValue!),
    );
    _targetUnitController = TextEditingController(
      text: habit?.targetUnit ?? 'minutes',
    );
    _targetType = habit?.targetType ?? HabitTargetType.boolean;
    _weekdays = habit?.weekdays.toSet() ?? {DateTime.now().weekday};
    _startDate = habit?.startDate ?? todayDate();
    _endDate = habit?.endDate;
    _isActive = habit?.isActive ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _categoryController.dispose();
    _targetValueController.dispose();
    _targetUnitController.dispose();
    super.dispose();
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

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_weekdays.isEmpty) {
      setState(() => _error = 'Escolhe pelo menos um dia da semana.');
      return;
    }
    if (_endDate != null && _endDate!.isBefore(_startDate)) {
      setState(() => _error = 'A data de fim deve ser depois do inicio.');
      return;
    }

    final targetValue = blankToNull(_targetValueController.text) == null
        ? null
        : tryParseDecimal(_targetValueController.text);

    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        HabitInput(
          title: _titleController.text,
          description: blankToNull(_descriptionController.text),
          category: blankToNull(_categoryController.text),
          targetType: _targetType,
          targetValue: _targetType == HabitTargetType.boolean
              ? null
              : targetValue,
          targetUnit: _targetType == HabitTargetType.boolean
              ? null
              : blankToNull(_targetUnitController.text),
          weekdays: _weekdays.toList(),
          startDate: _startDate,
          endDate: _endDate,
          isActive: _isActive,
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
      title: Text(widget.habit == null ? 'Novo habito' : 'Editar habito'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
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
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(labelText: 'Categoria'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<HabitTargetType>(
                initialValue: _targetType,
                decoration: const InputDecoration(labelText: 'Tipo objetivo'),
                items: HabitTargetType.values
                    .map(
                      (type) => DropdownMenuItem(
                        value: type,
                        child: Text(type.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  setState(() => _targetType = value);
                },
              ),
              if (_targetType != HabitTargetType.boolean) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetValueController,
                  decoration: const InputDecoration(
                    labelText: 'Valor objetivo',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _optionalPositiveDecimal,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _targetUnitController,
                  decoration: const InputDecoration(labelText: 'Unidade'),
                ),
              ],
              const SizedBox(height: 12),
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
                title: const Text('Ativo'),
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

String? _optionalPositiveDecimal(String? value) {
  final trimmed = (value ?? '').trim();
  if (trimmed.isEmpty) {
    return null;
  }
  final parsed = tryParseDecimal(trimmed);
  if (parsed == null || parsed <= 0) {
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
