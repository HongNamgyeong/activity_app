import '../database/app_database.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_type.dart';

class ActivityTypeService {
  ActivityTypeService(this._database);

  final AppDatabase _database;

  Future<List<ActivityType>> fetchAll() => _database.getAllActivityTypes();

  Future<ActivityType> add(
    String name, {
    ActivityMeasureType measureType = ActivityMeasureType.count,
  }) =>
      _database.addActivityType(name, measureType: measureType);

  Future<void> update(ActivityType type) => _database.updateActivityType(type);

  Future<void> delete(String id) => _database.deleteActivityType(id);
}
