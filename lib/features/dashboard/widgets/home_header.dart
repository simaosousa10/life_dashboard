import 'package:flutter/material.dart';

import '../../../core/constants/app_constants.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.displayName,
    required this.date,
    required this.onProfileTap,
    this.onSearchTap,
    super.key,
  });

  final String displayName;
  final DateTime date;
  final VoidCallback onProfileTap;
  final VoidCallback? onSearchTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Olá, $displayName',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatDate(date),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.70),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'O teu plano de hoje',
                style: TextStyle(
                  color: Color(0xFFFFD166),
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        IconButton.filledTonal(
          tooltip: 'Pesquisar',
          onPressed: onSearchTap,
          icon: const Icon(Icons.search),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        IconButton.filledTonal(
          tooltip: 'Perfil',
          onPressed: onProfileTap,
          icon: const Icon(Icons.person_outline),
          style: IconButton.styleFrom(
            backgroundColor: Colors.white.withValues(alpha: 0.10),
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }
}
