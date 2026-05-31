import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_constants.dart';
import '../core/theme/app_colors.dart';
import '../providers/activity_type_provider.dart';
import '../providers/backup_provider.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  final _addController = TextEditingController();
  DateTime? _lastBackupTime;
  bool _backupBusy = false;

  @override
  void initState() {
    super.initState();
    _loadLastBackupTime();
  }

  @override
  void dispose() {
    _addController.dispose();
    super.dispose();
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

  Future<void> _runRestore({required bool force}) async {
    setState(() => _backupBusy = true);
    try {
      final restored = await ref
          .read(backupServiceProvider)
          .restoreFromBackupFile(force: force);
      if (!mounted) return;

      if (restored) {
        await ref.read(activityTypesProvider.notifier).refresh();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('백업에서 데이터를 복원했습니다.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('복원할 백업이 없거나, 이미 최신 데이터입니다.'),
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

  Future<void> _addType() async {
    final name = _addController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('활동 이름을 입력해 주세요.')),
      );
      return;
    }

    try {
      await ref.read(activityTypesProvider.notifier).addType(name);
      _addController.clear();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    }
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                          '기록은 기기 안에 저장됩니다. 앱을 삭제하면 기본적으로 초기화되지만, '
                          '자동 백업 파일(Android: 다운로드 폴더의 ${AppConstants.backupFileName})과 '
                          'Google 계정 백업으로 재설치 후 복원을 시도합니다.',
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
                              : () => _runRestore(force: false),
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
                      child: Text('등록된 활동이 없습니다. 아래에서 추가하세요.'),
                    )
                  else
                    ...types.map(
                      (type) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ActivityTypeTile(
                          name: type.name,
                          onDelete: () => _deleteType(type.id, type.name),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              decoration: const BoxDecoration(
                color: AppColors.background,
                border: Border(
                  top: BorderSide(color: AppColors.border, width: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    '새 활동 추가',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '활동 명칭',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addController,
                          decoration: const InputDecoration(
                            hintText: '예: 묵주기도',
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 14,
                            ),
                          ),
                          onSubmitted: (_) => _addType(),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Material(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: _addType,
                          child: const SizedBox(
                            width: 52,
                            height: 52,
                            child: Icon(
                              Icons.add,
                              color: Color(0xFF1E1B4B),
                              size: 28,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline,
                        size: 14,
                        color: AppColors.textMuted.withValues(alpha: 0.8),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '추가된 항목은 활동 기록 탭의 선택 목록에 즉시 반영됩니다.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 12,
                              ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityTypeTile extends StatelessWidget {
  const _ActivityTypeTile({
    required this.name,
    required this.onDelete,
  });

  final String name;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
              Icons.church_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              name,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline),
            color: const Color(0xFFF87171),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}
