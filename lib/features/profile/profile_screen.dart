import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/user_profile.dart';
import '../../providers/app_providers.dart';
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
