import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/utils/inquiry_period_utils.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_summary.dart';
import '../models/legio_meeting_schedule.dart';
import '../services/activity_record_service.dart';
import 'backup_provider.dart';
import 'database_provider.dart';
import 'legio_meeting_provider.dart';

final activityRecordServiceProvider = Provider<ActivityRecordService>((ref) {
  return ActivityRecordService(ref.watch(appDatabaseProvider));
});

class InquiryState {
  const InquiryState({
    this.startDate,
    this.endDate,
    this.summary,
    this.isLoading = false,
    this.errorMessage,
    this.initialized = false,
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ActivityPeriodSummary? summary;
  final bool isLoading;
  final String? errorMessage;
  final bool initialized;

  InquiryState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ActivityPeriodSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool? initialized,
    bool clearSummary = false,
    bool clearError = false,
  }) {
    return InquiryState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      summary: clearSummary ? null : (summary ?? this.summary),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      initialized: initialized ?? this.initialized,
    );
  }
}

final inquiryProvider =
    NotifierProvider<InquiryNotifier, InquiryState>(InquiryNotifier.new);

class InquiryNotifier extends Notifier<InquiryState> {
  int _searchGeneration = 0;

  @override
  InquiryState build() => const InquiryState();

  Future<void> initialize() async {
    if (state.initialized) return;

    await ref.read(legioMeetingScheduleProvider.notifier).load();
    final schedule = ref.read(legioMeetingScheduleProvider);
    state = _defaultState(schedule).copyWith(initialized: true);
  }

  InquiryState _defaultState(LegioMeetingSchedule? schedule) {
    final now = DateTime.now();
    final start = schedule == null
        ? DateTime(now.year, now.month, now.day)
            .subtract(const Duration(days: 6))
        : mostRecentPastLegioMeeting(reference: now, schedule: schedule);

    return InquiryState(
      startDate: start,
      endDate: now,
      initialized: true,
    );
  }

  void applyLegioSchedule(LegioMeetingSchedule schedule) {
    resetStartToLegioDefault(schedule);
  }

  void resetStartToLegioDefault(LegioMeetingSchedule schedule) {
    state = state.copyWith(
      startDate: mostRecentPastLegioMeeting(
        reference: DateTime.now(),
        schedule: schedule,
      ),
      clearSummary: true,
      clearError: true,
    );
  }

  void selectStartDate(DateTime pickedDate) {
    final existing = state.startDate ?? DateTime.now();
    final start = combineDateAndTime(
      pickedDate,
      TimeOfDay(hour: existing.hour, minute: existing.minute),
    );

    state = state.copyWith(
      startDate: start,
      clearSummary: true,
      clearError: true,
    );
  }

  void selectStartTime(TimeOfDay time) {
    final existing = state.startDate ?? DateTime.now();
    final start = combineDateAndTime(existing, time);

    state = state.copyWith(
      startDate: start,
      clearSummary: true,
      clearError: true,
    );
  }

  void selectEndDate(DateTime pickedDate) {
    final existing = state.endDate ?? DateTime.now();
    final end = combineDateAndTime(
      pickedDate,
      TimeOfDay(hour: existing.hour, minute: existing.minute),
    );

    state = state.copyWith(
      endDate: end,
      clearSummary: true,
      clearError: true,
    );
  }

  void selectEndTime(TimeOfDay time) {
    final existing = state.endDate ?? DateTime.now();
    final end = combineDateAndTime(existing, time);

    state = state.copyWith(
      endDate: end,
      clearSummary: true,
      clearError: true,
    );
  }

  Future<void> search() async {
    final start = state.startDate;
    final end = state.endDate;

    if (start == null || end == null) {
      state = state.copyWith(errorMessage: '조회 기간을 선택해 주세요.');
      return;
    }

    if (end.isBefore(start)) {
      state = state.copyWith(errorMessage: '종료일시는 시작일시 이후여야 합니다.');
      return;
    }

    final generation = ++_searchGeneration;
    state = state.copyWith(isLoading: true, clearError: true, clearSummary: true);

    try {
      final summary = await ref
          .read(activityRecordServiceProvider)
          .getSummary(start, end);
      if (generation != _searchGeneration) return;
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (error) {
      if (generation != _searchGeneration) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> refreshIfLoaded() async {
    if (state.summary == null || state.startDate == null || state.endDate == null) {
      return;
    }
    await search();
  }
}

final recordSaveProvider =
    AsyncNotifierProvider<RecordSaveNotifier, void>(RecordSaveNotifier.new);

class RecordSaveNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<bool> save({
    required DateTime date,
    required String activityTypeId,
    required int count,
    required String content,
    ActivityTimeUnit? timeUnit,
    String? recordTime,
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(activityRecordServiceProvider).save(
            date: date,
            activityTypeId: activityTypeId,
            count: count,
            content: content,
            timeUnit: timeUnit,
            recordTime: recordTime,
          );
      await scheduleDataBackup(ref);
      state = const AsyncData(null);
      return true;
    } catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
      return false;
    }
  }
}
