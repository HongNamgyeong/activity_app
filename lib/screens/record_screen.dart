import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
  int _count = 1;
  final _contentController = TextEditingController();
  final _dateFormat = DateFormat('yyyy년 M월 d일 (E)', 'ko_KR');

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

    final success = await ref.read(recordSaveProvider.notifier).save(
          date: _selectedDate,
          activityTypeId: typeId,
          count: _count,
          content: _contentController.text,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      setState(() {
        _count = 1;
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

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            const SectionTitle(
              title: '오늘의 활동을 기록합니다',
              subtitle: '활동 종류, 횟수, 내용을 입력해 저장하세요.',
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('기록 날짜', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_month_outlined),
                    label: Text(_dateFormat.format(_selectedDate)),
                  ),
                  const SizedBox(height: 20),
                  DropdownButtonFormField<String>(
                    initialValue: selectedTypeId,
                    decoration: const InputDecoration(
                      labelText: '활동 선택',
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
                    const SizedBox(height: 12),
                    Text(
                      '설정에서 활동 목록을 먼저 추가해 주세요.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            CountStepper(
              value: _count,
              onChanged: (value) => setState(() => _count = value),
            ),
            const SizedBox(height: 16),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('내용', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _contentController,
                    minLines: 4,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      hintText: '활동 내용을 입력하세요',
                      alignLabelWithHint: true,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: types.isEmpty ? null : _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('기록 저장'),
            ),
          ],
        );
      },
    );
  }
}
