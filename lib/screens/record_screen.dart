import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/activity_value_format.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_type.dart';
import '../providers/activity_record_provider.dart';
import '../providers/activity_type_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/count_stepper.dart';
import '../widgets/record_date_picker.dart';
import '../widgets/record_time_picker.dart';
import '../widgets/time_stepper.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  late DateTime _selectedDate = _today;

  static DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  String? _selectedTypeId;
  int _count = 0;
  ActivityTimeUnit _timeUnit = ActivityTimeUnit.minute;
  late TimeOfDay _selectedTime = TimeOfDay.fromDateTime(DateTime.now());
  final _contentController = TextEditingController();

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// 목록에 없는(삭제된) ID가 남아 있으면 첫 항목 또는 null로 정규화합니다.
  String? _resolveTypeId(List<ActivityType> types) {
    if (types.isEmpty) return null;
    if (_selectedTypeId != null &&
        types.any((type) => type.id == _selectedTypeId)) {
      return _selectedTypeId;
    }
    return types.first.id;
  }

  ActivityType? _selectedType(List<ActivityType> types) {
    final typeId = _resolveTypeId(types);
    if (typeId == null) return null;
    return types.firstWhere((type) => type.id == typeId);
  }

  void _onTypeChanged(String? typeId, List<ActivityType> types) {
    final previous = _selectedType(types);
    setState(() {
      _selectedTypeId = typeId;
      final next = _selectedType(types);
      if (previous?.id != next?.id) {
        _count = 0;
        _timeUnit = ActivityTimeUnit.minute;
      }
    });
  }

  Future<void> _save(List<ActivityType> types) async {
    final selected = _selectedType(types);

    if (selected == null) {
      _showMessage('활동을 선택해 주세요.');
      return;
    }

    if (_count < 1) {
      _showMessage(
        selected.measureType == ActivityMeasureType.time
            ? '시간은 1 이상이어야 합니다.'
            : '횟수는 1 이상이어야 합니다.',
      );
      return;
    }

    final success = await ref.read(recordSaveProvider.notifier).save(
          date: _selectedDate,
          activityTypeId: selected.id,
          count: _count,
          content: _contentController.text,
          timeUnit: selected.measureType == ActivityMeasureType.time
              ? _timeUnit
              : null,
          recordTime: formatClockTime(_selectedTime),
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _count = 0;
        _timeUnit = ActivityTimeUnit.minute;
        _contentController.clear();
      });
      _showMessage('활동 기록을 저장했습니다.');
    } else {
      final error = ref.read(recordSaveProvider).error;
      _showMessage(error?.toString() ?? '저장에 실패했습니다.');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 88),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(activityTypesProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (types) {
        final effectiveTypeId = _resolveTypeId(types);
        final selectedType = _selectedType(types);
        final isTimeType =
            selectedType?.measureType == ActivityMeasureType.time;

        return SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                child: Text(
                  '활동기록',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        RecordDatePicker(
                          compact: true,
                          selectedDate: _selectedDate,
                          onDateChanged: (date) =>
                              setState(() => _selectedDate = date),
                        ),
                        const SizedBox(height: 12),
                        RecordTimePicker(
                          compact: true,
                          selectedTime: _selectedTime,
                          onTimeChanged: (time) =>
                              setState(() => _selectedTime = time),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '활동 항목',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        _ActivityTypeDropdown(
                          types: types,
                          selectedId: effectiveTypeId,
                          onChanged: (value) => _onTypeChanged(value, types),
                        ),
                        if (types.isEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            '설정에서 활동 목록을 먼저 추가해 주세요.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          isTimeType ? '시간' : '횟수',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        if (isTimeType)
                          TimeStepper(
                            value: _count,
                            timeUnit: _timeUnit,
                            min: 0,
                            onValueChanged: (value) =>
                                setState(() => _count = value),
                            onTimeUnitChanged: (unit) =>
                                setState(() => _timeUnit = unit),
                          )
                        else
                          CountStepper(
                            value: _count,
                            min: 0,
                            compact: true,
                            unitLabel: countUnitLabel(selectedType?.name),
                            onChanged: (value) =>
                                setState(() => _count = value),
                          ),
                        const SizedBox(height: 12),
                        Text(
                          '활동 내용 및 비고',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _contentController,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: '활동에 대한 구체적인 내용을 입력하세요...',
                            alignLabelWithHint: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    FilledButton.icon(
                      onPressed: types.isEmpty ? null : () => _save(types),
                      icon: const Icon(Icons.save_outlined, size: 20),
                      label: const Text('활동 기록 저장'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '기록된 활동은 \'활동조회\' 탭에서 기간별로 모아볼 수 있습니다.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 11,
                            height: 1.3,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// DropdownButtonFormField의 initialValue 오류를 피하기 위해
/// 항상 목록에 존재하는 value만 사용하는 드롭다운입니다.
class _ActivityTypeDropdown extends StatelessWidget {
  const _ActivityTypeDropdown({
    required this.types,
    required this.selectedId,
    required this.onChanged,
  });

  final List<ActivityType> types;
  final String? selectedId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    if (types.isEmpty) {
      return InputDecorator(
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
        child: Text(
          '활동 유형을 선택하세요',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppColors.textMuted,
              ),
        ),
      );
    }

    final items = types
        .map(
          (type) => DropdownMenuItem<String>(
            value: type.id,
            child: Text(type.name),
          ),
        )
        .toList();

    final value = selectedId != null &&
            items.any((item) => item.value == selectedId)
        ? selectedId
        : items.first.value;

    return InputDecorator(
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          hint: const Text('활동 유형을 선택하세요'),
          dropdownColor: AppColors.surfaceElevated,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
