import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'calendar/calendar_screen.dart';
import 'calories/health_screen.dart';
import 'home/home_screen.dart';
import 'notes/notes_screen.dart';
import 'profile/profile_screen.dart';
import 'todos/todos_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  void _selectTab(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final titles = [
      'Home',
      'Perfil',
      'Saude',
      'Tarefas',
      'Notas',
      'Calendario',
    ];

    final pages = [
      HomeScreen(onSelectTab: _selectTab),
      const ProfileScreen(),
      const HealthScreen(),
      const TodosScreen(),
      const NotesScreen(),
      const CalendarScreen(),
    ];

    return Scaffold(
      appBar: _selectedIndex == 0
          ? null
          : AppBar(
              title: Text(
                '${AppConstants.appName} - ${titles[_selectedIndex]}',
              ),
            ),
      body: IndexedStack(index: _selectedIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectTab,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Perfil',
          ),
          NavigationDestination(
            icon: Icon(Icons.favorite_border),
            selectedIcon: Icon(Icons.favorite),
            label: 'Saude',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_outlined),
            selectedIcon: Icon(Icons.checklist),
            label: 'Tarefas',
          ),
          NavigationDestination(
            icon: Icon(Icons.note_alt_outlined),
            selectedIcon: Icon(Icons.note_alt),
            label: 'Notas',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event),
            label: 'Calendario',
          ),
        ],
      ),
    );
  }
}
