import 'model_helpers.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.userId,
    required this.displayName,
    required this.weightKg,
    required this.dailyWaterGoalMl,
    required this.dailyCalorieGoal,
    required this.onboardingCompleted,
    required this.createdAt,
  });

  final String id;
  final String userId;
  final String displayName;
  final double weightKg;
  final int dailyWaterGoalMl;
  final int dailyCalorieGoal;
  final bool onboardingCompleted;
  final DateTime createdAt;

  bool get isComplete =>
      displayName.trim().isNotEmpty &&
      weightKg > 0 &&
      dailyWaterGoalMl > 0 &&
      dailyCalorieGoal > 0;

  bool get needsOnboarding => !onboardingCompleted || !isComplete;

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      displayName: map['display_name'] as String,
      weightKg: readDouble(map, 'weight_kg'),
      dailyWaterGoalMl: readInt(map, 'daily_water_goal_ml'),
      dailyCalorieGoal: readInt(map, 'daily_calorie_goal'),
      onboardingCompleted: map['onboarding_completed'] as bool? ?? true,
      createdAt: parseDate(map['created_at']),
    );
  }
}

class UserProfileInput {
  const UserProfileInput({
    required this.displayName,
    required this.weightKg,
    required this.dailyWaterGoalMl,
    required this.dailyCalorieGoal,
    this.onboardingCompleted = true,
  });

  final String displayName;
  final double weightKg;
  final int dailyWaterGoalMl;
  final int dailyCalorieGoal;
  final bool onboardingCompleted;

  Map<String, dynamic> toMap(String userId) => {
    'user_id': userId,
    'display_name': displayName.trim(),
    'weight_kg': weightKg,
    'daily_water_goal_ml': dailyWaterGoalMl,
    'daily_calorie_goal': dailyCalorieGoal,
    'onboarding_completed': onboardingCompleted,
  };
}
