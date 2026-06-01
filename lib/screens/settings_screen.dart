import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../models/activity_measure_type.dart';
import '../models/activity_type.dart';
import '../providers/activity_type_provider.dart';
import '../providers/backup_provider.dart';
import '../services/backup_service.dart';
import '../widgets/app_card.dart';

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
      final result = await ref
          .read(backupServiceProvider)
          .restoreFromBackupFile(force: true);
      if (!mounted) return;

      switch (result) {
        case BackupRestoreResult.restored:
          await ref.read(activityTypesProvider.notifier).refresh();
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
            const SnackBar(content: Text('백업 복원에 실패했습니다.')),
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

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (types) => SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          children: [
                  const ScreenHeader(
                    title: '활동 항목 설정',
                    subtitle: '활동 보고에 사용될 카테고리를 관리합니다',
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
                  const SizedBox(height: 12),
                  if (types.isEmpty)
                    const AppCard(
                      child: Text('등록된 활동이 없습니다. 아래 버튼으로 추가하세요.'),
                    )
                  else
                    ...types.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ActivityTypeTile(
                          type: type,
                          onMeasureTypeChanged: (measureType) async {
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
                          onDelete: () => _deleteType(type.id, type.name),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _showAddActivityDialog,
                    icon: const Icon(Icons.add),
                    label: const Text('새 활동 추가'),
                  ),
          ],
        ),
      ),
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

class _ActivityTypeTile extends StatelessWidget {
  const _ActivityTypeTile({
    required this.type,
    required this.onMeasureTypeChanged,
    required this.onDelete,
  });

  final ActivityType type;
  final ValueChanged<ActivityMeasureType> onMeasureTypeChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
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
