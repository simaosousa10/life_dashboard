import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../data/models/daily_review.dart';
import '../../data/models/day_plan.dart';
import '../../data/models/global_search_result.dart';
import '../../data/models/habit.dart';
import '../../data/models/model_helpers.dart';
import '../../data/models/todo_item.dart';
import '../../providers/app_providers.dart';
import '../dashboard/timeline_helpers.dart';
import '../dashboard/widgets/current_activity_card.dart';
import '../dashboard/widgets/empty_state_card.dart';
import '../dashboard/widgets/home_header.dart';
import '../dashboard/widgets/upcoming_activity_card.dart';
import '../habits/widgets/today_habits_check_in.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key, this.onSelectTab});

  final ValueChanged<int>? onSelectTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = formatDateKey(todayDate());
    final plan = ref.watch(dayPlanProvider(dateKey));
    final now = ref.watch(timelineClockProvider).valueOrNull ?? DateTime.now();

    return ColoredBox(
      color: const Color(0xFF10151F),
      child: SafeArea(
        child: AppAsyncValue(
          value: plan,
          onRetry: () => ref.invalidate(dayPlanProvider(dateKey)),
          builder: (data) {
            final currentItem = currentTimelineItem(data.timelineItems, now);
            final upcomingItems = upcomingTimelineItems(
              data.timelineItems,
              now,
            );

            return RefreshIndicator(
              color: const Color(0xFFFFA726),
              backgroundColor: const Color(0xFF1F2937),
              onRefresh: () async => invalidateDashboardData(ref),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
                children: [
                  HomeHeader(
                    displayName: data.displayName,
                    date: data.date,
                    onSearchTap: () => showDialog<void>(
                      context: context,
                      builder: (_) => const _GlobalSearchDialog(),
                    ),
                    onProfileTap: () => onSelectTab?.call(4),
                  ),
                  const SizedBox(height: 22),
                  const _SectionTitle('Agora'),
                  const SizedBox(height: 8),
                  if (currentItem == null)
                    const EmptyStateCard(
                      icon: Icons.self_improvement_outlined,
                      message: 'Sem atividade neste momento',
                    )
                  else
                    CurrentActivityCard(item: currentItem, now: now),
                  const SizedBox(height: 20),
                  const _SectionTitle('A seguir'),
                  const SizedBox(height: 8),
                  if (upcomingItems.isEmpty)
                    const EmptyStateCard(
                      icon: Icons.event_available_outlined,
                      message: 'Nada mais planeado para hoje',
                    )
                  else
                    ...upcomingItems.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: UpcomingActivityCard(item: item),
                      ),
                    ),
                  const SizedBox(height: 14),
                  const _SectionTitle('Tarefas de hoje'),
                  const SizedBox(height: 8),
                  _TodayTasksCard(tasks: data.todos),
                  const SizedBox(height: 14),
                  const _SectionTitle('Fecho do dia'),
                  const SizedBox(height: 8),
                  const TodayHabitsCheckIn(),
                  const SizedBox(height: 8),
                  _EndOfDayReviewCard(data: data),
                  const SizedBox(height: 14),
                  const _SectionTitle('Resumo'),
                  const SizedBox(height: 8),
                  _DailySummary(data: data),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _GlobalSearchDialog extends ConsumerStatefulWidget {
  const _GlobalSearchDialog();

  @override
  ConsumerState<_GlobalSearchDialog> createState() =>
      _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends ConsumerState<_GlobalSearchDialog> {
  final _controller = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final results = ref.watch(globalSearchProvider(_query));

    return AlertDialog(
      title: const Text('Pesquisa global'),
      content: SizedBox(
        width: 560,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _controller,
              autofocus: true,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                labelText: 'Pesquisar',
                hintText: 'Tarefas, eventos, notas ou habitos',
              ),
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            SizedBox(
              height: 320,
              child: _query.trim().length < 2
                  ? const Center(child: Text('Escreve pelo menos 2 letras.'))
                  : results.when(
                      loading: () =>
                          const Center(child: CircularProgressIndicator()),
                      error: (error, _) => Center(child: Text('$error')),
                      data: (items) {
                        if (items.isEmpty) {
                          return const Center(child: Text('Sem resultados.'));
                        }
                        return ListView.separated(
                          itemCount: items.length,
                          separatorBuilder: (context, index) =>
                              const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return ListTile(
                              leading: Icon(_searchResultIcon(item.type)),
                              title: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                item.subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              trailing: Text(item.typeLabel),
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

IconData _searchResultIcon(GlobalSearchResultType type) {
  return switch (type) {
    GlobalSearchResultType.todo => Icons.task_alt,
    GlobalSearchResultType.event => Icons.event_outlined,
    GlobalSearchResultType.note => Icons.sticky_note_2_outlined,
    GlobalSearchResultType.habit => Icons.fact_check_outlined,
  };
}

class _EndOfDayReviewCard extends ConsumerWidget {
  const _EndOfDayReviewCard({required this.data});

  final DayPlanData data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateKey = formatDateKey(data.date);
    final review = ref.watch(dailyReviewProvider(dateKey));

    return review.when(
      loading: () => const _EndOfDayContainer(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => _EndOfDayContainer(
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Color(0xFFFFD166)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                error.toString(),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withValues(alpha: 0.70)),
              ),
            ),
            TextButton(
              onPressed: () => ref.invalidate(dailyReviewProvider(dateKey)),
              child: const Text('Tentar'),
            ),
          ],
        ),
      ),
      data: (dailyReview) {
        final isClosed = dailyReview != null;
        return _EndOfDayContainer(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isClosed
                        ? Icons.check_circle_outline
                        : Icons.flag_circle_outlined,
                    color: const Color(0xFFFFD166),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isClosed ? 'Dia fechado' : 'Check-in final',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${data.completedHabits}/${data.totalHabits} habitos, '
                          '${data.completedTasks}/${data.totalTasks} tarefas, '
                          '${data.waterMl}/${data.waterGoalMl} ml',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.66),
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: () => showDialog<void>(
                      context: context,
                      builder: (_) =>
                          _EndOfDayDialog(data: data, review: dailyReview),
                    ),
                    child: Text(isClosed ? 'Editar fecho' : 'Fechar dia'),
                  ),
                ],
              ),
              if (dailyReview?.note != null || dailyReview?.mood != null) ...[
                const SizedBox(height: 10),
                Text(
                  [
                    if (dailyReview?.mood != null)
                      'Mood ${dailyReview!.mood}/5',
                    if (dailyReview?.note != null) dailyReview!.note!,
                  ].join(' - '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.72)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _EndOfDayContainer extends StatelessWidget {
  const _EndOfDayContainer({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: child,
    );
  }
}

class _EndOfDayDialog extends ConsumerStatefulWidget {
  const _EndOfDayDialog({required this.data, required this.review});

  final DayPlanData data;
  final DailyReview? review;

  @override
  ConsumerState<_EndOfDayDialog> createState() => _EndOfDayDialogState();
}

class _EndOfDayDialogState extends ConsumerState<_EndOfDayDialog> {
  late final TextEditingController _noteController;
  late final Set<String> _selectedTaskIds;
  late final Set<String> _selectedHabitIds;
  late final Map<String, TextEditingController> _habitValueControllers;
  int? _mood;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.review?.note ?? '');
    _mood = widget.review?.mood;
    _selectedTaskIds = widget.data.todos
        .where((todo) => todo.isCompleted)
        .map((todo) => todo.id)
        .toSet();
    _selectedHabitIds = widget.data.habits
        .where((entry) => entry.log?.isCompleted == true)
        .map((entry) => entry.habit.id)
        .toSet();
    _habitValueControllers = {
      for (final entry in widget.data.habits)
        if (entry.habit.targetType != HabitTargetType.boolean)
          entry.habit.id: TextEditingController(
            text:
                entry.log?.value?.toString() ??
                entry.habit.targetValue?.toString() ??
                '',
          ),
    };
  }

  @override
  void dispose() {
    _noteController.dispose();
    for (final controller in _habitValueControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final todosRepository = ref.read(todosRepositoryProvider);
      final habitsRepository = ref.read(habitsRepositoryProvider);
      final reviewsRepository = ref.read(dailyReviewsRepositoryProvider);

      for (final todo in widget.data.todos) {
        final selected = _selectedTaskIds.contains(todo.id);
        if (todo.isCompleted != selected) {
          await todosRepository.setCompleted(todo.id, selected);
        }
      }

      for (final entry in widget.data.habits) {
        final selected = _selectedHabitIds.contains(entry.habit.id);
        final value = _habitValueControllers[entry.habit.id] == null
            ? entry.log?.value
            : tryParseDecimal(_habitValueControllers[entry.habit.id]!.text);
        await habitsRepository.upsertHabitLog(
          HabitLogInput(
            habitId: entry.habit.id,
            date: widget.data.date,
            isCompleted: selected,
            value: value,
            note: entry.log?.note,
          ),
        );
      }

      await reviewsRepository.save(
        DailyReviewInput(
          date: widget.data.date,
          note: blankToNull(_noteController.text),
          mood: _mood,
        ),
      );

      invalidateDashboardData(ref);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = widget.data.todos
        .where((todo) => !todo.isCompleted)
        .toList();

    return AlertDialog(
      title: const Text('Fechar dia'),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _DialogSummary(data: widget.data),
              const SizedBox(height: 16),
              Text(
                'Tarefas de hoje',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              if (widget.data.todos.isEmpty)
                const Text('Sem tarefas para hoje.')
              else
                ...widget.data.todos.map(
                  (todo) => CheckboxListTile(
                    value: _selectedTaskIds.contains(todo.id),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      todo.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: todo.isCompleted
                        ? const Text('Ja estava concluida')
                        : null,
                    onChanged: (value) {
                      setState(() {
                        if (value ?? false) {
                          _selectedTaskIds.add(todo.id);
                        } else {
                          _selectedTaskIds.remove(todo.id);
                        }
                      });
                    },
                  ),
                ),
              const SizedBox(height: 12),
              Text('Habitos', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              if (widget.data.habits.isEmpty)
                const Text('Sem habitos planeados para hoje.')
              else
                ...widget.data.habits.map(_buildHabitRow),
              const SizedBox(height: 12),
              Text('Mood', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  for (var value = 1; value <= 5; value += 1)
                    ChoiceChip(
                      label: Text('$value'),
                      selected: _mood == value,
                      onSelected: (selected) {
                        setState(() => _mood = selected ? value : null);
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Nota rapida',
                  hintText: 'Como correu o dia?',
                ),
              ),
              if (pendingTasks.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  '${pendingTasks.length} tarefa(s) ainda pendente(s). Podes fechar o dia na mesma.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
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
          child: Text(_saving ? 'A guardar...' : 'Guardar fecho'),
        ),
      ],
    );
  }

  Widget _buildHabitRow(TodayHabitEntry entry) {
    final habit = entry.habit;
    final selected = _selectedHabitIds.contains(habit.id);
    final valueController = _habitValueControllers[habit.id];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        children: [
          CheckboxListTile(
            value: selected,
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              habit.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(_habitTargetText(habit)),
            onChanged: (value) {
              setState(() {
                if (value ?? false) {
                  _selectedHabitIds.add(habit.id);
                } else {
                  _selectedHabitIds.remove(habit.id);
                }
              });
            },
          ),
          if (valueController != null)
            TextField(
              controller: valueController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: InputDecoration(
                labelText: habit.targetType == HabitTargetType.duration
                    ? 'Duracao'
                    : 'Quantidade',
                suffixText: habit.targetUnit,
              ),
            ),
        ],
      ),
    );
  }
}

class _DialogSummary extends StatelessWidget {
  const _DialogSummary({required this.data});

  final DayPlanData data;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _SummaryPill(
          label: 'Agua',
          value: '${data.waterMl}/${data.waterGoalMl} ml',
        ),
        _SummaryPill(label: 'Refeicoes', value: '${data.mealEntries.length}'),
        _SummaryPill(
          label: 'Atividades',
          value: '${data.activityEntries.length}',
        ),
        _SummaryPill(label: 'Ingeridas', value: '${data.caloriesIn} kcal'),
        _SummaryPill(label: 'Gastas', value: '${data.caloriesOut} kcal'),
      ],
    );
  }
}

class _SummaryPill extends StatelessWidget {
  const _SummaryPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text('$label: $value'),
      visualDensity: VisualDensity.compact,
    );
  }
}

String _habitTargetText(Habit habit) {
  if (habit.targetType == HabitTargetType.boolean) {
    return 'Feito / nao feito';
  }
  final value = habit.targetValue;
  final unit = habit.targetUnit;
  if (value == null) {
    return habit.targetType.label;
  }
  return 'Objetivo: ${value.toStringAsFixed(value.truncateToDouble() == value ? 0 : 1)} ${unit ?? ''}'
      .trim();
}

class _DailySummary extends StatelessWidget {
  const _DailySummary({required this.data});

  final DayPlanData data;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 620;
        return GridView.count(
          crossAxisCount: wide ? 4 : 2,
          childAspectRatio: wide ? 2.9 : 2.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          children: [
            _SummaryTile(
              label: 'Tarefas',
              value: '${data.completedTasks}/${data.totalTasks}',
              icon: Icons.task_alt,
            ),
            _SummaryTile(
              label: 'Habitos',
              value: '${data.completedHabits}/${data.totalHabits}',
              icon: Icons.fact_check_outlined,
            ),
            _SummaryTile(
              label: 'Água',
              value: '${data.waterMl}/${data.waterGoalMl} ml',
              icon: Icons.water_drop_outlined,
            ),
            _SummaryTile(
              label: 'Ingeridas',
              value: '${data.caloriesIn} kcal',
              icon: Icons.restaurant_outlined,
            ),
            _SummaryTile(
              label: 'Gastas',
              value: '${data.caloriesOut} kcal',
              icon: Icons.local_fire_department_outlined,
            ),
          ],
        );
      },
    );
  }
}

class _TodayTasksCard extends ConsumerWidget {
  const _TodayTasksCard({required this.tasks});

  final List<TodoItem> tasks;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const EmptyStateCard(
        icon: Icons.task_alt,
        message: 'Sem tarefas para hoje',
      );
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Column(
        children: tasks.take(5).map((task) {
          return CheckboxListTile(
            value: task.isCompleted,
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            activeColor: const Color(0xFFFFA726),
            checkColor: Colors.black,
            onChanged: (value) async {
              try {
                await ref
                    .read(todosRepositoryProvider)
                    .setCompleted(task.id, value ?? false);
                invalidateDashboardData(ref);
              } catch (error) {
                if (context.mounted) {
                  showErrorSnackBar(context, error);
                }
              }
            },
            title: Text(
              task.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                decoration: task.isCompleted
                    ? TextDecoration.lineThrough
                    : null,
              ),
            ),
            subtitle: Text(
              [
                if (task.dueTime != null) compactTime(task.dueTime!),
                task.priority,
                if (task.recurringTaskId != null) 'recorrente',
              ].join(' - '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.62)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, color: const Color(0xFFFFD166), size: 19),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
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
        ],
      ),
    );
  }
}
