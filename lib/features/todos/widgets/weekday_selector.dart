import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class WeekdaySelector extends StatelessWidget {
  const WeekdaySelector({
    required this.selectedWeekdays,
    required this.onChanged,
    super.key,
  });

  final Set<int> selectedWeekdays;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: AppConstants.weekdays.entries.map((entry) {
        final selected = selectedWeekdays.contains(entry.key);
        return FilterChip(
          label: Text(_shortLabel(entry.value)),
          selected: selected,
          onSelected: (value) {
            final next = {...selectedWeekdays};
            if (value) {
              next.add(entry.key);
            } else {
              next.remove(entry.key);
            }
            onChanged(next);
          },
        );
      }).toList(),
    );
  }

  String _shortLabel(String value) {
    return value.length <= 3 ? value : value.substring(0, 3);
  }
}
