import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_dashboard/main.dart';

void main() {
  testWidgets('shows Supabase setup when credentials are missing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      const ProviderScope(child: LifeDashboardApp(isSupabaseConfigured: false)),
    );

    expect(find.text('Life Dashboard'), findsOneWidget);
    expect(find.textContaining('SUPABASE_URL'), findsWidgets);
  });
}
