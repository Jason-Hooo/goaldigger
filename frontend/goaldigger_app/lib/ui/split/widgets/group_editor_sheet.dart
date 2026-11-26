import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/result/result.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/sheets.dart';
import '../view_models/split_view_model.dart';
import '../views/qr_scanner_screen.dart';

enum GroupEditorMode { create, join }

/// Create a new group or join one by invitation code.
///
/// Submits through [SplitViewModel]; closes itself and shows a confirmation on
/// success, and keeps the form open with an inline error on failure.
class GroupEditorSheet extends StatefulWidget {
  const GroupEditorSheet({super.key, this.initialMode = GroupEditorMode.create});

  static const int invitationCodeLength = 6;

  final GroupEditorMode initialMode;

  @override
  State<GroupEditorSheet> createState() => _GroupEditorSheetState();
}

class _GroupEditorSheetState extends State<GroupEditorSheet> {
  final _formKey = GlobalKey<FormState>();
  final _groupNameController = TextEditingController();
  final _invitationCodeController = TextEditingController();
  late GroupEditorMode _mode = widget.initialMode;
  bool _isSubmitting = false;
  String? _errorMessage;

  bool get _isCreate => _mode == GroupEditorMode.create;

  @override
  void dispose() {
    _groupNameController.dispose();
    _invitationCodeController.dispose();
    super.dispose();
  }

  void _setMode(GroupEditorMode mode) {
    setState(() {
      _mode = mode;
      _errorMessage = null;
    });
  }

  Future<void> _scan() async {
    final code = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
    );
    if (code == null || !mounted) {
      return;
    }
    _invitationCodeController.text = code.toUpperCase();
    await _submit();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    final viewModel = context.read<SplitViewModel>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final Result<void> result = _isCreate
        ? await viewModel.createGroup(_groupNameController.text.trim())
        : await viewModel.joinGroup(_invitationCodeController.text);
    if (!mounted) {
      return;
    }

    switch (result) {
      case Success():
        navigator.pop();
        messenger.showMessage(_isCreate ? '已建立群組' : '已加入群組');
      case Failure(:final message):
        setState(() {
          _isSubmitting = false;
          _errorMessage = message;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final errorMessage = _errorMessage;
    return SheetBody(
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SheetHeader(
              title: _isCreate ? '建立群組' : '加入群組',
              subtitle: _isCreate ? '建立一個新的群組並邀請成員' : '加入現有群組並邀請成員',
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              children: [
                ChoiceChip(
                  label: const Text('建立群組'),
                  selected: _isCreate,
                  onSelected: (_) => _setMode(GroupEditorMode.create),
                ),
                ChoiceChip(
                  label: const Text('加入群組'),
                  selected: !_isCreate,
                  onSelected: (_) => _setMode(GroupEditorMode.join),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (errorMessage != null) ...[
              InlineBanner(message: errorMessage),
              const SizedBox(height: 12),
            ],
            if (_isCreate)
              TextFormField(
                controller: _groupNameController,
                decoration: const InputDecoration(
                  labelText: '群組名稱',
                  hintText: '例如：京都旅行',
                ),
                maxLength: 20,
                validator: Validators.required('請輸入群組名稱'),
              )
            else ...[
              TextFormField(
                controller: _invitationCodeController,
                decoration: const InputDecoration(
                  labelText: '邀請碼',
                  hintText: '輸入要加入的群組邀請碼',
                ),
                textCapitalization: TextCapitalization.characters,
                validator: _validateInvitationCode,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _isSubmitting ? null : _scan,
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('掃描 QR Code'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.pinkPrimary,
                ),
              ),
            ],
            const SizedBox(height: 20),
            SheetActions(isBusy: _isSubmitting, onConfirm: _submit),
          ],
        ),
      ),
    );
  }

  String? _validateInvitationCode(String? value) {
    final code = (value ?? '').trim();
    if (code.isEmpty) {
      return '請輸入邀請碼';
    }
    if (code.length != GroupEditorSheet.invitationCodeLength) {
      return '邀請碼必須是 ${GroupEditorSheet.invitationCodeLength} 個字元';
    }
    return null;
  }
}
