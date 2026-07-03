import '../../core/constants/app_constants.dart';
import 'model_helpers.dart';

class MealEntry {
  const MealEntry({
    required this.id,
    required this.userId,
    required this.mealName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.date,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String mealName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime date;
  final DateTime createdAt;

  factory MealEntry.fromMap(Map<String, dynamic> map) {
    return MealEntry(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      mealName: map['meal_name'] as String,
      calories: readInt(map, 'calories'),
      proteinG: readDouble(map, 'protein_g'),
      carbsG: readDouble(map, 'carbs_g'),
      fatG: readDouble(map, 'fat_g'),
      date: parseDate(map['date']),
      createdAt: parseDate(map['created_at']),
    );
  }
}

class MealEntryInput {
  const MealEntryInput({
    required this.mealName,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.date,
  });

  final String mealName;
  final int calories;
  final double proteinG;
  final double carbsG;
  final double fatG;
  final DateTime date;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'meal_name': mealName.trim(),
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'date': formatDateKey(date),
  };

  Map<String, dynamic> toUpdateMap() => {
    'meal_name': mealName.trim(),
    'calories': calories,
    'protein_g': proteinG,
    'carbs_g': carbsG,
    'fat_g': fatG,
    'date': formatDateKey(date),
  };
}
