import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_record.dart';
import '../models/activity_summary.dart';
import 'activity_record_provider.dart';
import 'navigation_provider.dart';

class ActivityDetailState {
  const ActivityDetailState({
    this.activityTypeId,
    this.activityTypeName,
    this.startDate,
    this.endDate,
    this.records = const [],
    this.newestFirst = true,
    this.isLoading = false,
  });

  final String? activityTypeId;
  final String? activityTypeName;
  final DateTime? startDate;
  final DateTime? endDate;
  final List<ActivityRecord> records;
  final bool newestFirst;
  final bool isLoading;

  bool get hasSelection =>
      activityTypeId != null && startDate != null && endDate != null;

  int get totalCount =>
      records.fold<int>(0, (sum, record) => sum + record.count);

  List<ActivityRecord> get sortedRecords {
    final copy = List<ActivityRecord>.from(records);
    copy.sort((a, b) {
      final compare = a.date.compareTo(b.date);
      return newestFirst ? -compare : compare;
    });
    return copy;
  }

  ActivityDetailState copyWith({
    String? activityTypeId,
    String? activityTypeName,
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
    await reload();
    await ref.read(inquiryProvider.notifier).refreshIfLoaded();
  }

  Future<void> updateRecord({
    required String id,
    required DateTime date,
    required int count,
    required String content,
  }) async {
    await ref.read(activityRecordServiceProvider).update(
          id: id,
          date: date,
          count: count,
          content: content,
        );
    await reload();
    await ref.read(inquiryProvider.notifier).refreshIfLoaded();
  }
}
