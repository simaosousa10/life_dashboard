import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/constants/app_constants.dart';
import '../data/models/activity_entry.dart';
import '../data/models/app_category.dart';
import '../data/models/calendar_event.dart';
import '../data/models/dashboard_summary.dart';
import '../data/models/day_plan.dart';
import '../data/models/daily_review.dart';
import '../data/models/habit.dart';
import '../data/models/global_search_result.dart';
import '../data/models/home_dashboard_data.dart';
import '../data/models/meal_entry.dart';
import '../data/models/recurring_task.dart';
import '../data/models/schedule_block.dart';
import '../data/models/study_note.dart';
import '../data/models/today_timeline_item.dart';
import '../data/models/todo_item.dart';
import '../data/models/user_profile.dart';
import '../data/models/water_entry.dart';
import '../data/models/weekly_review.dart';
import '../data/repositories/activities_repository.dart';
import '../data/repositories/auth_repository.dart';
import '../data/repositories/calendar_repository.dart';
import '../data/repositories/categories_repository.dart';
import '../data/repositories/daily_reviews_repository.dart';
import '../data/repositories/habits_repository.dart';
import '../data/repositories/meals_repository.dart';
import '../data/repositories/notes_repository.dart';
import '../data/repositories/profile_repository.dart';
import '../data/repositories/recurring_tasks_repository.dart';
import '../data/repositories/schedule_repository.dart';
import '../data/repositories/todos_repository.dart';
import '../data/repositories/water_repository.dart';
import '../features/dashboard/timeline_helpers.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = Provider<User?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  final state = ref.watch(authStateProvider);
  return state.maybeWhen(
    data: (authState) => authState.session?.user,
    orElse: () => client.auth.currentUser,
  );
});

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  return ScheduleRepository(ref.watch(supabaseClientProvider));
});

final todosRepositoryProvider = Provider<TodosRepository>((ref) {
  return TodosRepository(ref.watch(supabaseClientProvider));
});

final recurringTasksRepositoryProvider = Provider<RecurringTasksRepository>((
  ref,
) {
  return RecurringTasksRepository(ref.watch(supabaseClientProvider));
});

final notesRepositoryProvider = Provider<NotesRepository>((ref) {
  return NotesRepository(ref.watch(supabaseClientProvider));
});

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return WaterRepository(ref.watch(supabaseClientProvider));
});

final calendarRepositoryProvider = Provider<CalendarRepository>((ref) {
  return CalendarRepository(ref.watch(supabaseClientProvider));
});

final mealsRepositoryProvider = Provider<MealsRepository>((ref) {
  return MealsRepository(ref.watch(supabaseClientProvider));
});

final activitiesRepositoryProvider = Provider<ActivitiesRepository>((ref) {
  return ActivitiesRepository(ref.watch(supabaseClientProvider));
});

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.watch(supabaseClientProvider));
});

final habitsRepositoryProvider = Provider<HabitsRepository>((ref) {
  return HabitsRepository(ref.watch(supabaseClientProvider));
});

final dailyReviewsRepositoryProvider = Provider<DailyReviewsRepository>((ref) {
  return DailyReviewsRepository(ref.watch(supabaseClientProvider));
});

final categoriesRepositoryProvider = Provider<CategoriesRepository>((ref) {
  return CategoriesRepository(ref.watch(supabaseClientProvider));
});

final scheduleBlocksProvider = FutureProvider.autoDispose<List<ScheduleBlock>>((
  ref,
) {
  if (ref.watch(currentUserProvider) == null) {
    return <ScheduleBlock>[];
  }
  return ref.watch(scheduleRepositoryProvider).list();
});

final todosProvider = FutureProvider.autoDispose<List<TodoItem>>((ref) async {
  if (ref.watch(currentUserProvider) == null) {
    return <TodoItem>[];
  }
  await ref
      .watch(recurringTasksRepositoryProvider)
      .generateTasksForDate(todayDate());
  return ref.watch(todosRepositoryProvider).list();
});

final recurringTasksProvider = FutureProvider.autoDispose<List<RecurringTask>>((
  ref,
) {
  if (ref.watch(currentUserProvider) == null) {
    return <RecurringTask>[];
  }
  return ref.watch(recurringTasksRepositoryProvider).list();
});

final habitsProvider = FutureProvider.autoDispose<List<Habit>>((ref) {
  if (ref.watch(currentUserProvider) == null) {
    return <Habit>[];
  }
  return ref.watch(habitsRepositoryProvider).getHabits();
});

final todayHabitEntriesProvider =
    FutureProvider.autoDispose<List<TodayHabitEntry>>((ref) {
      if (ref.watch(currentUserProvider) == null) {
        return <TodayHabitEntry>[];
      }
      return ref.watch(habitsRepositoryProvider).getTodayEntries(todayDate());
    });

final weeklyHabitSummaryProvider =
    FutureProvider.autoDispose<WeeklyHabitSummary>((ref) {
      final today = todayDate();
      final weekStart = today.subtract(Duration(days: today.weekday - 1));
      final weekEnd = weekStart.add(const Duration(days: 6));

      if (ref.watch(currentUserProvider) == null) {
        return WeeklyHabitSummary(
          weekStart: weekStart,
          weekEnd: weekEnd,
          stats: const [],
        );
      }

      return ref
          .watch(habitsRepositoryProvider)
          .getWeeklySummary(weekStart, weekEnd);
    });

final notesProvider = FutureProvider.autoDispose<List<StudyNote>>((ref) {
  if (ref.watch(currentUserProvider) == null) {
    return <StudyNote>[];
  }
  return ref.watch(notesRepositoryProvider).list();
});

final categoriesProvider = FutureProvider.autoDispose<List<AppCategory>>((ref) {
  if (ref.watch(currentUserProvider) == null) {
    return <AppCategory>[];
  }
  return ref.watch(categoriesRepositoryProvider).list();
});

final waterEntriesProvider = FutureProvider.autoDispose
    .family<List<WaterEntry>, String>((ref, dateKey) {
      if (ref.watch(currentUserProvider) == null) {
        return <WaterEntry>[];
      }
      return ref.watch(waterRepositoryProvider).listByDate(dateKey);
    });

final calendarEventsProvider = FutureProvider.autoDispose<List<CalendarEvent>>((
  ref,
) {
  if (ref.watch(currentUserProvider) == null) {
    return <CalendarEvent>[];
  }
  return ref.watch(calendarRepositoryProvider).list();
});

final mealEntriesProvider = FutureProvider.autoDispose
    .family<List<MealEntry>, String>((ref, dateKey) {
      if (ref.watch(currentUserProvider) == null) {
        return <MealEntry>[];
      }
      return ref.watch(mealsRepositoryProvider).listByDate(dateKey);
    });

final activityEntriesProvider = FutureProvider.autoDispose
    .family<List<ActivityEntry>, String>((ref, dateKey) {
      if (ref.watch(currentUserProvider) == null) {
        return <ActivityEntry>[];
      }
      return ref.watch(activitiesRepositoryProvider).listByDate(dateKey);
    });

final userProfileProvider = FutureProvider.autoDispose<UserProfile?>((ref) {
  if (ref.watch(currentUserProvider) == null) {
    return null;
  }
  return ref.watch(profileRepositoryProvider).getProfile();
});

final dailyReviewProvider = FutureProvider.autoDispose
    .family<DailyReview?, String>((ref, dateKey) {
      if (ref.watch(currentUserProvider) == null) {
        return null;
      }
      return ref
          .watch(dailyReviewsRepositoryProvider)
          .getByDate(DateTime.parse(dateKey));
    });

final weeklyReviewProvider = FutureProvider.autoDispose<WeeklyReviewData>((
  ref,
) async {
  final today = todayDate();
  final weekStart = today.subtract(Duration(days: today.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  if (ref.watch(currentUserProvider) == null) {
    return WeeklyReviewData(
      weekStart: weekStart,
      weekEnd: weekEnd,
      habitSummary: WeeklyHabitSummary(
        weekStart: weekStart,
        weekEnd: weekEnd,
        stats: const [],
      ),
      completedTasks: 0,
      overdueTasks: 0,
      averageWaterMl: 0,
      caloriesIn: 0,
      caloriesOut: 0,
      dailyReviewCount: 0,
    );
  }

  final results = await Future.wait<Object>([
    ref.watch(habitsRepositoryProvider).getWeeklySummary(weekStart, weekEnd),
    ref.watch(todosRepositoryProvider).list(),
    _listWaterForRange(ref, weekStart, weekEnd),
    _listMealsForRange(ref, weekStart, weekEnd),
    _listActivitiesForRange(ref, weekStart, weekEnd),
    ref.watch(dailyReviewsRepositoryProvider).listByRange(weekStart, weekEnd),
  ]);

  final habitSummary = results[0] as WeeklyHabitSummary;
  final todos = results[1] as List<TodoItem>;
  final waterEntries = results[2] as List<WaterEntry>;
  final meals = results[3] as List<MealEntry>;
  final activities = results[4] as List<ActivityEntry>;
  final reviews = results[5] as List<DailyReview>;

  final completedTasks = todos.where((todo) {
    final dueDate = todo.dueDate;
    return todo.isCompleted &&
        dueDate != null &&
        !_isBeforeDate(dueDate, weekStart) &&
        !_isAfterDate(dueDate, weekEnd);
  }).length;
  final overdueTasks = todos.where((todo) {
    final dueDate = todo.dueDate;
    return !todo.isCompleted &&
        dueDate != null &&
        _isBeforeDate(dueDate, today);
  }).length;
  final waterMl = waterEntries.fold(0, (sum, entry) => sum + entry.amountMl);
  final caloriesIn = meals.fold(0, (sum, entry) => sum + entry.calories);
  final caloriesOut = activities.fold(
    0,
    (sum, entry) => sum + entry.caloriesBurned.round(),
  );

  return WeeklyReviewData(
    weekStart: weekStart,
    weekEnd: weekEnd,
    habitSummary: habitSummary,
    completedTasks: completedTasks,
    overdueTasks: overdueTasks,
    averageWaterMl: (waterMl / 7).round(),
    caloriesIn: caloriesIn,
    caloriesOut: caloriesOut,
    dailyReviewCount: reviews.length,
  );
});

final globalSearchProvider = FutureProvider.autoDispose
    .family<List<GlobalSearchResult>, String>((ref, rawQuery) async {
      final query = rawQuery.trim().toLowerCase();
      if (ref.watch(currentUserProvider) == null || query.length < 2) {
        return const [];
      }

      final results = await Future.wait<Object>([
        ref.watch(todosRepositoryProvider).list(),
        ref.watch(calendarRepositoryProvider).list(),
        ref.watch(notesRepositoryProvider).list(),
        ref.watch(habitsRepositoryProvider).getHabits(),
      ]);

      final todos = results[0] as List<TodoItem>;
      final events = results[1] as List<CalendarEvent>;
      final notes = results[2] as List<StudyNote>;
      final habits = results[3] as List<Habit>;

      final matches = <GlobalSearchResult>[
        for (final todo in todos)
          if (_containsQuery([
            todo.title,
            todo.description,
            todo.priority,
          ], query))
            GlobalSearchResult(
              id: todo.id,
              title: todo.title,
              subtitle: [
                'Tarefa',
                if (todo.dueDate != null) formatDate(todo.dueDate),
                if (todo.isCompleted) 'concluida',
              ].join(' - '),
              type: GlobalSearchResultType.todo,
              date: todo.dueDate,
            ),
        for (final event in events)
          if (_containsQuery([
            event.title,
            event.description,
            event.category,
            event.location,
          ], query))
            GlobalSearchResult(
              id: event.id,
              title: event.title,
              subtitle: [
                'Evento',
                formatDate(event.eventDate),
                if (event.startTime != null) compactTime(event.startTime!),
              ].join(' - '),
              type: GlobalSearchResultType.event,
              date: event.eventDate,
            ),
        for (final note in notes)
          if (_containsQuery([note.title, note.content, note.subject], query))
            GlobalSearchResult(
              id: note.id,
              title: note.title,
              subtitle: [
                'Nota',
                note.subject,
                if (note.needsReview) 'para rever',
              ].join(' - '),
              type: GlobalSearchResultType.note,
              date: note.nextReviewDate,
            ),
        for (final habit in habits)
          if (_containsQuery([
            habit.title,
            habit.description,
            habit.category,
          ], query))
            GlobalSearchResult(
              id: habit.id,
              title: habit.title,
              subtitle: [
                'Habito',
                habit.targetType.label,
                if (!habit.isActive) 'inativo',
              ].join(' - '),
              type: GlobalSearchResultType.habit,
              date: habit.startDate,
            ),
      ];

      matches.sort((left, right) {
        final typeCompare = left.type.index.compareTo(right.type.index);
        if (typeCompare != 0) {
          return typeCompare;
        }
        return left.title.toLowerCase().compareTo(right.title.toLowerCase());
      });

      return matches;
    });

final dayPlanProvider = FutureProvider.autoDispose.family<DayPlanData, String>((
  ref,
  dateKey,
) async {
  final date = DateTime.parse(dateKey);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return DayPlanData(
      displayName: 'Utilizador',
      date: date,
      profile: null,
      scheduleBlocks: const [],
      events: const [],
      todos: const [],
      habits: const [],
      waterEntries: const [],
      mealEntries: const [],
      activityEntries: const [],
      timelineItems: const [],
    );
  }

  await ref.watch(recurringTasksRepositoryProvider).generateTasksForDate(date);

  final results = await Future.wait<Object?>([
    ref.watch(profileRepositoryProvider).getProfile(),
    ref.watch(scheduleRepositoryProvider).list(),
    ref.watch(todosRepositoryProvider).list(),
    ref.watch(calendarRepositoryProvider).list(),
    ref.watch(waterRepositoryProvider).listByDate(dateKey),
    ref.watch(mealsRepositoryProvider).listByDate(dateKey),
    ref.watch(activitiesRepositoryProvider).listByDate(dateKey),
    ref.watch(habitsRepositoryProvider).getTodayEntries(date),
  ]);

  final profile = results[0] as UserProfile?;
  final scheduleBlocks = results[1] as List<ScheduleBlock>;
  final todos = results[2] as List<TodoItem>;
  final events = results[3] as List<CalendarEvent>;
  final waterEntries = results[4] as List<WaterEntry>;
  final mealEntries = results[5] as List<MealEntry>;
  final activityEntries = results[6] as List<ActivityEntry>;
  final habitEntries = results[7] as List<TodayHabitEntry>;

  final dayTodos = todos
      .where(
        (todo) =>
            todo.dueDate != null && formatDateKey(todo.dueDate!) == dateKey,
      )
      .toList();
  final dayEvents = events
      .where((event) => formatDateKey(event.eventDate) == dateKey)
      .toList();
  final timelineItems = buildTodayTimelineItems(
    date: date,
    scheduleBlocks: scheduleBlocks,
    events: dayEvents,
    todos: dayTodos,
    habits: habitEntries,
  );

  final displayName =
      profile?.displayName ?? user.email?.split('@').first ?? 'Utilizador';

  return DayPlanData(
    displayName: displayName,
    date: date,
    profile: profile,
    scheduleBlocks: scheduleBlocks,
    events: dayEvents,
    todos: dayTodos,
    habits: habitEntries,
    waterEntries: waterEntries,
    mealEntries: mealEntries,
    activityEntries: activityEntries,
    timelineItems: timelineItems,
  );
});

final timelineClockProvider = StreamProvider.autoDispose<DateTime>((
  ref,
) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>((
  ref,
) async {
  if (ref.watch(currentUserProvider) == null) {
    return const DashboardSummary(
      completedTasks: 0,
      pendingTasks: 0,
      waterMl: 0,
      caloriesIn: 0,
      caloriesOut: 0,
      upcomingEvents: [],
    );
  }

  final dateKey = formatDateKey(todayDate());

  await ref
      .watch(recurringTasksRepositoryProvider)
      .generateTasksForDate(todayDate());
  final todos = await ref.watch(todosRepositoryProvider).list();
  final water = await ref.watch(waterRepositoryProvider).listByDate(dateKey);
  final meals = await ref.watch(mealsRepositoryProvider).listByDate(dateKey);
  final activities = await ref
      .watch(activitiesRepositoryProvider)
      .listByDate(dateKey);
  final events = await ref.watch(calendarRepositoryProvider).upcoming();

  return DashboardSummary(
    completedTasks: todos.where((todo) => todo.isCompleted).length,
    pendingTasks: todos.where((todo) => !todo.isCompleted).length,
    waterMl: water.fold(0, (total, entry) => total + entry.amountMl),
    caloriesIn: meals.fold(0, (total, entry) => total + entry.calories),
    caloriesOut: activities.fold(
      0,
      (total, entry) => total + entry.caloriesBurned.round(),
    ),
    upcomingEvents: events,
  );
});

final homeDashboardProvider = FutureProvider.autoDispose<HomeDashboardData>((
  ref,
) async {
  final today = todayDate();
  final dateKey = formatDateKey(today);
  final user = ref.watch(currentUserProvider);

  if (user == null) {
    return HomeDashboardData(
      displayName: 'Utilizador',
      date: today,
      profile: null,
      todayScheduleBlocks: const [],
      currentBlock: null,
      nextScheduleBlocks: const [],
      todayEvents: const [],
      todayTodos: const [],
      waterEntries: const [],
      mealEntries: const [],
      activityEntries: const [],
      completedTasks: 0,
      totalTasks: 0,
      waterMl: 0,
      waterGoalMl: 2000,
      caloriesIn: 0,
      caloriesOut: 0,
    );
  }

  await ref.watch(recurringTasksRepositoryProvider).generateTasksForDate(today);

  final results = await Future.wait<Object?>([
    ref.watch(profileRepositoryProvider).getProfile(),
    ref.watch(scheduleRepositoryProvider).list(),
    ref.watch(todosRepositoryProvider).list(),
    ref.watch(calendarRepositoryProvider).list(),
    ref.watch(waterRepositoryProvider).listByDate(dateKey),
    ref.watch(mealsRepositoryProvider).listByDate(dateKey),
    ref.watch(activitiesRepositoryProvider).listByDate(dateKey),
  ]);

  final profile = results[0] as UserProfile?;
  final scheduleBlocks = results[1] as List<ScheduleBlock>;
  final todos = results[2] as List<TodoItem>;
  final events = results[3] as List<CalendarEvent>;
  final waterEntries = results[4] as List<WaterEntry>;
  final mealEntries = results[5] as List<MealEntry>;
  final activityEntries = results[6] as List<ActivityEntry>;

  final todayScheduleBlocks =
      scheduleBlocks.where((block) => block.weekday == today.weekday).toList()
        ..sort(
          (left, right) => _timeToMinutes(
            left.startTime,
          ).compareTo(_timeToMinutes(right.startTime)),
        );

  final nowMinutes = today.hour * 60 + today.minute;
  ScheduleBlock? currentBlock;
  for (final block in todayScheduleBlocks) {
    final startMinutes = _timeToMinutes(block.startTime);
    final endMinutes = _timeToMinutes(block.endTime);
    if (startMinutes <= nowMinutes && nowMinutes < endMinutes) {
      currentBlock = block;
      break;
    }
  }

  final nextScheduleBlocks = todayScheduleBlocks.where((block) {
    final startMinutes = _timeToMinutes(block.startTime);
    return currentBlock == null
        ? startMinutes >= nowMinutes
        : startMinutes > nowMinutes;
  }).toList();

  final todayEvents = events
      .where((event) => formatDateKey(event.eventDate) == dateKey)
      .toList();

  final todayTodos = todos
      .where(
        (todo) =>
            todo.dueDate != null && formatDateKey(todo.dueDate!) == dateKey,
      )
      .toList();

  final completedTasks = todayTodos.where((todo) => todo.isCompleted).length;
  final totalTasks = todayTodos.length;
  final waterMl = waterEntries.fold(0, (sum, entry) => sum + entry.amountMl);
  final caloriesIn = mealEntries.fold(0, (sum, entry) => sum + entry.calories);
  final caloriesOut = activityEntries.fold(
    0,
    (sum, entry) => sum + entry.caloriesBurned.round(),
  );

  final displayName =
      profile?.displayName ?? (user.email?.split('@').first ?? 'Utilizador');

  return HomeDashboardData(
    displayName: displayName,
    date: today,
    profile: profile,
    todayScheduleBlocks: todayScheduleBlocks,
    currentBlock: currentBlock,
    nextScheduleBlocks: nextScheduleBlocks,
    todayEvents: todayEvents,
    todayTodos: todayTodos,
    waterEntries: waterEntries,
    mealEntries: mealEntries,
    activityEntries: activityEntries,
    completedTasks: completedTasks,
    totalTasks: totalTasks,
    waterMl: waterMl,
    waterGoalMl: profile?.dailyWaterGoalMl ?? 2000,
    caloriesIn: caloriesIn,
    caloriesOut: caloriesOut,
  );
});

final homeTimelineProvider = FutureProvider.autoDispose<TodayTimelineData>((
  ref,
) async {
  final today = todayDate();
  final dateKey = formatDateKey(today);
  final plan = await ref.watch(dayPlanProvider(dateKey).future);

  return TodayTimelineData(
    displayName: plan.displayName,
    date: today,
    items: plan.timelineItems,
    completedTasks: plan.completedTasks,
    totalTasks: plan.totalTasks,
    waterMl: plan.waterMl,
    waterGoalMl: plan.waterGoalMl,
    caloriesIn: plan.caloriesIn,
    caloriesOut: plan.caloriesOut,
  );
});

int _timeToMinutes(String value) {
  final parts = value.split(':');
  final hours = int.tryParse(parts.first) ?? 0;
  final minutes = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;
  return hours * 60 + minutes;
}

Future<List<WaterEntry>> _listWaterForRange(
  Ref ref,
  DateTime start,
  DateTime end,
) async {
  final entries = <WaterEntry>[];
  var date = start;
  while (!date.isAfter(end)) {
    entries.addAll(
      await ref.watch(waterRepositoryProvider).listByDate(formatDateKey(date)),
    );
    date = date.add(const Duration(days: 1));
  }
  return entries;
}

Future<List<MealEntry>> _listMealsForRange(
  Ref ref,
  DateTime start,
  DateTime end,
) async {
  final entries = <MealEntry>[];
  var date = start;
  while (!date.isAfter(end)) {
    entries.addAll(
      await ref.watch(mealsRepositoryProvider).listByDate(formatDateKey(date)),
    );
    date = date.add(const Duration(days: 1));
  }
  return entries;
}

Future<List<ActivityEntry>> _listActivitiesForRange(
  Ref ref,
  DateTime start,
  DateTime end,
) async {
  final entries = <ActivityEntry>[];
  var date = start;
  while (!date.isAfter(end)) {
    entries.addAll(
      await ref
          .watch(activitiesRepositoryProvider)
          .listByDate(formatDateKey(date)),
    );
    date = date.add(const Duration(days: 1));
  }
  return entries;
}

bool _isBeforeDate(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isBefore(DateTime(right.year, right.month, right.day));
}

bool _isAfterDate(DateTime left, DateTime right) {
  return DateTime(
    left.year,
    left.month,
    left.day,
  ).isAfter(DateTime(right.year, right.month, right.day));
}

bool _containsQuery(List<String?> values, String query) {
  return values.any((value) => (value ?? '').toLowerCase().contains(query));
}

void invalidateDashboardData(WidgetRef ref) {
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dayPlanProvider);
  ref.invalidate(dailyReviewProvider);
  ref.invalidate(homeDashboardProvider);
  ref.invalidate(homeTimelineProvider);
  ref.invalidate(todosProvider);
  ref.invalidate(recurringTasksProvider);
  ref.invalidate(habitsProvider);
  ref.invalidate(todayHabitEntriesProvider);
  ref.invalidate(weeklyHabitSummaryProvider);
  ref.invalidate(weeklyReviewProvider);
  ref.invalidate(calendarEventsProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(waterEntriesProvider);
  ref.invalidate(mealEntriesProvider);
  ref.invalidate(activityEntriesProvider);
  ref.invalidate(globalSearchProvider);
  ref.invalidate(categoriesProvider);
}

void invalidateHabitData(WidgetRef ref) {
  ref.invalidate(habitsProvider);
  ref.invalidate(todayHabitEntriesProvider);
  ref.invalidate(weeklyHabitSummaryProvider);
  ref.invalidate(weeklyReviewProvider);
  ref.invalidate(dayPlanProvider);
  ref.invalidate(dailyReviewProvider);
  ref.invalidate(homeTimelineProvider);
  ref.invalidate(globalSearchProvider);
  ref.invalidate(categoriesProvider);
}

void invalidateUserScopedData(WidgetRef ref) {
  ref.invalidate(homeDashboardProvider);
  ref.invalidate(homeTimelineProvider);
  ref.invalidate(dayPlanProvider);
  ref.invalidate(scheduleBlocksProvider);
  ref.invalidate(todosProvider);
  ref.invalidate(recurringTasksProvider);
  ref.invalidate(habitsProvider);
  ref.invalidate(todayHabitEntriesProvider);
  ref.invalidate(weeklyHabitSummaryProvider);
  ref.invalidate(weeklyReviewProvider);
  ref.invalidate(notesProvider);
  ref.invalidate(waterEntriesProvider);
  ref.invalidate(calendarEventsProvider);
  ref.invalidate(mealEntriesProvider);
  ref.invalidate(activityEntriesProvider);
  ref.invalidate(userProfileProvider);
  ref.invalidate(dashboardSummaryProvider);
  ref.invalidate(dailyReviewProvider);
  ref.invalidate(globalSearchProvider);
  ref.invalidate(categoriesProvider);
}
