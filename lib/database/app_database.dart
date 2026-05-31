import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/constants/app_constants.dart';
import '../models/activity_record.dart' as models;
import '../models/activity_summary.dart';
import '../models/activity_type.dart' as models;

part 'app_database.g.dart';

@DataClassName('ActivityTypeRow')
class ActivityTypes extends Table {
  TextColumn get id => text()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('ActivityRecordRow')
class ActivityRecords extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get activityTypeId =>
      text().references(ActivityTypes, #id, onDelete: KeyAction.restrict)();
  IntColumn get count => integer().withDefault(const Constant(1))();
  TextColumn get content => text().withDefault(const Constant(''))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(tables: [ActivityTypes, ActivityRecords])
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  static const _uuid = Uuid();

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator migrator) async {
          await migrator.createAll();
          await _seedDefaultActivityTypes();
        },
      );

  static QueryExecutor _openConnection() {
    return driftDatabase(name: 'legio_activity_report');
  }

  Future<void> _seedDefaultActivityTypes() async {
    final existing = await select(activityTypes).get();
    if (existing.isNotEmpty) {
      return;
    }

    await batch((batch) {
      batch.insertAll(
        activityTypes,
        AppConstants.defaultActivityTypes.asMap().entries.map(
          (entry) => ActivityTypesCompanion.insert(
            id: _uuid.v4(),
            name: entry.value,
            sortOrder: Value(entry.key),
          ),
        ),
      );
    });
  }

  Future<List<models.ActivityType>> getAllActivityTypes() async {
    final rows = await (select(activityTypes)
          ..orderBy([(table) => OrderingTerm.asc(table.sortOrder)]))
        .get();

    return rows
        .map(
          (row) => models.ActivityType(
            id: row.id,
            name: row.name,
            sortOrder: row.sortOrder,
          ),
        )
        .toList();
  }

  Future<models.ActivityType> addActivityType(String name) async {
    final current = await getAllActivityTypes();
    final id = _uuid.v4();
    final sortOrder = current.isEmpty ? 0 : current.last.sortOrder + 1;

    await into(activityTypes).insert(
      ActivityTypesCompanion.insert(
        id: id,
        name: name.trim(),
        sortOrder: Value(sortOrder),
      ),
    );

    return models.ActivityType(id: id, name: name.trim(), sortOrder: sortOrder);
  }

  Future<void> updateActivityType(models.ActivityType type) async {
    await (update(activityTypes)..where((table) => table.id.equals(type.id)))
        .write(
      ActivityTypesCompanion(
        name: Value(type.name.trim()),
        sortOrder: Value(type.sortOrder),
      ),
    );
  }

  Future<void> deleteActivityType(String id) async {
    final usageCount = await (select(activityRecords)
          ..where((table) => table.activityTypeId.equals(id)))
        .get()
        .then((rows) => rows.length);

    if (usageCount > 0) {
      throw StateError('이 활동은 기록에 사용 중이라 삭제할 수 없습니다.');
    }

    await (delete(activityTypes)..where((table) => table.id.equals(id))).go();
  }

  Future<models.ActivityRecord> insertActivityRecord({
    required DateTime date,
    required String activityTypeId,
    required int count,
    required String content,
  }) async {
    final typeRow = await (select(activityTypes)
          ..where((table) => table.id.equals(activityTypeId)))
        .getSingleOrNull();

    if (typeRow == null) {
      throw StateError('선택한 활동을 찾을 수 없습니다.');
    }

    final id = _uuid.v4();
    final normalizedDate = DateTime(date.year, date.month, date.day);
    final createdAt = DateTime.now();

    await into(activityRecords).insert(
      ActivityRecordsCompanion.insert(
        id: id,
        date: normalizedDate,
        activityTypeId: activityTypeId,
        count: Value(count),
        content: Value(content.trim()),
        createdAt: createdAt,
      ),
    );

    return models.ActivityRecord(
      id: id,
      date: normalizedDate,
      activityTypeId: activityTypeId,
      activityTypeName: typeRow.name,
      count: count,
      content: content.trim(),
      createdAt: createdAt,
    );
  }

  Future<ActivityPeriodSummary> getPeriodSummary(
    DateTime start,
    DateTime end,
  ) async {
    final records = await getRecordsBetween(start, end);
    final grouped = <String, ActivitySummaryItem>{};

    for (final record in records) {
      final existing = grouped[record.activityTypeId];
      if (existing == null) {
        grouped[record.activityTypeId] = ActivitySummaryItem(
          activityTypeId: record.activityTypeId,
          activityTypeName: record.activityTypeName,
          totalCount: record.count,
          recordCount: 1,
          records: [record],
        );
      } else {
        grouped[record.activityTypeId] = ActivitySummaryItem(
          activityTypeId: existing.activityTypeId,
          activityTypeName: existing.activityTypeName,
          totalCount: existing.totalCount + record.count,
          recordCount: existing.recordCount + 1,
          records: [...existing.records, record],
        );
      }
    }

    final items = grouped.values.toList()
      ..sort((a, b) => a.activityTypeName.compareTo(b.activityTypeName));

    return ActivityPeriodSummary(
      startDate: DateTime(start.year, start.month, start.day),
      endDate: DateTime(end.year, end.month, end.day),
      items: items,
      totalRecords: records.length,
      totalCount: records.fold<int>(0, (sum, record) => sum + record.count),
    );
  }

  Future<List<models.ActivityRecord>> getRecordsBetween(
    DateTime start,
    DateTime end, {
    String? activityTypeId,
  }) async {
    final startDate = DateTime(start.year, start.month, start.day);
    final endDate = DateTime(end.year, end.month, end.day, 23, 59, 59);

    final query = select(activityRecords).join([
      innerJoin(
        activityTypes,
        activityTypes.id.equalsExp(activityRecords.activityTypeId),
      ),
    ])
      ..where(activityRecords.date.isBetweenValues(startDate, endDate));

    if (activityTypeId != null) {
      query.where(activityRecords.activityTypeId.equals(activityTypeId));
    }

    query.orderBy([
      OrderingTerm.asc(activityRecords.date),
      OrderingTerm.asc(activityTypes.sortOrder),
    ]);

    final rows = await query.get();

    return rows
        .map(
          (row) => models.ActivityRecord(
            id: row.readTable(activityRecords).id,
            date: row.readTable(activityRecords).date,
            activityTypeId: row.readTable(activityRecords).activityTypeId,
            activityTypeName: row.readTable(activityTypes).name,
            count: row.readTable(activityRecords).count,
            content: row.readTable(activityRecords).content,
            createdAt: row.readTable(activityRecords).createdAt,
          ),
        )
        .toList();
  }

  Future<void> updateActivityRecord({
    required String id,
    required DateTime date,
    required int count,
    required String content,
  }) async {
    final normalizedDate = DateTime(date.year, date.month, date.day);

    final updated = await (update(activityRecords)
          ..where((table) => table.id.equals(id)))
        .write(
      ActivityRecordsCompanion(
        date: Value(normalizedDate),
        count: Value(count),
        content: Value(content.trim()),
      ),
    );

    if (updated == 0) {
      throw StateError('기록을 찾을 수 없습니다.');
    }
  }

  Future<void> deleteActivityRecord(String id) async {
    final deleted = await (delete(activityRecords)
          ..where((table) => table.id.equals(id)))
        .go();

    if (deleted == 0) {
      throw StateError('기록을 찾을 수 없습니다.');
    }
  }
}
