import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/ledger_entry.dart';

enum LedgerDetailAction { edit, duplicate, delete }

/// Read-only details of a ledger entry. Pops with the chosen
/// [LedgerDetailAction], or `null` when dismissed.
class LedgerDetailSheet extends StatelessWidget {
  const LedgerDetailSheet({super.key, required this.entry});

  final LedgerEntry entry;

  @override
  Widget build(BuildContext context) {
    void pop(LedgerDetailAction action) => Navigator.pop(context, action);

    return SheetBody(
      scrollable: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(entry.title, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            entry.subtitle,
            style: const TextStyle(color: AppColors.inkLight),
          ),
          const SizedBox(height: 18),
          DetailRow(label: '類型', value: entry.typeLabel),
          DetailRow(label: '金額', value: entry.amountLabel),
          DetailRow(label: '分類', value: entry.categoryName),
          DetailRow(label: '時間', value: entry.recordedAtLabel),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => pop(LedgerDetailAction.edit),
                  child: const Text('編輯'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => pop(LedgerDetailAction.duplicate),
                  child: const Text('複製新增'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => pop(LedgerDetailAction.delete),
                  child: const Text('刪除'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
