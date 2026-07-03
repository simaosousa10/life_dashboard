import 'model_helpers.dart';

class StudyNote {
  const StudyNote({
    required this.id,
    required this.userId,
    required this.title,
    required this.content,
    required this.subject,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String content;
  final String subject;
  final DateTime createdAt;

  factory StudyNote.fromMap(Map<String, dynamic> map) {
    return StudyNote(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      subject: map['subject'] as String,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class StudyNoteInput {
  const StudyNoteInput({
    required this.title,
    required this.content,
    required this.subject,
  });

  final String title;
  final String content;
  final String subject;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'title': title.trim(),
    'content': content.trim(),
    'subject': subject.trim(),
  };

  Map<String, dynamic> toUpdateMap() => {
    'title': title.trim(),
    'content': content.trim(),
    'subject': subject.trim(),
  };
}
