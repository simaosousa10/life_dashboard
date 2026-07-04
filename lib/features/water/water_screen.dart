import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/metric_card.dart';
import '../../data/models/water_entry.dart';
import '../../providers/app_providers.dart';

class WaterScreen extends ConsumerStatefulWidget {
  const WaterScreen({super.key});

  @override
  ConsumerState<WaterScreen> createState() => _WaterScreenState();
}

class _WaterScreenState extends ConsumerState<WaterScreen> {
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

  Future<void> _addWater(int amountMl, {bool showSnack = true}) async {
    try {
      await ref
          .read(waterRepositoryProvider)
          .add(WaterEntryInput(amountMl: amountMl, date: _date));
      ref.invalidate(waterEntriesProvider(formatDateKey(_date)));
      ref.invalidate(dayPlanProvider);
      ref.invalidate(weeklyReviewProvider);
    } catch (error) {
      if (showSnack && mounted) {
        showErrorSnackBar(context, error);
      }
      if (!showSnack) {
        rethrow;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = formatDateKey(_date);
    final entries = ref.watch(waterEntriesProvider(dateKey));
    final profile = ref.watch(userProfileProvider).valueOrNull;

    return AppAsyncValue(
      value: entries,
      onRetry: () => ref.invalidate(waterEntriesProvider(dateKey)),
      builder: (items) {
        final total = items.fold(0, (sum, item) => sum + item.amountMl);
        final goal = profile?.dailyWaterGoalMl ?? 2000;

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(waterEntriesProvider(dateKey));
            ref.invalidate(dayPlanProvider);
            ref.invalidate(weeklyReviewProvider);
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
                title: 'Total diario',
                value: '$total ml',
                subtitle: 'objetivo $goal ml',
                icon: Icons.water_drop_outlined,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addWater(250),
                      icon: const Icon(Icons.add),
                      label: const Text('250 ml'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _addWater(500),
                      icon: const Icon(Icons.add),
                      label: const Text('500 ml'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filledTonal(
                    tooltip: 'Adicionar',
                    onPressed: () => _openWaterDialog(context),
                    icon: const Icon(Icons.water_drop),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (items.isEmpty)
                const Card(
                  child: ListTile(
                    leading: Icon(Icons.water_drop_outlined),
                    title: Text('Sem entradas neste dia'),
                  ),
                )
              else
                ...items.map(
                  (entry) => Card(
                    child: ListTile(
                      leading: const Icon(Icons.water_drop_outlined),
                      title: Text('${entry.amountMl} ml'),
                      subtitle: Text(formatDate(entry.date)),
                      trailing: IconButton(
                        tooltip: 'Eliminar',
                        icon: const Icon(Icons.delete_outline),
                        onPressed: () async {
                          try {
                            await ref
                                .read(waterRepositoryProvider)
                                .delete(entry.id);
                            ref.invalidate(waterEntriesProvider(dateKey));
                            ref.invalidate(dayPlanProvider);
                            ref.invalidate(weeklyReviewProvider);
                          } catch (error) {
                            if (context.mounted) {
                              showErrorSnackBar(context, error);
                            }
                          }
                        },
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

  void _openWaterDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => _WaterDialog(
        onSubmit: (amount) => _addWater(amount, showSnack: false),
      ),
    );
  }
}

class _WaterDialog extends StatefulWidget {
  const _WaterDialog({required this.onSubmit});

  final Future<void> Function(int amountMl) onSubmit;

  @override
  State<_WaterDialog> createState() => _WaterDialogState();
}

class _WaterDialogState extends State<_WaterDialog> {
  final _controller = TextEditingController(text: '250');
  final _formKey = GlobalKey<FormState>();
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
      title: const Text('Adicionar agua'),
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
                  return 'Valor invalido.';
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
