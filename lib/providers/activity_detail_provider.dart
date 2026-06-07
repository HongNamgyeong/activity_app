import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/activity_value_format.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_record.dart';
import '../models/activity_summary.dart';
import 'activity_record_provider.dart';
import 'backup_provider.dart';
import 'navigation_provider.dart';

class ActivityDetailState {
  const ActivityDetailState({
    this.activityTypeId,
    this.activityTypeName,
    this.measureType = ActivityMeasureType.count,
    this.startDate,
    this.endDate,
    this.records = const [],
    this.newestFirst = true,
    this.isLoading = false,
  });

  final String? activityTypeId;
  final String? activityTypeName;
  final ActivityMeasureType measureType;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ActivityRecord> records;
  final bool newestFirst;
  final bool isLoading;

  bool get hasSelection =>
      activityTypeId != null && startDate != null && endDate != null;

  int get totalCount => records.fold<int>(
        0,
        (sum, record) => sum +
            (measureType == ActivityMeasureType.time
                ? activityValueToMinutes(record.count, record.timeUnit)
                : record.count),
      );

  String get totalCountLabel => measureType == ActivityMeasureType.time
      ? formatTotalTimeValue(totalCount)
      : formatCountValue(totalCount, activityTypeName: activityTypeName);

  List<ActivityRecord> get sortedRecords {
    final copy = List<ActivityRecord>.from(records);
    copy.sort((a, b) {
      final compare = a.date.compareTo(b.date);
      if (compare != 0) {
        return newestFirst ? -compare : compare;
      }
      final timeA = a.recordTime ?? '';
      final timeB = b.recordTime ?? '';
      final timeCompare = timeA.compareTo(timeB);
      return newestFirst ? -timeCompare : timeCompare;
    });
    return copy;
  }

  ActivityDetailState copyWith({
    String? activityTypeId,
    String? activityTypeName,
    ActivityMeasureType? measureType,
    DateTime? startDate,
    DateTime? endDate,
    List<ActivityRecord>? records,
    bool? newestFirst,
    bool? isLoading,
    bool clearSelection = false,
  }) {
    return ActivityDetailState(
      activityTypeId:
          clearSelection ? null : (activityTypeId ?? this.activityTypeId),
      activityTypeName:
          clearSelection ? null : (activityTypeName ?? this.activityTypeName),
      measureType: clearSelection
          ? ActivityMeasureType.count
          : (measureType ?? this.measureType),
      startDate: clearSelection ? null : (startDate ?? this.startDate),
      endDate: clearSelection ? null : (endDate ?? this.endDate),
      records: records ?? this.records,
      newestFirst: newestFirst ?? this.newestFirst,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

final activityDetailProvider =
    NotifierProvider<ActivityDetailNotifier, ActivityDetailState>(
  ActivityDetailNotifier.new,
);

class ActivityDetailNotifier extends Notifier<ActivityDetailState> {
  @override
  ActivityDetailState build() => const ActivityDetailState();

  Future<void> openFromSummaryItem({
    required ActivitySummaryItem item,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    state = ActivityDetailState(
      activityTypeId: item.activityTypeId,
      activityTypeName: item.activityTypeName,
      measureType: item.measureType,
      startDate: startDate,
      endDate: endDate,
      records: item.records,
    );
    ref.read(mainTabIndexProvider.notifier).select(2);
  }

  Future<void> reload() async {
    final typeId = state.activityTypeId;
    final start = state.startDate;
    final end = state.endDate;

    if (typeId == null || start == null || end == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final records = await ref.read(activityRecordServiceProvider).getByType(
            activityTypeId: typeId,
            start: start,
            end: end,
          );
      state = state.copyWith(records: records, isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  void toggleSortOrder() {
    state = state.copyWith(newestFirst: !state.newestFirst);
  }

  Future<void> deleteRecord(String id) async {
    await ref.read(activityRecordServiceProvider).delete(id);
    await scheduleDataBackup(ref);
    await reload();
    await ref.read(inquiryProvider.notifier).refreshIfLoaded();
  }

  Future<void> updateRecord({
    required String id,
    required DateTime date,
    required int count,
    required String content,
    ActivityTimeUnit? timeUnit,
    String? recordTime,
  }) async {
    await ref.read(activityRecordServiceProvider).update(
          id: id,
          date: date,
          count: count,
          content: content,
          timeUnit: timeUnit,
          measureType: state.measureType,
          recordTime: recordTime,
        );
    await scheduleDataBackup(ref);
    await reload();
    await ref.read(inquiryProvider.notifier).refreshIfLoaded();
  }
}
