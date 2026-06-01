import '../database/app_database.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_record.dart';
import '../models/activity_summary.dart';

class ActivityRecordService {
  ActivityRecordService(this._database);

  final AppDatabase _database;

  Future<ActivityRecord> save({
    required DateTime date,
    required String activityTypeId,
    required int count,
    required String content,
    ActivityTimeUnit? timeUnit,
  }) {
    return _database.insertActivityRecord(
      date: date,
      activityTypeId: activityTypeId,
      count: count,
      content: content,
      timeUnit: timeUnit,
    );
  }

  Future<ActivityPeriodSummary> getSummary(DateTime start, DateTime end) {
    return _database.getPeriodSummary(start, end);
  }

  Future<List<ActivityRecord>> getByType({
    required String activityTypeId,
    required DateTime start,
    required DateTime end,
  }) {
    return _database.getRecordsBetween(
      start,
      end,
      activityTypeId: activityTypeId,
    );
  }

  Future<void> update({
    required String id,
    required DateTime date,
    required int count,
    required String content,
    ActivityTimeUnit? timeUnit,
    ActivityMeasureType? measureType,
  }) {
    return _database.updateActivityRecord(
      id: id,
      date: date,
      count: count,
      content: content,
      timeUnit: timeUnit,
      measureType: measureType,
    );
  }

  Future<void> delete(String id) {
    return _database.deleteActivityRecord(id);
  }
}
