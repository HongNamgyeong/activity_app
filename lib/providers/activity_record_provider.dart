import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/activity_summary.dart';
import '../services/activity_record_service.dart';
import 'backup_provider.dart';
import 'database_provider.dart';

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
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final ActivityPeriodSummary? summary;
  final bool isLoading;
  final String? errorMessage;

  InquiryState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    ActivityPeriodSummary? summary,
    bool? isLoading,
    String? errorMessage,
    bool clearSummary = false,
    bool clearError = false,
  }) {
    return InquiryState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      summary: clearSummary ? null : (summary ?? this.summary),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

final inquiryProvider =
    NotifierProvider<InquiryNotifier, InquiryState>(InquiryNotifier.new);

class InquiryNotifier extends Notifier<InquiryState> {
  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  /// 조회 기간 기본값: 1주일 전 ~ 오늘
  static InquiryState initialState() {
    return InquiryState(
      startDate: _today.subtract(const Duration(days: 7)),
      endDate: _today,
    );
  }

  @override
  InquiryState build() => initialState();

  void selectRange(DateTime? start, DateTime? end) {
    state = state.copyWith(
      startDate: start,
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
      state = state.copyWith(errorMessage: '종료일은 시작일 이후여야 합니다.');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true, clearSummary: true);

    try {
      final summary = await ref
          .read(activityRecordServiceProvider)
          .getSummary(start, end);
      state = state.copyWith(summary: summary, isLoading: false);
    } catch (error) {
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
  }) async {
    state = const AsyncLoading();

    try {
      await ref.read(activityRecordServiceProvider).save(
            date: date,
            activityTypeId: activityTypeId,
            count: count,
            content: content,
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
