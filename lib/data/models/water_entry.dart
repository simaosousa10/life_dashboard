import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class WaterEntry {
  const WaterEntry({
    required this.id,
    required this.userId,
    required this.amountMl,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final int amountMl;
  final DateTime date;
  final DateTime createdAt;

  factory WaterEntry.fromMap(Map<String, dynamic> map) {
    return WaterEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      amountMl: readInt(map, 'amount_ml'),
      date: parseDate(map['date']),
      createdAt: parseDate(map['created_at']),
    );
  }
}

class WaterEntryInput {
  const WaterEntryInput({required this.amountMl, required this.date});

  final int amountMl;
  final DateTime date;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'amount_ml': amountMl,
    'date': formatDateKey(date),
  };
}
