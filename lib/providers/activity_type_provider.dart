import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_type.dart';
import '../services/activity_type_service.dart';
import 'backup_provider.dart';
import 'database_provider.dart';

final activityTypeServiceProvider = Provider<ActivityTypeService>((ref) {
  return ActivityTypeService(ref.watch(appDatabaseProvider));
});

final activityTypesProvider =
    AsyncNotifierProvider<ActivityTypesNotifier, List<ActivityType>>(
  ActivityTypesNotifier.new,
);

class ActivityTypesNotifier extends AsyncNotifier<List<ActivityType>> {
  @override
  Future<List<ActivityType>> build() {
    return ref.read(activityTypeServiceProvider).fetchAll();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(activityTypeServiceProvider).fetchAll(),
    );
  }

  Future<void> addType(String name) async {
    await ref.read(activityTypeServiceProvider).add(name);
    await scheduleDataBackup(ref);
    await refresh();
  }

  Future<void> updateType(ActivityType type) async {
    await ref.read(activityTypeServiceProvider).update(type);
    await scheduleDataBackup(ref);
    await refresh();
  }

  Future<void> deleteType(String id) async {
    await ref.read(activityTypeServiceProvider).delete(id);
    await scheduleDataBackup(ref);
    await refresh();
  }
}
