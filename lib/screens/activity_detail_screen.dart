import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/activity_value_format.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_record.dart';
import '../providers/activity_detail_provider.dart';
import '../providers/navigation_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/count_stepper.dart';
import '../widgets/time_stepper.dart';

class ActivityDetailScreen extends ConsumerWidget {
  const ActivityDetailScreen({super.key});

  static final _dateFormat = DateFormat('yyyy.MM.dd');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(activityDetailProvider);

    if (!detail.hasSelection) {
      return SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.list_alt_outlined,
                  size: 56,
                  color: AppColors.textMuted.withValues(alpha: 0.6),
                ),
                const SizedBox(height: 16),
                Text(
                  '활동상세내역',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '활동조회에서 항목을 선택하면\n일자별 기록을 확인할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    final records = detail.sortedRecords;

    return SafeArea(
      child: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            children: [
              _SummaryHeader(detail: detail),
              const SizedBox(height: 24),
              Row(
                children: [
                  Text('일자별 기록',
                      style: Theme.of(context).textTheme.titleLarge),
                  const Spacer(),
                  _SortButton(
                    newestFirst: detail.newestFirst,
                    onTap: () =>
                        ref.read(activityDetailProvider.notifier).toggleSortOrder(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (detail.isLoading)
                const Padding(
                  padding: EdgeInsets.all(32),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (records.isEmpty)
                AppCard(
                  child: Text(
                    '선택한 기간에 기록이 없습니다.',
                    style: Theme.of(context).textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                ...records.map(
                  (record) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RecordCard(
                      record: record,
                      onEdit: () => _editRecord(context, ref, record),
                      onDelete: () => _deleteRecord(context, ref, record),
                    ),
                  ),
                ),
              if (records.isNotEmpty) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '모든 내역을 확인했습니다',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ],
          ),
          Positioned(
            right: 20,
            bottom: 16,
            child: FloatingActionButton.extended(
              onPressed: () =>
                  ref.read(mainTabIndexProvider.notifier).select(1),
              backgroundColor: AppColors.accent,
              foregroundColor: AppColors.onAccent,
              icon: const Icon(Icons.add),
              label: const Text('기록 추가'),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteRecord(
    BuildContext context,
    WidgetRef ref,
    ActivityRecord record,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록 삭제'),
        content: const Text('이 활동 기록을 삭제하시겠습니까?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        await ref.read(activityDetailProvider.notifier).deleteRecord(record.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
  }

  Future<void> _editRecord(
    BuildContext context,
    WidgetRef ref,
    ActivityRecord record,
  ) async {
    final detail = ref.read(activityDetailProvider);
    final contentController = TextEditingController(text: record.content);
    var count = record.count;
    var date = record.date;
    var selectedTime =
        parseClockTime(record.recordTime) ?? TimeOfDay.fromDateTime(record.date);
    var timeUnit = record.timeUnit ?? ActivityTimeUnit.minute;
    final isTimeType = detail.measureType == ActivityMeasureType.time;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('기록 수정'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: date,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2035),
                      locale: const Locale('ko', 'KR'),
                    );
                    if (picked != null) {
                      setDialogState(() => date = picked);
                    }
                  },
                  child: Text(formatRecordDateLabel(date)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      initialEntryMode: TimePickerEntryMode.input,
                      builder: (context, child) {
                        return MediaQuery(
                          data: MediaQuery.of(context)
                              .copyWith(alwaysUse24HourFormat: true),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setDialogState(() => selectedTime = picked);
                    }
                  },
                  child: Text('시각 ${formatClockTime(selectedTime)}'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: '활동 내용',
                  ),
                ),
                const SizedBox(height: 12),
                Text(isTimeType ? '시간' : '횟수'),
                const SizedBox(height: 8),
                if (isTimeType)
                  TimeStepper(
                    value: count,
                    timeUnit: timeUnit,
                    min: 1,
                    onValueChanged: (value) =>
                        setDialogState(() => count = value),
                    onTimeUnitChanged: (unit) =>
                        setDialogState(() => timeUnit = unit),
                  )
                else
                  CountStepper(
                    value: count,
                    min: 1,
                    unitLabel: countUnitLabel(detail.activityTypeName),
                    onChanged: (value) => setDialogState(() => count = value),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );

    if (saved == true) {
      try {
        await ref.read(activityDetailProvider.notifier).updateRecord(
              id: record.id,
              date: date,
              count: count,
              content: contentController.text,
              timeUnit: isTimeType ? timeUnit : null,
              recordTime: formatClockTime(selectedTime),
            );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
    contentController.dispose();
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({required this.detail});

  final ActivityDetailState detail;

  @override
  Widget build(BuildContext context) {
    final dateRange =
        '${ActivityDetailScreen._dateFormat.format(detail.startDate!)} - ${ActivityDetailScreen._dateFormat.format(detail.endDate!)}';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.headerSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  dateRange,
                  style: const TextStyle(
                    color: AppColors.headerTextMuted,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.calendar_month_outlined,
                color: AppColors.headerTextMuted.withValues(alpha: 0.8),
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            detail.activityTypeName ?? '',
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: detail.totalCountLabel,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppColors.headerHighlight,
                  ),
                ),
                const TextSpan(text: ' 실시됨'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SortButton extends StatelessWidget {
  const _SortButton({
    required this.newestFirst,
    required this.onTap,
  });

  final bool newestFirst;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sort, size: 16, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                newestFirst ? '최신순' : '오래된순',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({
    required this.record,
    required this.onEdit,
    required this.onDelete,
  });

  final ActivityRecord record;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  formatRecordDateLabel(
                    record.date,
                    recordTime: record.recordTime,
                  ),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              const Spacer(),
              Text(
                formatRecordValue(
                  count: record.count,
                  measureType: record.measureType,
                  timeUnit: record.timeUnit,
                  activityTypeName: record.activityTypeName,
                ),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '활동 내용',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 4),
          Text(
            record.content.isEmpty ? '(내용 없음)' : record.content,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontSize: 14,
                  height: 1.5,
                ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: AppColors.textSecondary,
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline, size: 20),
                color: AppColors.destructive,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
