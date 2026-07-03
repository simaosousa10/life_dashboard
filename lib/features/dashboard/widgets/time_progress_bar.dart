import 'package:flutter/material.dart';

class TimeProgressBar extends StatelessWidget {
  const TimeProgressBar({required this.value, super.key});

  final double value;

  @override
  Widget build(BuildContext context) {
    final progress = value.clamp(0.0, 1.0);

    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: Container(
        height: 7,
        color: Colors.white.withValues(alpha: 0.22),
        child: Align(
          alignment: Alignment.centerLeft,
          child: FractionallySizedBox(
            widthFactor: progress,
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFFD166), Color(0xFFFF7A1A)],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
