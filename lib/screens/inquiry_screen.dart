import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/activity_detail_provider.dart';
import '../providers/activity_record_provider.dart';
import '../widgets/app_card.dart';
import '../widgets/date_range_picker_card.dart';
import '../widgets/summary_section.dart';

class InquiryScreen extends ConsumerWidget {
  const InquiryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inquiry = ref.watch(inquiryProvider);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        children: [
          const ScreenHeader(
            title: '활동조회',
            subtitle: '기간별 활동 내역을 확인하세요',
          ),
          const SizedBox(height: 24),
          DateRangePickerCard(
            startDate: inquiry.startDate,
            endDate: inquiry.endDate,
            isLoading: inquiry.isLoading,
            onStartChanged: (date) {
              ref.read(inquiryProvider.notifier).selectRange(
                    date,
                    inquiry.endDate,
                  );
            },
            onEndChanged: (date) {
              ref.read(inquiryProvider.notifier).selectRange(
                    inquiry.startDate,
                    date,
                  );
            },
            onSearch: () => ref.read(inquiryProvider.notifier).search(),
          ),
          if (inquiry.errorMessage != null) ...[
            const SizedBox(height: 12),
            AppCard(
              child: Text(
                inquiry.errorMessage!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ),
          ],
          if (inquiry.summary != null) ...[
            const SizedBox(height: 24),
            SummarySection(
              summary: inquiry.summary!,
              onItemTap: (item) {
                if (inquiry.startDate == null || inquiry.endDate == null) {
                  return;
                }
                ref.read(activityDetailProvider.notifier).openFromSummaryItem(
                      item: item,
                      startDate: inquiry.startDate!,
                      endDate: inquiry.endDate!,
                    );
              },
            ),
          ],
        ],
      ),
    );
  }
}
