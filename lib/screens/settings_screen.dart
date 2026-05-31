import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/app_colors.dart';
import '../models/activity_type.dart';
import '../providers/activity_type_provider.dart';
import '../widgets/app_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final typesAsync = ref.watch(activityTypesProvider);

    return typesAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (types) => ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        children: [
          const SectionTitle(
            title: '활동 목록 관리',
            subtitle: '기록 화면의 활동 선택 목록을 편집합니다.',
          ),
          const SizedBox(height: 20),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '등록된 활동 ${types.length}개',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () => _showTypeDialog(context, ref),
                      icon: const Icon(Icons.add),
                      label: const Text('추가'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '항목을 눌러 이름을 수정하거나 삭제할 수 있습니다.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          if (types.isEmpty)
            const AppCard(
              child: Text('등록된 활동이 없습니다. 추가 버튼으로 활동을 등록하세요.'),
            )
          else
            ...types.map(
              (type) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ActivityTypeTile(type: type),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showTypeDialog(
    BuildContext context,
    WidgetRef ref, {
    ActivityType? editing,
  }) async {
    final controller = TextEditingController(text: editing?.name ?? '');
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(editing == null ? '활동 추가' : '활동 수정'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: '활동 이름',
              hintText: '예: 방문, 기도',
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '활동 이름을 입력해 주세요.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved != true || !context.mounted) {
      controller.dispose();
      return;
    }

    try {
      if (editing == null) {
        await ref
            .read(activityTypesProvider.notifier)
            .addType(controller.text.trim());
      } else {
        await ref.read(activityTypesProvider.notifier).updateType(
              editing.copyWith(name: controller.text.trim()),
            );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error.toString())),
        );
      }
    } finally {
      controller.dispose();
    }
  }
}

class _ActivityTypeTile extends ConsumerWidget {
  const _ActivityTypeTile({required this.type});

  final ActivityType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppCard(
      padding: EdgeInsets.zero,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.goldMuted.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.label_outline, color: AppColors.burgundy),
        ),
        title: Text(type.name),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              tooltip: '수정',
              onPressed: () => _edit(context, ref),
              icon: const Icon(Icons.edit_outlined),
            ),
            IconButton(
              tooltip: '삭제',
              onPressed: () => _delete(context, ref),
              icon: const Icon(Icons.delete_outline),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final controller = TextEditingController(text: type.name);
    final formKey = GlobalKey<FormState>();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('활동 수정'),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(labelText: '활동 이름'),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return '활동 이름을 입력해 주세요.';
              }
              return null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(context, true);
              }
            },
            child: const Text('저장'),
          ),
        ],
      ),
    );

    if (saved == true) {
      if (!context.mounted) {
        controller.dispose();
        return;
      }
      try {
        await ref.read(activityTypesProvider.notifier).updateType(
              type.copyWith(name: controller.text.trim()),
            );
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
    controller.dispose();
  }

  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('활동 삭제'),
        content: Text('"${type.name}" 항목을 삭제하시겠습니까?'),
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

    if (confirmed == true) {
      if (!context.mounted) {
        return;
      }
      try {
        await ref.read(activityTypesProvider.notifier).deleteType(type.id);
      } catch (error) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.toString())),
          );
        }
      }
    }
  }
}
