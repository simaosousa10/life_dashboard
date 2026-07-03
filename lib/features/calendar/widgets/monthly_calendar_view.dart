import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';
import 'calendar_day_cell.dart';

class MonthlyCalendarView extends StatelessWidget {
  const MonthlyCalendarView({
    required this.visibleMonth,
    required this.selectedDate,
    required this.hasItemsForDate,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onSelectDate,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final bool Function(DateTime date) hasItemsForDate;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;
  final ValueChanged<DateTime> onSelectDate;

  @override
  Widget build(BuildContext context) {
    final dates = _visibleCalendarCells(visibleMonth);
    final today = todayDate();

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Mes anterior',
                  onPressed: onPreviousMonth,
                  icon: const Icon(Icons.chevron_left),
                ),
                Expanded(
                  child: Text(
                    _monthLabel(visibleMonth),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Mes seguinte',
                  onPressed: onNextMonth,
                  icon: const Icon(Icons.chevron_right),
                ),
              ],
            ),
            const SizedBox(height: 6),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.45,
              children: const [
                _WeekdayLabel('Seg'),
                _WeekdayLabel('Ter'),
                _WeekdayLabel('Qua'),
                _WeekdayLabel('Qui'),
                _WeekdayLabel('Sex'),
                _WeekdayLabel('Sab'),
                _WeekdayLabel('Dom'),
              ],
            ),
            GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.05,
              children: dates.map((date) {
                return CalendarDayCell(
                  date: date,
                  isToday: date != null && _isSameDay(date, today),
                  isSelected: date != null && _isSameDay(date, selectedDate),
                  hasItems: date != null && hasItemsForDate(date),
                  onTap: date == null ? null : () => onSelectDate(date),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeekdayLabel extends StatelessWidget {
  const _WeekdayLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

List<DateTime?> _visibleCalendarCells(DateTime month) {
  final first = DateTime(month.year, month.month);
  final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
  final leadingEmptyCells = first.weekday - 1;
  final totalCells = ((leadingEmptyCells + daysInMonth) / 7).ceil() * 7;

  return List<DateTime?>.generate(totalCells, (index) {
    final dayNumber = index - leadingEmptyCells + 1;
    if (dayNumber < 1 || dayNumber > daysInMonth) {
      return null;
    }
    return DateTime(month.year, month.month, dayNumber);
  });
}

bool _isSameDay(DateTime left, DateTime right) =>
    left.year == right.year &&
    left.month == right.month &&
    left.day == right.day;

String _monthLabel(DateTime value) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Marco',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return '${months[value.month - 1]} ${value.year}';
}
