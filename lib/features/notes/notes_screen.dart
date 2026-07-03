import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/utils/app_error.dart';
import '../../core/widgets/app_async_value.dart';
import '../../core/widgets/app_snackbars.dart';
import '../../core/widgets/empty_state.dart';
import '../../data/models/study_note.dart';
import '../../providers/app_providers.dart';

class NotesScreen extends ConsumerStatefulWidget {
  const NotesScreen({super.key});

  @override
  ConsumerState<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends ConsumerState<NotesScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notes = ref.watch(notesProvider);

    return Scaffold(
      body: AppAsyncValue(
        value: notes,
        onRetry: () => ref.invalidate(notesProvider),
        builder: (items) {
          final query = _query.trim().toLowerCase();
          final filtered = query.isEmpty
              ? items
              : items.where((note) {
                  return note.title.toLowerCase().contains(query) ||
                      note.content.toLowerCase().contains(query) ||
                      note.subject.toLowerCase().contains(query);
                }).toList();

          return RefreshIndicator(
            onRefresh: () async => invalidateUserScopedData(ref),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    labelText: 'Pesquisar notas',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.clear),
                          ),
                  ),
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 16),
                if (filtered.isEmpty)
                  const EmptyState(
                    icon: Icons.note_alt_outlined,
                    title: 'Sem notas',
                    message: 'Cria notas por disciplina e pesquisa-as depois.',
                  )
                else
                  ...filtered.map(
                    (note) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note.title,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.titleMedium,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          note.subject,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _openNoteDialog(context, ref, note);
                                      } else {
                                        try {
                                          await ref
                                              .read(notesRepositoryProvider)
                                              .delete(note.id);
                                          invalidateUserScopedData(ref);
                                        } catch (error) {
                                          if (context.mounted) {
                                            showErrorSnackBar(context, error);
                                          }
                                        }
                                      }
                                    },
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text('Editar'),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text('Eliminar'),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                _preview(note.content),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNoteDialog(context, ref),
        icon: const Icon(Icons.note_add_outlined),
        label: const Text('Nota'),
      ),
    );
  }

  void _openNoteDialog(BuildContext context, WidgetRef ref, [StudyNote? note]) {
    showDialog<void>(
      context: context,
      builder: (_) => _NoteDialog(
        note: note,
        onSubmit: (input) async {
          final repository = ref.read(notesRepositoryProvider);
          if (note == null) {
            await repository.create(input);
          } else {
            await repository.update(note.id, input);
          }
          invalidateUserScopedData(ref);
        },
      ),
    );
  }
}

class _NoteDialog extends StatefulWidget {
  const _NoteDialog({required this.onSubmit, this.note});

  final StudyNote? note;
  final Future<void> Function(StudyNoteInput input) onSubmit;

  @override
  State<_NoteDialog> createState() => _NoteDialogState();
}

class _NoteDialogState extends State<_NoteDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late final TextEditingController _subjectController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final note = widget.note;
    _titleController = TextEditingController(text: note?.title ?? '');
    _contentController = TextEditingController(text: note?.content ?? '');
    _subjectController = TextEditingController(text: note?.subject ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _subjectController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(
        StudyNoteInput(
          title: _titleController.text,
          content: _contentController.text,
          subject: _subjectController.text,
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
      title: Text(widget.note == null ? 'Nova nota' : 'Editar nota'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
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
                controller: _subjectController,
                decoration: const InputDecoration(labelText: 'Disciplina'),
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Obrigatorio.' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                decoration: const InputDecoration(labelText: 'Conteudo'),
                minLines: 4,
                maxLines: 8,
                validator: (value) =>
                    (value ?? '').trim().isEmpty ? 'Obrigatorio.' : null,
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

String _preview(String content) {
  final trimmed = content.trim();
  if (trimmed.length <= 120) {
    return trimmed;
  }
  return '${trimmed.substring(0, 120)}...';
}
