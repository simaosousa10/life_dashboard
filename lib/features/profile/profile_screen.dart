import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../data/models/app_category.dart';
import '../../data/models/habit.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/weekly_review.dart';
import '../../providers/app_providers.dart';
import '../habits/widgets/habit_form_dialog.dart';
import '../habits/widgets/weekly_habits_dashboard.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      body: AppAsyncValue(
        value: profile,
        onRetry: () => ref.invalidate(userProfileProvider),
        builder: (data) {
          final displayName =
              data?.displayName ??
              (user?.email?.split('@').first ?? 'Utilizador');
          final email = user?.email ?? 'Sem email';
          final weight = data?.weightKg ?? 70;
          final waterGoal = data?.dailyWaterGoalMl ?? 2000;
          final calorieGoal = data?.dailyCalorieGoal ?? 2200;

          return RefreshIndicator(
            onRefresh: () async => invalidateUserScopedData(ref),
            child: ListView(
              padding: const EdgeInsets.all(14),
              children: [
                _ProfileHeader(
                  displayName: displayName,
                  email: email,
                  onEdit: () => _openEditDialog(context, ref, data, user),
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final columns = constraints.maxWidth > 700 ? 3 : 2;
                    return GridView.count(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisCount: columns,
                      childAspectRatio: columns == 2 ? 1.85 : 2.25,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 8,
                      children: [
                        _ProfileMetricCard(
                          label: 'Peso',
                          value: '${weight.toStringAsFixed(1)} kg',
                          icon: Icons.monitor_weight_outlined,
                        ),
                        _ProfileMetricCard(
                          label: 'Agua',
                          value: '$waterGoal ml',
                          icon: Icons.water_drop_outlined,
                        ),
                        _ProfileMetricCard(
                          label: 'Calorias',
                          value: '$calorieGoal kcal',
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 12),
                const WeeklyHabitsDashboard(),
                const SizedBox(height: 12),
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        _SettingsTile(
                          icon: Icons.edit_outlined,
                          title: 'Editar perfil',
                          subtitle: 'Nome, peso e objetivos',
                          onPressed: () =>
                              _openEditDialog(context, ref, data, user),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.fact_check_outlined,
                          title: 'Gerir habitos',
                          subtitle: 'Adicionar novo habito',
                          onPressed: () => _openHabitDialog(context, ref),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.auto_awesome_motion_outlined,
                          title: 'Adicionar template',
                          subtitle: 'Rotina manha, noite, estudo ou saude',
                          onPressed: () => _openTemplateDialog(context, ref),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.category_outlined,
                          title: 'Gerir categorias',
                          subtitle: 'Categorias pessoais simples',
                          onPressed: () => _openCategoriesDialog(context),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.insights_outlined,
                          title: 'Ver revisao semanal',
                          subtitle: 'Tarefas, agua, calorias e check-ins',
                          onPressed: () => _openWeeklyReview(context),
                        ),
                        const Divider(height: 1),
                        _SettingsTile(
                          icon: Icons.logout,
                          title: 'Terminar sessao',
                          subtitle: 'Sair desta conta',
                          onPressed: () => _signOut(context, ref),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _openEditDialog(
    BuildContext context,
    WidgetRef ref,
    UserProfile? profile,
    User? user,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _ProfileDialog(
        profile: profile,
        user: user,
        onSubmit: (input) async {
          await ref.read(profileRepositoryProvider).save(input);
          ref.invalidate(userProfileProvider);
          ref.invalidate(homeDashboardProvider);
          ref.invalidate(homeTimelineProvider);
          ref.invalidate(dashboardSummaryProvider);
        },
      ),
    );
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(authRepositoryProvider).signOut();
      invalidateUserScopedData(ref);
    } catch (error) {
      if (context.mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  void _openHabitDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => HabitFormDialog(
        onSubmit: (input) async {
          await ref.read(habitsRepositoryProvider).createHabit(input);
          invalidateHabitData(ref);
        },
      ),
    );
  }

  void _openWeeklyReview(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _WeeklyReviewDialog(),
    );
  }

  void _openTemplateDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (_) => _HabitTemplateDialog(
        onSubmit: (template) async {
          final repository = ref.read(habitsRepositoryProvider);
          for (final input in template.toHabitInputs()) {
            await repository.createHabit(input);
          }
          invalidateHabitData(ref);
        },
      ),
    );
  }

  void _openCategoriesDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => const _CategoriesDialog(),
    );
  }
}

class _CategoriesDialog extends ConsumerStatefulWidget {
  const _CategoriesDialog();

  @override
  ConsumerState<_CategoriesDialog> createState() => _CategoriesDialogState();
}

class _CategoriesDialogState extends ConsumerState<_CategoriesDialog> {
  final _nameController = TextEditingController();
  final _colorController = TextEditingController(text: '#FFA726');
  final _iconController = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _colorController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  Future<void> _create() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Nome obrigatorio.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await ref
          .read(categoriesRepositoryProvider)
          .create(
            AppCategoryInput(
              name: name,
              color: blankToNull(_colorController.text),
              icon: blankToNull(_iconController.text),
            ),
          );
      _nameController.clear();
      _iconController.clear();
      ref.invalidate(categoriesProvider);
    } catch (error) {
      setState(() => _error = friendlyErrorMessage(error));
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  Future<void> _delete(AppCategory category) async {
    try {
      await ref.read(categoriesRepositoryProvider).delete(category.id);
      ref.invalidate(categoriesProvider);
    } catch (error) {
      if (mounted) {
        showErrorSnackBar(context, error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = ref.watch(categoriesProvider);

    return AlertDialog(
      title: const Text('Categorias'),
      content: SizedBox(
        width: 520,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Nome'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _colorController,
                    decoration: const InputDecoration(labelText: 'Cor'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _iconController,
                    decoration: const InputDecoration(labelText: 'Icone'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _saving ? null : _create,
                icon: const Icon(Icons.add),
                label: Text(_saving ? 'A criar...' : 'Criar'),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            ],
            const SizedBox(height: 12),
            SizedBox(
              height: 280,
              child: AppAsyncValue(
                value: categories,
                onRetry: () => ref.invalidate(categoriesProvider),
                builder: (items) {
                  if (items.isEmpty) {
                    return const Center(child: Text('Sem categorias.'));
                  }
                  return ListView.separated(
                    shrinkWrap: true,
                    itemCount: items.length,
                    separatorBuilder: (context, index) =>
                        const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final category = items[index];
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.label_outline),
                        title: Text(category.name),
                        subtitle: Text(
                          [
                            if (category.color != null) category.color!,
                            if (category.icon != null) category.icon!,
                          ].join(' - '),
                        ),
                        trailing: IconButton(
                          tooltip: 'Apagar categoria',
                          onPressed: () => _delete(category),
                          icon: const Icon(Icons.delete_outline),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _HabitTemplateDialog extends StatefulWidget {
  const _HabitTemplateDialog({required this.onSubmit});

  final Future<void> Function(_HabitTemplate template) onSubmit;

  @override
  State<_HabitTemplateDialog> createState() => _HabitTemplateDialogState();
}

class _HabitTemplateDialogState extends State<_HabitTemplateDialog> {
  var _selected = _habitTemplates.first;
  bool _saving = false;
  String? _error;

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      await widget.onSubmit(_selected);
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
      title: const Text('Adicionar template'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final template in _habitTemplates)
                ListTile(
                  selected: template == _selected,
                  leading: Icon(
                    template == _selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                  ),
                  title: Text(template.title),
                  subtitle: Text(template.description),
                  onTap: () => setState(() => _selected = template),
                ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final habit in _selected.habits)
                      Chip(
                        label: Text(habit.title),
                        visualDensity: VisualDensity.compact,
                      ),
                  ],
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
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
          child: Text(_saving ? 'A criar...' : 'Criar habitos'),
        ),
      ],
    );
  }
}

class _HabitTemplate {
  const _HabitTemplate({
    required this.title,
    required this.description,
    required this.habits,
  });

  final String title;
  final String description;
  final List<_HabitTemplateItem> habits;

  List<HabitInput> toHabitInputs() {
    final today = todayDate();
    return habits
        .map(
          (habit) => HabitInput(
            title: habit.title,
            description: null,
            category: habit.category,
            targetType: habit.targetType,
            targetValue: habit.targetValue,
            targetUnit: habit.targetUnit,
            weekdays: const [1, 2, 3, 4, 5, 6, 7],
            startDate: today,
            isActive: true,
          ),
        )
        .toList();
  }
}

class _HabitTemplateItem {
  const _HabitTemplateItem({
    required this.title,
    required this.category,
    this.targetType = HabitTargetType.boolean,
    this.targetValue,
    this.targetUnit,
  });

  final String title;
  final String category;
  final HabitTargetType targetType;
  final double? targetValue;
  final String? targetUnit;
}

const _habitTemplates = [
  _HabitTemplate(
    title: 'Rotina manha',
    description: 'Arranque basico para preparar o dia.',
    habits: [
      _HabitTemplateItem(title: 'Acordar', category: 'rotina'),
      _HabitTemplateItem(title: 'Lavar dentes', category: 'rotina'),
      _HabitTemplateItem(
        title: 'Beber agua',
        category: 'saude',
        targetType: HabitTargetType.quantity,
        targetValue: 500,
        targetUnit: 'ml',
      ),
      _HabitTemplateItem(
        title: 'Ler 20 min',
        category: 'estudo',
        targetType: HabitTargetType.duration,
        targetValue: 20,
        targetUnit: 'min',
      ),
    ],
  ),
  _HabitTemplate(
    title: 'Rotina noite',
    description: 'Fechar o dia com menos friccao.',
    habits: [
      _HabitTemplateItem(title: 'Preparar roupa/mochila', category: 'rotina'),
      _HabitTemplateItem(title: 'Lavar dentes', category: 'rotina'),
      _HabitTemplateItem(
        title: 'Leitura leve',
        category: 'pessoal',
        targetType: HabitTargetType.duration,
        targetValue: 15,
        targetUnit: 'min',
      ),
      _HabitTemplateItem(title: 'Telemovel fora da cama', category: 'saude'),
    ],
  ),
  _HabitTemplate(
    title: 'Estudo',
    description: 'Base simples para estudo e programacao.',
    habits: [
      _HabitTemplateItem(
        title: 'Deep Work programacao',
        category: 'programacao',
        targetType: HabitTargetType.duration,
        targetValue: 120,
        targetUnit: 'min',
      ),
      _HabitTemplateItem(title: 'Rever UC', category: 'universidade'),
      _HabitTemplateItem(title: 'Trabalhos universidade', category: 'estudo'),
      _HabitTemplateItem(
        title: 'Revisao leve',
        category: 'estudo',
        targetType: HabitTargetType.duration,
        targetValue: 20,
        targetUnit: 'min',
      ),
    ],
  ),
  _HabitTemplate(
    title: 'Saude',
    description: 'Rotina curta para registar saude diaria.',
    habits: [
      _HabitTemplateItem(
        title: 'Beber agua',
        category: 'saude',
        targetType: HabitTargetType.quantity,
        targetValue: 2000,
        targetUnit: 'ml',
      ),
      _HabitTemplateItem(
        title: 'Caminhar',
        category: 'saude',
        targetType: HabitTargetType.duration,
        targetValue: 30,
        targetUnit: 'min',
      ),
      _HabitTemplateItem(title: 'Registar refeicao', category: 'saude'),
      _HabitTemplateItem(title: 'Exercicio', category: 'saude'),
    ],
  ),
];

class _WeeklyReviewDialog extends ConsumerWidget {
  const _WeeklyReviewDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(weeklyReviewProvider);

    return AlertDialog(
      title: const Text('Revisao semanal'),
      content: SizedBox(
        width: 520,
        child: AppAsyncValue(
          value: review,
          onRetry: () => ref.invalidate(weeklyReviewProvider),
          builder: (data) => _WeeklyReviewContent(data: data),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Fechar'),
        ),
      ],
    );
  }
}

class _WeeklyReviewContent extends StatelessWidget {
  const _WeeklyReviewContent({required this.data});

  final WeeklyReviewData data;

  @override
  Widget build(BuildContext context) {
    final bestHabit = data.bestHabit;
    final weakestHabit = data.weakestHabit;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${formatDate(data.weekStart)} - ${formatDate(data.weekEnd)}',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 14),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.25,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: [
              _ReviewMetric(
                label: 'Habitos',
                value: '${(data.habitSummary.completionRate * 100).round()}%',
              ),
              _ReviewMetric(
                label: 'Tarefas feitas',
                value: '${data.completedTasks}',
              ),
              _ReviewMetric(label: 'Vencidas', value: '${data.overdueTasks}'),
              _ReviewMetric(
                label: 'Agua media',
                value: '${data.averageWaterMl} ml',
              ),
              _ReviewMetric(
                label: 'Ingeridas',
                value: '${data.caloriesIn} kcal',
              ),
              _ReviewMetric(label: 'Gastas', value: '${data.caloriesOut} kcal'),
              _ReviewMetric(
                label: 'Check-ins',
                value: '${data.dailyReviewCount}/7',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text('Destaques', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          _HabitHighlight(
            label: 'Mais consistente',
            value: bestHabit == null
                ? 'Sem dados suficientes'
                : _habitReviewText(bestHabit),
          ),
          const SizedBox(height: 8),
          _HabitHighlight(
            label: 'Precisa de atencao',
            value: weakestHabit == null
                ? 'Sem dados suficientes'
                : _habitReviewText(weakestHabit),
          ),
        ],
      ),
    );
  }
}

class _ReviewMetric extends StatelessWidget {
  const _ReviewMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _HabitHighlight extends StatelessWidget {
  const _HabitHighlight({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
    );
  }
}

String _habitReviewText(WeeklyHabitStat stat) {
  return '${stat.habit.title}: ${stat.completedDays}/${stat.plannedDays} dias, '
      '${(stat.completionRate * 100).round()}%, streak ${stat.currentStreak}';
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.displayName,
    required this.email,
    required this.onEdit,
  });

  final String displayName;
  final String email;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                displayName.isEmpty ? '?' : displayName[0].toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    email,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Conta Supabase',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Editar perfil',
              onPressed: onEdit,
              icon: const Icon(Icons.edit_outlined),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  const _ProfileMetricCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Icon(icon, color: colorScheme.primary, size: 22),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onPressed,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      leading: Icon(icon, size: 22),
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleSmall,
      ),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: const Icon(Icons.chevron_right, size: 20),
      onTap: onPressed,
    );
  }
}

class _ProfileDialog extends StatefulWidget {
  const _ProfileDialog({
    required this.onSubmit,
    required this.user,
    this.profile,
  });

  final UserProfile? profile;
  final User? user;
  final Future<void> Function(UserProfileInput input) onSubmit;

  @override
  State<_ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<_ProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _weightController;
  late final TextEditingController _waterGoalController;
  late final TextEditingController _calorieGoalController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _nameController = TextEditingController(
      text: profile?.displayName ?? widget.user?.email?.split('@').first ?? '',
    );
    _weightController = TextEditingController(
      text: (profile?.weightKg ?? 70).toString(),
    );
    _waterGoalController = TextEditingController(
      text: (profile?.dailyWaterGoalMl ?? 2000).toString(),
    );
    _calorieGoalController = TextEditingController(
      text: (profile?.dailyCalorieGoal ?? 2200).toString(),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _weightController.dispose();
    _waterGoalController.dispose();
    _calorieGoalController.dispose();
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
      await widget.onSubmit(
        UserProfileInput(
          displayName: _nameController.text,
          weightKg: parseDecimal(_weightController.text),
          dailyWaterGoalMl: int.parse(_waterGoalController.text),
          dailyCalorieGoal: int.parse(_calorieGoalController.text),
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
      title: const Text('Editar perfil'),
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
                controller: _weightController,
                decoration: const InputDecoration(labelText: 'Peso kg'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: _positiveDouble,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _waterGoalController,
                decoration: const InputDecoration(
                  labelText: 'Objetivo de agua ml',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _positiveInt,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _calorieGoalController,
                decoration: const InputDecoration(
                  labelText: 'Objetivo de calorias kcal',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: _positiveInt,
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
