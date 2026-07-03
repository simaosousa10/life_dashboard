import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/metric_card.dart';
import '../../data/models/activity_entry.dart';
import '../../data/models/model_helpers.dart';
import '../../providers/app_providers.dart';

class ActivitiesScreen extends ConsumerStatefulWidget {
  const ActivitiesScreen({super.key});

  @override
  ConsumerState<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends ConsumerState<ActivitiesScreen> {
  DateTime _date = todayDate();

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = formatDateKey(_date);
    final activities = ref.watch(activityEntriesProvider(dateKey));
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return AppAsyncValue(
      value: activities,
      onRetry: () => ref.invalidate(activityEntriesProvider(dateKey)),
      builder: (items) {
        final total = items.fold(
          0,
          (sum, item) => sum + item.caloriesBurned.round(),
        );

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(activityEntriesProvider(dateKey));
            ref.invalidate(dashboardSummaryProvider);
            ref.invalidate(homeTimelineProvider);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(formatDate(_date)),
              ),
              const SizedBox(height: 12),
              MetricCard(
                title: 'Calorias gastas',
                value: '$total kcal',
                subtitle: 'formula MET x peso x horas',
                icon: Icons.local_fire_department_outlined,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openActivityDialog(
                  context,
                  date: _date,
                  defaultWeight: profile?.weightKg ?? 70,
                ),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar atividade'),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.directions_run_outlined),
                    title: Text('Sem atividades neste dia'),
                  ),
                )
              else
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.directions_run_outlined),
                      title: Text(item.activityName),
                      subtitle: Text(
                        '${item.durationMinutes} min - MET ${item.met} - ${item.weightKg} kg',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _openActivityDialog(
                              context,
                              activity: item,
                              date: _date,
                              defaultWeight: profile?.weightKg ?? 70,
                            );
                          } else {
                            try {
                              await ref
                                  .read(activitiesRepositoryProvider)
                                  .delete(item.id);
                              ref.invalidate(activityEntriesProvider(dateKey));
                              ref.invalidate(dashboardSummaryProvider);
                              ref.invalidate(homeTimelineProvider);
                            } catch (error) {
                              if (context.mounted) {
                                showErrorSnackBar(context, error);
                              }
                            }
                          }
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'edit', child: Text('Editar')),
                          PopupMenuItem(
                            value: 'delete',
                            child: Text('Eliminar'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _openActivityDialog(
    BuildContext context, {
    ActivityEntry? activity,
    required DateTime date,
    required double defaultWeight,
  }) {
    final dateKey = formatDateKey(_date);
    showDialog<void>(
      context: context,
      builder: (_) => _ActivityDialog(
        activity: activity,
        date: date,
        defaultWeight: defaultWeight,
        onSubmit: (input) async {
          final repository = ref.read(activitiesRepositoryProvider);
          if (activity == null) {
            await repository.create(input);
          } else {
            await repository.update(activity.id, input);
          }
          ref.invalidate(activityEntriesProvider(dateKey));
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(homeTimelineProvider);
        },
      ),
    );
  }
}

class _ActivityDialog extends StatefulWidget {
  const _ActivityDialog({
    required this.date,
    required this.defaultWeight,
    required this.onSubmit,
    this.activity,
  });

  final DateTime date;
  final double defaultWeight;
  final ActivityEntry? activity;
  final Future<void> Function(ActivityEntryInput input) onSubmit;

  @override
  State<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<_ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _durationController;
  late final TextEditingController _metController;
  late final TextEditingController _weightController;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final activity = widget.activity;
    _nameController = TextEditingController(text: activity?.activityName ?? '');
    _durationController = TextEditingController(
      text: (activity?.durationMinutes ?? 30).toString(),
    );
    _metController = TextEditingController(
      text: (activity?.met ?? 4).toString(),
    );
    _weightController = TextEditingController(
      text: (activity?.weightKg ?? widget.defaultWeight).toString(),
    );
    _date = activity?.date ?? widget.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _metController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  double get _calories {
    final duration = int.tryParse(_durationController.text) ?? 0;
    final met = tryParseDecimal(_metController.text) ?? 0;
    final weight = tryParseDecimal(_weightController.text) ?? 0;
    return met * weight * (duration / 60);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => _date = picked);
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
        ActivityEntryInput(
          activityName: _nameController.text,
          durationMinutes: int.parse(_durationController.text),
          met: parseDecimal(_metController.text),
          weightKg: parseDecimal(_weightController.text),
          date: _date,
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
      title: Text(
        widget.activity == null ? 'Nova atividade' : 'Editar atividade',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Atividade'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duracao min'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _positiveInt,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DoubleField(
                      controller: _metController,
                      label: 'MET',
                      onChanged: () => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _DoubleField(
                      controller: _weightController,
                      label: 'Peso kg',
                      onChanged: () => setState(() {}),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.event_outlined),
                label: Text(formatDate(_date)),
              ),
              const SizedBox(height: 12),
              Text('${_calories.round()} kcal'),
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

class _DoubleField extends StatelessWidget {
  const _DoubleField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final parsed = tryParseDecimal(value);
        if (parsed == null || parsed <= 0) {
          return 'Invalido.';
        }
        return null;
      },
      onChanged: (_) => onChanged(),
    );
  }
}

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return 'Obrigatorio.';
  }
  return null;
}

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) {
    return 'Invalido.';
  }
  return null;
}
