enum GlobalSearchResultType { todo, event, note, habit }

class GlobalSearchResult {
  const GlobalSearchResult({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.type,
    this.date,
  });

  final String id;
  final String title;
  final String subtitle;
  final GlobalSearchResultType type;
  final DateTime? date;

  String get typeLabel {
    return switch (type) {
      GlobalSearchResultType.todo => 'Tarefa',
      GlobalSearchResultType.event => 'Evento',
      GlobalSearchResultType.note => 'Nota',
      GlobalSearchResultType.habit => 'Habito',
    };
  }
}
