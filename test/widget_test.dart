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

    expect(find.text('활동조회'), findsWidgets);
    expect(find.text('기간별 활동 내역을 확인하세요'), findsOneWidget);
  });
}
