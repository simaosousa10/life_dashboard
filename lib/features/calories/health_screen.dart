import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/summary_card.dart';
import '../../core/widgets/today_item_card.dart';
import '../../data/models/activity_entry.dart';
import '../../data/models/meal_entry.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/water_entry.dart';
import '../../providers/app_providers.dart';

class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen> {
  @override
  Widget build(BuildContext context) {
    final dateKey = formatDateKey(todayDate());
    final profile = ref.watch(userProfileProvider).valueOrNull;
    final water = ref.watch(waterEntriesProvider(dateKey));
    final meals = ref.watch(mealEntriesProvider(dateKey));
    final activities = ref.watch(activityEntriesProvider(dateKey));

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async => invalidateUserScopedData(ref),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _WaterSection(
              water: water,
              goalMl: profile?.dailyWaterGoalMl ?? 2000,
              onAddWater: (amount) async {
                await ref
                    .read(waterRepositoryProvider)
                    .add(WaterEntryInput(amountMl: amount, date: todayDate()));
                invalidateUserScopedData(ref);
              },
            ),
            const SizedBox(height: 16),
            _MealsSection(
              meals: meals,
              calorieGoal: profile?.dailyCalorieGoal ?? 2200,
              onAddMeal: (input) async {
                await ref.read(mealsRepositoryProvider).create(input);
                invalidateUserScopedData(ref);
              },
            ),
            const SizedBox(height: 16),
            _ActivitiesSection(
              activities: activities,
              weightKg: profile?.weightKg ?? 70,
              onAddActivity: (input) async {
                await ref.read(activitiesRepositoryProvider).create(input);
                invalidateUserScopedData(ref);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _WaterSection extends StatelessWidget {
  const _WaterSection({
    required this.water,
    required this.goalMl,
    required this.onAddWater,
  });

  final AsyncValue<List<WaterEntry>> water;
  final int goalMl;
  final Future<void> Function(int amountMl) onAddWater;

  @override
  Widget build(BuildContext context) {
    return water.when(
      data: (items) {
        final total = items.fold(0, (sum, item) => sum + item.amountMl);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryCard(
                  title: 'Água de hoje',
                  value: '$total ml',
                  subtitle: 'objetivo $goalMl ml',
                  progress: goalMl == 0 ? null : total / goalMl,
                  progressLabel: '$total ml consumidos',
                  icon: Icons.water_drop_outlined,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onAddWater(250),
                        icon: const Icon(Icons.add),
                        label: const Text('+250 ml'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.tonalIcon(
                        onPressed: () => onAddWater(500),
                        icon: const Icon(Icons.add),
                        label: const Text('+500 ml'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filledTonal(
                      tooltip: 'Valor personalizado',
                      onPressed: () => _openWaterDialog(context, onAddWater),
                      icon: const Icon(Icons.water_drop_outlined),
                    ),
                  ],
                ),
                if (items.isEmpty) ...[
                  const SizedBox(height: 12),
                  const EmptyState(
                    icon: Icons.water_drop_outlined,
                    title: 'Sem água lançada hoje',
                    message:
                        'Usa os botões rápidos para registar a hidratação.',
                  ),
                ] else ...[
                  const SizedBox(height: 12),
                  ...items
                      .take(3)
                      .map(
                        (entry) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TodayItemCard(
                            title: '${entry.amountMl} ml',
                            time: formatDate(entry.date),
                            category: 'água',
                            icon: Icons.water_drop_outlined,
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (error, _) => _ErrorCard(message: friendlyErrorMessage(error)),
    );
  }
}

class _MealsSection extends StatelessWidget {
  const _MealsSection({
    required this.meals,
    required this.calorieGoal,
    required this.onAddMeal,
  });

  final AsyncValue<List<MealEntry>> meals;
  final int calorieGoal;
  final Future<void> Function(MealEntryInput input) onAddMeal;

  @override
  Widget build(BuildContext context) {
    return meals.when(
      data: (items) {
        final calories = items.fold(0, (sum, item) => sum + item.calories);
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryCard(
                  title: 'Calorias ingeridas',
                  value: '$calories kcal',
                  subtitle: 'objetivo $calorieGoal kcal',
                  icon: Icons.restaurant_outlined,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openMealDialog(context, onAddMeal),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar refeição'),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.restaurant_outlined,
                    title: 'Sem refeições hoje',
                    message:
                        'Adiciona as refeições para acompanhar as calorias.',
                  )
                else
                  ...items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TodayItemCard(
                            title: item.mealName,
                            time: formatDate(item.date),
                            category: '${item.calories} kcal',
                            icon: Icons.restaurant_outlined,
                            subtitle:
                                'P ${item.proteinG} g · C ${item.carbsG} g · G ${item.fatG} g',
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (error, _) => _ErrorCard(message: friendlyErrorMessage(error)),
    );
  }
}

class _ActivitiesSection extends StatelessWidget {
  const _ActivitiesSection({
    required this.activities,
    required this.weightKg,
    required this.onAddActivity,
  });

  final AsyncValue<List<ActivityEntry>> activities;
  final double weightKg;
  final Future<void> Function(ActivityEntryInput input) onAddActivity;

  @override
  Widget build(BuildContext context) {
    return activities.when(
      data: (items) {
        final calories = items.fold(
          0,
          (sum, item) => sum + item.caloriesBurned.round(),
        );
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SummaryCard(
                  title: 'Calorias gastas',
                  value: '$calories kcal',
                  subtitle: 'atividades de hoje',
                  icon: Icons.local_fire_department_outlined,
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () => _openActivityDialog(
                    context,
                    onAddActivity,
                    defaultWeight: weightKg,
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('Adicionar atividade'),
                ),
                const SizedBox(height: 12),
                if (items.isEmpty)
                  const EmptyState(
                    icon: Icons.directions_run_outlined,
                    title: 'Sem atividades hoje',
                    message:
                        'Regista treinos ou caminhadas para acompanhar o gasto.',
                  )
                else
                  ...items
                      .take(3)
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: TodayItemCard(
                            title: item.activityName,
                            time: formatDate(item.date),
                            category: '${item.caloriesBurned.round()} kcal',
                            icon: Icons.directions_run_outlined,
                            subtitle:
                                '${item.durationMinutes} min · MET ${item.met} · ${item.weightKg} kg',
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
      loading: () => const _LoadingCard(),
      error: (error, _) => _ErrorCard(message: friendlyErrorMessage(error)),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Center(child: CircularProgressIndicator()),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: EmptyState(
          icon: Icons.error_outline,
          title: 'Erro ao carregar',
          message: message,
        ),
      ),
    );
  }
}

void _openWaterDialog(
  BuildContext context,
  Future<void> Function(int amountMl) onAddWater,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _WaterDialog(onSubmit: onAddWater),
  );
}

void _openMealDialog(
  BuildContext context,
  Future<void> Function(MealEntryInput input) onAddMeal,
) {
  showDialog<void>(
    context: context,
    builder: (_) => _MealDialog(onSubmit: onAddMeal),
  );
}

void _openActivityDialog(
  BuildContext context,
  Future<void> Function(ActivityEntryInput input) onAddActivity, {
  required double defaultWeight,
}) {
  showDialog<void>(
    context: context,
    builder: (_) =>
        _ActivityDialog(defaultWeight: defaultWeight, onSubmit: onAddActivity),
  );
}

class _WaterDialog extends StatefulWidget {
  const _WaterDialog({required this.onSubmit});

  final Future<void> Function(int amountMl) onSubmit;

  @override
  State<_WaterDialog> createState() => _WaterDialogState();
}

class _WaterDialogState extends State<_WaterDialog> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController(text: '250');
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
      await widget.onSubmit(int.parse(_controller.text));
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
      title: const Text('Adicionar água'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _controller,
              decoration: const InputDecoration(labelText: 'Mililitros'),
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                if (parsed == null || parsed <= 0) {
                  return 'Valor inválido.';
                }
                return null;
              },
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

class _MealDialog extends StatefulWidget {
  const _MealDialog({required this.onSubmit});

  final Future<void> Function(MealEntryInput input) onSubmit;

  @override
  State<_MealDialog> createState() => _MealDialogState();
}

class _MealDialogState extends State<_MealDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _caloriesController = TextEditingController();
  final _proteinController = TextEditingController(text: '0');
  final _carbsController = TextEditingController(text: '0');
  final _fatController = TextEditingController(text: '0');
  DateTime _date = todayDate();
  bool _saving = false;
  String? _error;

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
      title: const Text('Nova refeição'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nome'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Obrigatorio.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _caloriesController,
                decoration: const InputDecoration(labelText: 'Calorias'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _proteinController,
                      decoration: const InputDecoration(
                        labelText: 'Proteina g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _carbsController,
                      decoration: const InputDecoration(
                        labelText: 'Hidratos g',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _fatController,
                      decoration: const InputDecoration(labelText: 'Gordura g'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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

class _ActivityDialog extends StatefulWidget {
  const _ActivityDialog({required this.defaultWeight, required this.onSubmit});

  final double defaultWeight;
  final Future<void> Function(ActivityEntryInput input) onSubmit;

  @override
  State<_ActivityDialog> createState() => _ActivityDialogState();
}

class _ActivityDialogState extends State<_ActivityDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _durationController = TextEditingController(text: '30');
  final _metController = TextEditingController(text: '4');
  late final TextEditingController _weightController;
  DateTime _date = todayDate();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.defaultWeight.toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _durationController.dispose();
    _metController.dispose();
    _weightController.dispose();
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
      title: const Text('Nova atividade'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Atividade'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Obrigatorio.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _durationController,
                decoration: const InputDecoration(labelText: 'Duração min'),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  final parsed = int.tryParse(value ?? '');
                  if (parsed == null || parsed <= 0) {
                    return 'Valor inválido.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _metController,
                      decoration: const InputDecoration(labelText: 'MET'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _weightController,
                      decoration: const InputDecoration(labelText: 'Peso kg'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
