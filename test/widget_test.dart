import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:activity_app/database/app_database.dart';
import 'package:activity_app/main.dart';
import 'package:activity_app/providers/database_provider.dart';

void main() {
  testWidgets('App renders main navigation', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final database = AppDatabase(NativeDatabase.memory());
            ref.onDispose(database.close);
            return database;
          }),
        ],
        child: const LegioActivityApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('활동기록'), findsWidgets);
    expect(find.text('오늘의 활동을 기록합니다'), findsOneWidget);
  });
}
