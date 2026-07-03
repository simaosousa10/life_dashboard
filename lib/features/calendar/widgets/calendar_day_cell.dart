import 'package:flutter/material.dart';

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.date,
    required this.isToday,
    required this.isSelected,
    required this.hasItems,
    required this.onTap,
    super.key,
  });

  final DateTime? date;
  final bool isToday;
  final bool isSelected;
  final bool hasItems;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (date == null) {
      return const SizedBox.shrink();
    }

    final colorScheme = Theme.of(context).colorScheme;
    final background = isSelected
        ? colorScheme.primary
        : isToday
        ? colorScheme.primaryContainer
        : Colors.transparent;
    final foreground = isSelected
        ? colorScheme.onPrimary
        : isToday
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.all(3),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${date!.day}',
                style: TextStyle(
                  color: foreground,
                  fontWeight: isToday || isSelected
                      ? FontWeight.w800
                      : FontWeight.w600,
                ),
              ),
              const SizedBox(height: 5),
              SizedBox(
                height: 5,
                child: hasItems
                    ? DecoratedBox(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.onPrimary
                              : colorScheme.tertiary,
                          shape: BoxShape.circle,
                        ),
                        child: const SizedBox.square(dimension: 5),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
