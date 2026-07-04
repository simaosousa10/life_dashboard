import 'package:flutter_test/flutter_test.dart';
import 'package:life_dashboard/data/models/user_profile.dart';

void main() {
  test(
    'UserProfile.needsOnboarding handles incomplete and unfinished profiles',
    () {
      expect(_profile(onboardingCompleted: false).needsOnboarding, isTrue);
      expect(_profile(displayName: '   ').needsOnboarding, isTrue);
      expect(_profile(weightKg: 0).needsOnboarding, isTrue);
      expect(_profile().needsOnboarding, isFalse);
    },
  );
}

UserProfile _profile({
  String displayName = 'User',
  double weightKg = 70,
  int waterGoal = 2000,
  int calorieGoal = 2200,
  bool onboardingCompleted = true,
}) {
  return UserProfile(
    id: 'profile-1',
    userId: 'user-1',
    displayName: displayName,
    weightKg: weightKg,
    dailyWaterGoalMl: waterGoal,
    dailyCalorieGoal: calorieGoal,
    onboardingCompleted: onboardingCompleted,
    createdAt: DateTime(2026, 7, 1),
  );
}
