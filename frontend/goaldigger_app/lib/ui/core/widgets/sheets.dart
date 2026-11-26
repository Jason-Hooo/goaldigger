import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Opens a scroll-controlled bottom sheet with a drag handle.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool showDragHandle = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    showDragHandle: showDragHandle,
    builder: builder,
  );
}

/// Standard padding for bottom sheet content that respects the keyboard.
class SheetBody extends StatelessWidget {
  const SheetBody({super.key, required this.child, this.scrollable = true});

  final Widget child;
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        20 + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: scrollable ? SingleChildScrollView(child: child) : child,
    );
  }
}

/// Title + muted subtitle header used at the top of form sheets.
class SheetHeader extends StatelessWidget {
  const SheetHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: textTheme.bodyMedium?.copyWith(color: AppColors.inkLight),
        ),
      ],
    );
  }
}

/// Cancel / confirm button pair used at the bottom of form sheets.
class SheetActions extends StatelessWidget {
  const SheetActions({
    super.key,
    required this.onConfirm,
    this.confirmLabel = '儲存',
    this.cancelLabel = '取消',
    this.isBusy = false,
  });

  final VoidCallback onConfirm;
  final String confirmLabel;
  final String cancelLabel;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isBusy ? null : () => Navigator.pop(context),
            child: Text(cancelLabel),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: isBusy ? null : onConfirm,
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}

/// Shows a two-button confirmation dialog and resolves to `true` on confirm.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = '確認',
  String cancelLabel = '取消',
  bool destructive = false,
}) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: Text(cancelLabel),
        ),
        if (destructive)
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(confirmLabel),
          )
        else
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
      ],
    ),
  );
  return confirmed ?? false;
}

extension ScaffoldMessengerX on ScaffoldMessengerState {
  /// Replaces any visible snack bar with [message].
  void showMessage(String message, {Duration? duration}) {
    this
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          duration: duration ?? const Duration(milliseconds: 4000),
        ),
      );
  }
}
