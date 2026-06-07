import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_measure_type.dart';
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

  Future<void> addType(
    String name, {
    ActivityMeasureType measureType = ActivityMeasureType.count,
  }) async {
    await ref.read(activityTypeServiceProvider).add(
          name,
          measureType: measureType,
        );
    await scheduleDataBackup(ref);
    await refresh();
  }

  Future<void> updateType(ActivityType type) async {
    await ref.read(activityTypeServiceProvider).update(type);
    await scheduleDataBackup(ref);
    await refresh();
  }

  Future<void> reorderTypes(List<String> orderedIds) async {
    final current = state.value;
    if (current == null) return;

    final byId = {for (final type in current) type.id: type};
    final reordered = <ActivityType>[];
    for (var index = 0; index < orderedIds.length; index++) {
      final type = byId[orderedIds[index]];
      if (type != null) {
        reordered.add(type.copyWith(sortOrder: index));
      }
    }

    state = AsyncData(reordered);
    await ref.read(activityTypeServiceProvider).reorder(orderedIds);
    await scheduleDataBackup(ref);
  }

  Future<void> deleteType(String id) async {
    await ref.read(activityTypeServiceProvider).delete(id);
    await scheduleDataBackup(ref);
    await refresh();
  }
}
