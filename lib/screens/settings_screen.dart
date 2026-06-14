import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/activity_value_format.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_type.dart';
import '../models/legio_meeting_schedule.dart';
import '../providers/activity_type_provider.dart';
import '../providers/backup_provider.dart';
import '../providers/activity_record_provider.dart';
import '../providers/legio_meeting_provider.dart';
import '../services/android_public_backup.dart';
import '../services/backup_service.dart';
import '../widgets/app_card.dart';
import '../widgets/record_time_picker.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  DateTime? _lastBackupTime;
  bool _backupBusy = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(legioMeetingScheduleProvider.notifier).load();
    });
  }

  Future<void> _loadLastBackupTime() async {
    final time = await ref.read(backupServiceProvider).lastBackupTime();
    if (mounted) {
      setState(() => _lastBackupTime = time);
    }
  }

  Future<void> _runBackup() async {
    setState(() => _backupBusy = true);
    try {
      if (Platform.isAndroid) {
        final granted = await AndroidPublicBackup.ensureAccess(context: context);
        if (!granted) return;
      }

      final time = await ref.read(backupServiceProvider).writeBackup();
      if (mounted) {
        setState(() => _lastBackupTime = time);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업 파일을 저장했습니다.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('백업 실패: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
      }
    }
  }

  Future<void> _runRestore() async {
    setState(() => _backupBusy = true);
    try {
      if (Platform.isAndroid) {
        final granted = await AndroidPublicBackup.ensureAccess(context: context);
        if (!granted) return;
      }

      final result = await ref
          .read(backupServiceProvider)
          .restoreFromBackupFile(force: true);
      if (!mounted) return;

      switch (result) {
        case BackupRestoreResult.restored:
          await ref.read(activityTypesProvider.notifier).refresh();
          await ref.read(legioMeetingScheduleProvider.notifier).load();
          final legioSchedule = ref.read(legioMeetingScheduleProvider);
          if (legioSchedule != null) {
            ref
                .read(inquiryProvider.notifier)
                .applyLegioSchedule(legioSchedule);
          }
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('백업에서 데이터를 복원했습니다.')),
          );
        case BackupRestoreResult.notFound:
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '다운로드 폴더에 ${AppConstants.backupFileName} 파일이 없습니다. '
                '재설치 전에 설정에서 「지금 백업하기」를 눌러 주세요.',
              ),
            ),
          );
        case BackupRestoreResult.empty:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('백업 파일에 복원할 데이터가 없습니다.')),
          );
        case BackupRestoreResult.upToDate:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('이미 최신 데이터입니다.')),
          );
        case BackupRestoreResult.failed:
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                '백업 복원에 실패했습니다. 다운로드/LegioActivityReport 폴더의 '
                '백업 파일과 접근 권한을 확인해 주세요.',
              ),
            ),
          );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('복원 실패: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _backupBusy = false);
        await _loadLastBackupTime();
      }
    }
  }

  Future<void> _addType(String name, ActivityMeasureType measureType) async {
    try {
      await ref
          .read(activityTypesProvider.notifier)
          .addType(name, measureType: measureType);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('"$name" 활동을 추가했습니다.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  Future<void> _showLegioMeetingDialog() async {
    final current = ref.read(legioMeetingScheduleProvider);
    final result = await showDialog<LegioMeetingSchedule>(
      context: context,
      builder: (context) => _LegioMeetingDialog(
        initial: current ??
            const LegioMeetingSchedule(weekday: 3, meetingTime: '19:00'),
      ),
    );

    if (result == null || !mounted) return;

    await ref.read(legioMeetingScheduleProvider.notifier).save(result);
    ref.read(inquiryProvider.notifier).applyLegioSchedule(result);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('주회시간을 ${result.displayLabel}로 저장했습니다.')),
      );
    }
  }

  Future<void> _showAddActivityDialog() async {
    final result = await showDialog<({String name, ActivityMeasureType measureType})?>(
      context: context,
      builder: (context) => const _AddActivityDialog(),
    );

    if (result == null || !mounted) return;

    await _addType(result.name, result.measureType);
  }

  Future<void> _deleteType(String id, String name) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('활동 삭제'),
        content: Text('"$name" 항목을 삭제하시겠습니까?'),
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

    if (confirmed != true || !mounted) return;

    try {
      await ref.read(activityTypesProvider.notifier).deleteType(id);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(activityTypesProvider);
    final legioSchedule = ref.watch(legioMeetingScheduleProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (types) => SafeArea(
        child: Stack(
          children: [
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
              children: [
                  const ScreenHeader(
                    title: '활동 항목 설정',
                    subtitle: '활동 보고에 사용될 카테고리를 관리합니다',
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle(title: '레지오 주회시간'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: _showLegioMeetingDialog,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: AppColors.surfaceElevated,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.event_repeat,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: legioSchedule == null
                                  ? Text(
                                      '요일과 시간을 설정해 주세요',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: AppColors.textMuted,
                                          ),
                                    )
                                  : Text(
                                      legioSchedule.displayLabel,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w700,
                                            color: AppColors.accent,
                                          ),
                                    ),
                            ),
                            Icon(
                              Icons.chevron_right,
                              color:
                                  AppColors.textMuted.withValues(alpha: 0.8),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const SectionTitle(title: '데이터 백업'),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '「지금 백업하기」를 누르면 다운로드/LegioActivityReport 폴더에 '
                          '${AppConstants.backupFileName} 한 개만 덮어씁니다. '
                          '복원 시 가장 최근 백업을 사용합니다.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (_lastBackupTime != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '마지막 백업: ${DateFormat('yyyy.MM.dd HH:mm').format(_lastBackupTime!)}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.accent,
                                ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        FilledButton(
                          onPressed: _backupBusy ? null : _runBackup,
                          child: _backupBusy
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('지금 백업하기'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton(
                          onPressed: _backupBusy
                              ? null
                              : _runRestore,
                          child: const Text('백업에서 복원'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SectionTitle(
                    title: '현재 활동 목록',
                    trailing: Text(
                      '총 ${types.length}개',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.accent,
                          ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '길게 눌러 드래그하면 우선순위를 변경할 수 있습니다.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                  const SizedBox(height: 12),
                  if (types.isEmpty)
                    const AppCard(
                      child: Text(
                        '등록된 활동이 없습니다. 우측 하단 「활동목록 추가」 버튼을 눌러 주세요.',
                      ),
                    )
                  else
                    _ReorderableActivityTypeList(
                      types: ActivityType.sortedByPriority(types),
                      onReorder: (orderedIds) async {
                        try {
                          await ref
                              .read(activityTypesProvider.notifier)
                              .reorderTypes(orderedIds);
                        } catch (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      onMeasureTypeChanged: (type, measureType) async {
                        try {
                          await ref
                              .read(activityTypesProvider.notifier)
                              .updateType(
                                type.copyWith(measureType: measureType),
                              );
                        } catch (error) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.toString())),
                            );
                          }
                        }
                      },
                      onDelete: _deleteType,
                    ),
              ],
            ),
            Positioned(
              right: 20,
              bottom: 16,
              child: FloatingActionButton.extended(
                onPressed: _showAddActivityDialog,
                backgroundColor: AppColors.accent,
                foregroundColor: AppColors.onAccent,
                icon: const Icon(Icons.add),
                label: const Text('활동목록 추가'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegioMeetingDialog extends StatefulWidget {
  const _LegioMeetingDialog({required this.initial});

  final LegioMeetingSchedule initial;

  @override
  State<_LegioMeetingDialog> createState() => _LegioMeetingDialogState();
}

class _LegioMeetingDialogState extends State<_LegioMeetingDialog> {
  late int _weekday = widget.initial.weekday;
  late TimeOfDay _time = widget.initial.time;

  void _submit() {
    Navigator.pop(
      context,
      LegioMeetingSchedule(
        weekday: _weekday,
        meetingTime: formatClockTime(_time),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('레지오 주회시간'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '주회 요일',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            DecoratedBox(
              decoration: BoxDecoration(
                color: AppColors.inputBackground,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: DropdownButton<int>(
                  value: _weekday,
                  isExpanded: true,
                  underline: const SizedBox.shrink(),
                  items: LegioMeetingSchedule.weekdayLabels.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _weekday = value);
                    }
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            RecordTimePicker(
              selectedTime: _time,
              onTimeChanged: (time) => setState(() => _time = time),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('저장'),
        ),
      ],
    );
  }
}

class _AddActivityDialog extends StatefulWidget {
  const _AddActivityDialog();

  @override
  State<_AddActivityDialog> createState() => _AddActivityDialogState();
}

class _AddActivityDialogState extends State<_AddActivityDialog> {
  final _nameController = TextEditingController();
  ActivityMeasureType _measureType = ActivityMeasureType.count;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('활동 이름을 입력해 주세요.')),
      );
      return;
    }
    Navigator.pop(context, (name: name, measureType: _measureType));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('새 활동 추가'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '활동 명칭',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nameController,
              autofocus: true,
              textInputAction: TextInputAction.done,
              decoration: const InputDecoration(
                hintText: '예: 묵주기도',
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            Text(
              '기록 단위',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SegmentedButton<ActivityMeasureType>(
              segments: const [
                ButtonSegment(
                  value: ActivityMeasureType.count,
                  label: Text('횟수'),
                ),
                ButtonSegment(
                  value: ActivityMeasureType.time,
                  label: Text('시간'),
                ),
              ],
              selected: {_measureType},
              onSelectionChanged: (selection) {
                setState(() => _measureType = selection.first);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('추가'),
        ),
      ],
    );
  }
}

class _ReorderableActivityTypeList extends StatelessWidget {
  const _ReorderableActivityTypeList({
    required this.types,
    required this.onReorder,
    required this.onMeasureTypeChanged,
    required this.onDelete,
  });

  final List<ActivityType> types;
  final Future<void> Function(List<String> orderedIds) onReorder;
  final Future<void> Function(ActivityType type, ActivityMeasureType measureType)
      onMeasureTypeChanged;
  final Future<void> Function(String id, String name) onDelete;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      buildDefaultDragHandles: false,
      itemCount: types.length,
      onReorderItem: (oldIndex, newIndex) async {
        final reordered = [...types];
        final moved = reordered.removeAt(oldIndex);
        reordered.insert(newIndex, moved);
        await onReorder(reordered.map((type) => type.id).toList());
      },
      itemBuilder: (context, index) {
        final type = types[index];
        return Padding(
          key: ValueKey(type.id),
          padding: const EdgeInsets.only(bottom: 8),
          child: _ActivityTypeTile(
            type: type,
            priority: index + 1,
            dragIndex: index,
            onMeasureTypeChanged: (measureType) =>
                onMeasureTypeChanged(type, measureType),
            onDelete: () => onDelete(type.id, type.name),
          ),
        );
      },
    );
  }
}

class _ActivityTypeTile extends StatelessWidget {
  const _ActivityTypeTile({
    required this.type,
    required this.onMeasureTypeChanged,
    required this.onDelete,
    this.priority,
    this.dragIndex,
  });

  final ActivityType type;
  final ValueChanged<ActivityMeasureType> onMeasureTypeChanged;
  final VoidCallback onDelete;
  final int? priority;
  final int? dragIndex;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              if (dragIndex != null)
                ReorderableDragStartListener(
                  index: dragIndex!,
                  child: const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.drag_handle,
                      color: AppColors.textMuted,
                    ),
                  ),
                ),
              if (priority != null)
                Container(
                  width: 28,
                  height: 28,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$priority',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
              if (priority != null) const SizedBox(width: 10),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.church_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  type.name,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
                color: AppColors.destructive,
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          const SizedBox(height: 10),
          SegmentedButton<ActivityMeasureType>(
            segments: const [
              ButtonSegment(
                value: ActivityMeasureType.count,
                label: Text('횟수'),
              ),
              ButtonSegment(
                value: ActivityMeasureType.time,
                label: Text('시간'),
              ),
            ],
            selected: {type.measureType},
            onSelectionChanged: (selection) {
              onMeasureTypeChanged(selection.first);
            },
          ),
        ],
      ),
    );
  }
}
