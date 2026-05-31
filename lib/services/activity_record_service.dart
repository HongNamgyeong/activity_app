import '../database/app_database.dart';
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
  }) {
    return _database.insertActivityRecord(
      date: date,
      activityTypeId: activityTypeId,
      count: count,
      content: content,
    );
  }

  Future<ActivityPeriodSummary> getSummary(DateTime start, DateTime end) {
    return _database.getPeriodSummary(start, end);
  }
}
