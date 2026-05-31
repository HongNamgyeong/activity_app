import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../core/theme/app_colors.dart';
import '../providers/activity_record_provider.dart';
import '../providers/activity_type_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/count_stepper.dart';

class RecordScreen extends ConsumerStatefulWidget {
  const RecordScreen({super.key});

  @override
  ConsumerState<RecordScreen> createState() => _RecordScreenState();
}

class _RecordScreenState extends ConsumerState<RecordScreen> {
  DateTime _selectedDate = DateTime.now();
  String? _selectedTypeId;
  int _count = 0;
  final _contentController = TextEditingController();
  final _headerDateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ko', 'KR'),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.accent,
              onPrimary: Color(0xFF1E1B4B),
              surface: AppColors.surface,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _save() async {
    final types = ref.read(activityTypesProvider).value ?? [];
    final typeId = _selectedTypeId ?? (types.isNotEmpty ? types.first.id : null);

    if (typeId == null) {
      _showMessage('활동을 선택해 주세요.');
      return;
    }

    if (_count < 1) {
      _showMessage('횟수는 1 이상이어야 합니다.');
      return;
    }

    final success = await ref.read(recordSaveProvider.notifier).save(
          date: _selectedDate,
          activityTypeId: typeId,
          count: _count,
          content: _contentController.text,
        );

    if (!mounted) return;

    if (success) {
      setState(() {
        _count = 0;
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
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final typesAsync = ref.watch(activityTypesProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (types) {
        final selectedTypeId =
            _selectedTypeId ?? (types.isNotEmpty ? types.first.id : null);

        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            children: [
              Text(
                _headerDateFormat.format(_selectedDate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      '활동기록',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  Material(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(24),
                      onTap: _pickDate,
                      child: const Padding(
                        padding: EdgeInsets.all(10),
                        child: Icon(
                          Icons.church_outlined,
                          color: AppColors.textPrimary,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '활동 항목',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      key: ValueKey(selectedTypeId),
                      initialValue: selectedTypeId,
                      hint: const Text('활동 유형을 선택하세요'),
                      decoration: const InputDecoration(
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      items: types
                          .map(
                            (type) => DropdownMenuItem(
                              value: type.id,
                              child: Text(type.name),
                            ),
                          )
                          .toList(),
                      onChanged: types.isEmpty
                          ? null
                          : (value) => setState(() => _selectedTypeId = value),
                    ),
                    if (types.isEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '설정에서 활동 목록을 먼저 추가해 주세요.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 20),
                    Text(
                      '횟수 / 시간',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    CountStepper(
                      value: _count,
                      min: 0,
                      compact: true,
                      onChanged: (value) => setState(() => _count = value),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '활동 내용 및 비고',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _contentController,
                      minLines: 4,
                      maxLines: 8,
                      decoration: const InputDecoration(
                        hintText: '활동에 대한 구체적인 내용을 입력하세요...',
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: types.isEmpty ? null : _save,
                icon: const Icon(Icons.save_outlined),
                label: const Text('활동 기록 저장'),
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: AppColors.textMuted.withValues(alpha: 0.8),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '기록된 활동은 \'활동조회\' 탭에서 기간별로 모아볼 수 있습니다.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
