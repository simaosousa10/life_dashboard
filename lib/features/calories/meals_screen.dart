import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/metric_card.dart';
import '../../data/models/meal_entry.dart';
import '../../data/models/model_helpers.dart';
import '../../providers/app_providers.dart';

class MealsScreen extends ConsumerStatefulWidget {
  const MealsScreen({super.key});

  @override
  ConsumerState<MealsScreen> createState() => _MealsScreenState();
}

class _MealsScreenState extends ConsumerState<MealsScreen> {
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
    final meals = ref.watch(mealEntriesProvider(dateKey));
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return AppAsyncValue(
      value: meals,
      onRetry: () => ref.invalidate(mealEntriesProvider(dateKey)),
      builder: (items) {
        final calories = items.fold(0, (sum, item) => sum + item.calories);
        final protein = items.fold(0.0, (sum, item) => sum + item.proteinG);
        final carbs = items.fold(0.0, (sum, item) => sum + item.carbsG);
        final fat = items.fold(0.0, (sum, item) => sum + item.fatG);

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(mealEntriesProvider(dateKey));
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
                title: 'Calorias ingeridas',
                value: '$calories kcal',
                subtitle: 'objetivo ${profile?.dailyCalorieGoal ?? 2200} kcal',
                icon: Icons.restaurant_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                'Proteina ${protein.toStringAsFixed(1)} g - Hidratos ${carbs.toStringAsFixed(1)} g - Gordura ${fat.toStringAsFixed(1)} g',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () => _openMealDialog(context, date: _date),
                icon: const Icon(Icons.add),
                label: const Text('Adicionar refeicao'),
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.restaurant_outlined),
                    title: Text('Sem refeicoes neste dia'),
                  ),
                )
              else
                ...items.map(
                  (item) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.restaurant_outlined),
                      title: Text(item.mealName),
                      subtitle: Text(
                        '${item.calories} kcal - P ${item.proteinG} g - C ${item.carbsG} g - G ${item.fatG} g',
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          if (value == 'edit') {
                            _openMealDialog(context, meal: item, date: _date);
                          } else {
                            try {
                              await ref
                                  .read(mealsRepositoryProvider)
                                  .delete(item.id);
                              ref.invalidate(mealEntriesProvider(dateKey));
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

  void _openMealDialog(
    BuildContext context, {
    MealEntry? meal,
    required DateTime date,
  }) {
    final dateKey = formatDateKey(_date);
    showDialog<void>(
      context: context,
      builder: (_) => _MealDialog(
        meal: meal,
        date: date,
        onSubmit: (input) async {
          final repository = ref.read(mealsRepositoryProvider);
          if (meal == null) {
            await repository.create(input);
          } else {
            await repository.update(meal.id, input);
          }
          ref.invalidate(mealEntriesProvider(dateKey));
          ref.invalidate(dashboardSummaryProvider);
          ref.invalidate(homeTimelineProvider);
        },
      ),
    );
  }
}

class _MealDialog extends StatefulWidget {
  const _MealDialog({required this.date, required this.onSubmit, this.meal});

  final DateTime date;
  final MealEntry? meal;
  final Future<void> Function(MealEntryInput input) onSubmit;

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _proteinController;
  late final TextEditingController _carbsController;
  late final TextEditingController _fatController;
  late DateTime _date;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final meal = widget.meal;
    _nameController = TextEditingController(text: meal?.mealName ?? '');
    _caloriesController = TextEditingController(
      text: (meal?.calories ?? '').toString(),
    );
    _proteinController = TextEditingController(
      text: (meal?.proteinG ?? 0).toString(),
    );
    _carbsController = TextEditingController(
      text: (meal?.carbsG ?? 0).toString(),
    );
    _fatController = TextEditingController(text: (meal?.fatG ?? 0).toString());
    _date = meal?.date ?? widget.date;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _caloriesController.dispose();
    _proteinController.dispose();
    _carbsController.dispose();
    _fatController.dispose();
    super.dispose();
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
        MealEntryInput(
          mealName: _nameController.text,
          calories: int.parse(_caloriesController.text),
          proteinG: parseDecimal(_proteinController.text),
          carbsG: parseDecimal(_carbsController.text),
          fatG: parseDecimal(_fatController.text),
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
      title: Text(widget.meal == null ? 'Nova refeicao' : 'Editar refeicao'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calorias'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _NumberField(
                      controller: _proteinController,
                      label: 'Proteina g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(
                      controller: _carbsController,
                      label: 'Hidratos g',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _NumberField(
                      controller: _fatController,
                      label: 'Gordura g',
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

class _NumberField extends StatelessWidget {
  const _NumberField({required this.controller, required this.label});

  final TextEditingController controller;
  final String label;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        final parsed = tryParseDecimal(value);
        if (parsed == null || parsed < 0) {
          return 'Invalido.';
        }
        return null;
      },
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
