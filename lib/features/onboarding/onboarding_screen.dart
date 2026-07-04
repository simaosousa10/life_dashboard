import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../data/models/habit.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key, this.initialProfile});

  final UserProfile? initialProfile;

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _weightController = TextEditingController(text: '70');
  final _waterGoalController = TextEditingController(text: '2000');
  final _calorieGoalController = TextEditingController(text: '2200');
  final _selectedTemplates = <_HabitTemplate>{..._defaultTemplates.take(3)};
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final email = ref.read(currentUserProvider)?.email;
    final profile = widget.initialProfile;
    _nameController.text =
        profile?.displayName ?? email?.split('@').first ?? '';
    if (profile != null) {
      _weightController.text = profile.weightKg.toString();
      _waterGoalController.text = profile.dailyWaterGoalMl.toString();
      _calorieGoalController.text = profile.dailyCalorieGoal.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(profileRepositoryProvider)
          .save(
            UserProfileInput(
              displayName: _nameController.text,
              weightKg: parseDecimal(_weightController.text),
              dailyWaterGoalMl: int.parse(_waterGoalController.text),
              dailyCalorieGoal: int.parse(_calorieGoalController.text),
            ),
          );

      final habits = ref.read(habitsRepositoryProvider);
      for (final template in _selectedTemplates) {
        await habits.createHabit(template.toInput());
      }

      invalidateUserScopedData(ref);
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
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Preparar o teu dashboard',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Define os dados base para a Home ficar orientada ao teu dia.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 18),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Nome',
                              ),
                              validator: _required,
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _weightController,
                              decoration: const InputDecoration(
                                labelText: 'Peso kg',
                              ),
                              keyboardType:
                                  const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                              validator: _positiveDouble,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _waterGoalController,
                                    decoration: const InputDecoration(
                                      labelText: 'Agua ml',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: _positiveInt,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextFormField(
                                    controller: _calorieGoalController,
                                    decoration: const InputDecoration(
                                      labelText: 'Calorias kcal',
                                    ),
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    validator: _positiveInt,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Habitos iniciais',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _defaultTemplates.map((template) {
                        final selected = _selectedTemplates.contains(template);
                        return FilterChip(
                          selected: selected,
                          label: Text(template.title),
                          onSelected: (value) {
                            setState(() {
                              if (value) {
                                _selectedTemplates.add(template);
                              } else {
                                _selectedTemplates.remove(template);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    FilledButton.icon(
                      onPressed: _saving ? null : _finish,
                      icon: _saving
                          ? const SizedBox.square(
                              dimension: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.check),
                      label: const Text('Entrar na Home'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HabitTemplate {
  const _HabitTemplate({
    required this.title,
    required this.category,
    required this.targetType,
    this.targetValue,
    this.targetUnit,
  });

  final String title;
  final String category;
  final HabitTargetType targetType;
  final double? targetValue;
  final String? targetUnit;

  HabitInput toInput() {
    return HabitInput(
      title: title,
      category: category,
      targetType: targetType,
      targetValue: targetValue,
      targetUnit: targetUnit,
      weekdays: AppConstants.weekdays.keys.toList(),
      startDate: todayDate(),
      isActive: true,
    );
  }
}

const _defaultTemplates = [
  _HabitTemplate(
    title: 'Lavar dentes',
    category: 'Rotina',
    targetType: HabitTargetType.boolean,
  ),
  _HabitTemplate(
    title: 'Ler 20 min',
    category: 'Estudo',
    targetType: HabitTargetType.duration,
    targetValue: 20,
    targetUnit: 'min',
  ),
  _HabitTemplate(
    title: 'Deep Work programacao',
    category: 'Carreira',
    targetType: HabitTargetType.duration,
    targetValue: 120,
    targetUnit: 'min',
  ),
  _HabitTemplate(
    title: 'Beber agua',
    category: 'Saude',
    targetType: HabitTargetType.quantity,
    targetValue: 2000,
    targetUnit: 'ml',
  ),
  _HabitTemplate(
    title: 'Preparar dia seguinte',
    category: 'Rotina',
    targetType: HabitTargetType.boolean,
  ),
];

String? _required(String? value) {
  if ((value ?? '').trim().isEmpty) {
    return 'Obrigatorio.';
  }
  return null;
}

String? _positiveInt(String? value) {
  final parsed = int.tryParse(value ?? '');
  if (parsed == null || parsed <= 0) {
    return 'Valor invalido.';
  }
  return null;
}

String? _positiveDouble(String? value) {
  final parsed = tryParseDecimal(value);
  if (parsed == null || parsed <= 0) {
    return 'Valor invalido.';
  }
  return null;
}
