import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/schedule_block.dart';
import '../../providers/app_providers.dart';

class ScheduleScreen extends ConsumerWidget {
  const ScheduleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final blocks = ref.watch(scheduleBlocksProvider);

    return Scaffold(
      body: AppAsyncValue(
        value: blocks,
        onRetry: () => ref.invalidate(scheduleBlocksProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const EmptyState(
              icon: Icons.calendar_view_week_outlined,
              title: 'Sem blocos no horario',
              message: 'Adiciona aulas, estudo, trabalho ou rotinas.',
            );
          }

          return RefreshIndicator(
            onRefresh: () async => invalidateUserScopedData(ref),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(child: Text(item.weekday.toString())),
                    title: Text(item.title),
                    subtitle: Text(
                      '${AppConstants.weekdays[item.weekday]} - ${compactTime(item.startTime)}-${compactTime(item.endTime)}\n${item.category}${item.description == null ? '' : ' - ${item.description}'}',
                    ),
                    isThreeLine: item.description != null,
                    trailing: PopupMenuButton<String>(
                      onSelected: (value) async {
                        if (value == 'edit') {
                          _openScheduleDialog(context, ref, item);
                        } else {
                          try {
                            await ref
                                .read(scheduleRepositoryProvider)
                                .delete(item.id);
                            ref.invalidate(scheduleBlocksProvider);
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
                        PopupMenuItem(value: 'delete', child: Text('Eliminar')),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openScheduleDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Bloco'),
      ),
    );
  }

  void _openScheduleDialog(
    BuildContext context,
    WidgetRef ref, [
    ScheduleBlock? block,
  ]) {
    showDialog<void>(
      context: context,
      builder: (_) => _ScheduleDialog(
        block: block,
        onSubmit: (input) async {
          final repository = ref.read(scheduleRepositoryProvider);
          if (block == null) {
            await repository.create(input);
          } else {
            await repository.update(block.id, input);
          }
          ref.invalidate(scheduleBlocksProvider);
          ref.invalidate(homeTimelineProvider);
        },
      ),
    );
  }
}

class _ScheduleDialog extends StatefulWidget {
  const _ScheduleDialog({required this.onSubmit, this.block});

  final ScheduleBlock? block;
  final Future<void> Function(ScheduleBlockInput input) onSubmit;

  @override
  State<_ScheduleDialog> createState() => _ScheduleDialogState();
}

class _ScheduleDialogState extends State<_ScheduleDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late int _weekday;
  late String _category;
  late TimeOfDay _start;
  late TimeOfDay _end;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final block = widget.block;
    _titleController = TextEditingController(text: block?.title ?? '');
    _descriptionController = TextEditingController(
      text: block?.description ?? '',
    );
    _weekday = block?.weekday ?? DateTime.now().weekday;
    _category = block?.category ?? AppConstants.scheduleCategories.first;
    _start = _parseTime(block?.startTime ?? '09:00');
    _end = _parseTime(block?.endTime ?? '10:00');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _start = picked;
        } else {
          _end = picked;
        }
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_minutes(_end) <= _minutes(_start)) {
      setState(() => _error = 'A hora de fim deve ser posterior ao inicio.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        ScheduleBlockInput(
          title: _titleController.text,
          description: blankToNull(_descriptionController.text),
          weekday: _weekday,
          startTime: _formatTime(_start),
          endTime: _formatTime(_end),
          category: _category,
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
      title: Text(widget.block == null ? 'Novo bloco' : 'Editar bloco'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              DropdownButtonFormField<int>(
                initialValue: _weekday,
                decoration: const InputDecoration(labelText: 'Dia'),
                items: AppConstants.weekdays.entries
                    .map(
                      (entry) => DropdownMenuItem(
                        value: entry.key,
                        child: Text(entry.value),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _weekday = value!),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _category,
                decoration: const InputDecoration(labelText: 'Categoria'),
                items: AppConstants.scheduleCategories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(category),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() => _category = value!),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: true),
                      icon: const Icon(Icons.schedule),
                      label: Text(_formatTime(_start)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickTime(isStart: false),
                      icon: const Icon(Icons.schedule),
                      label: Text(_formatTime(_end)),
                    ),
                  ),
                ],
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

TimeOfDay _parseTime(String value) {
  final parts = value.split(':');
  return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
}

String _formatTime(TimeOfDay value) {
  final hour = value.hour.toString().padLeft(2, '0');
  final minute = value.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

int _minutes(TimeOfDay value) => value.hour * 60 + value.minute;
