import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';
import 'database/app_database.dart';
import 'providers/database_provider.dart';
import 'screens/main_shell.dart';
import 'services/backup_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ko_KR');

  final database = AppDatabase();
  final backupService = BackupService(database);
  await backupService.tryRestoreFromPersistentBackupIfNeeded();
  // 재설치 직후 빈 DB로 공용 백업을 덮어쓰지 않도록, 기록이 있을 때만 갱신
  if (await database.activityRecordCount() > 0) {
    await backupService.writeBackup();
  }

  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const LegioActivityApp(),
    ),
  );
}

class LegioActivityApp extends StatelessWidget {
  const LegioActivityApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.light,
      locale: const Locale('ko', 'KR'),
      supportedLocales: const [Locale('ko', 'KR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AppRoot(),
    );
  }
}
