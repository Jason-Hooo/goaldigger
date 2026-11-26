import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../core/theme/app_colors.dart';
import '../../../data/models/split.dart';

class _CloseButton extends StatelessWidget {
  const _CloseButton();

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () => Navigator.pop(context),
      style: ElevatedButton.styleFrom(
        minimumSize: const Size(double.infinity, 48),
      ),
      child: const Text('關閉'),
    );
  }
}

/// Invitation code rendered as text and QR code.
class InvitationQrSheet extends StatelessWidget {
  const InvitationQrSheet({super.key, required this.invitationCode});

  final String invitationCode;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '群組邀請碼',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.pinkPrimary),
            ),
            child: Column(
              children: [
                Text(
                  invitationCode,
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 4,
                  ),
                ),
                const SizedBox(height: 16),
                QrImageView(
                  data: invitationCode,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _CloseButton(),
        ],
      ),
    );
  }
}

class MembersSheet extends StatelessWidget {
  const MembersSheet({super.key, required this.members});

  final List<GroupMember> members;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '群組成員',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${members.length} 人',
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (members.isEmpty)
            const Center(
              child: Text('暫無成員', style: TextStyle(color: Colors.grey)),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: members.length,
                itemBuilder: (context, index) {
                  final member = members[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.pinkPrimary,
                      child: Text(
                        member.initial,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(member.userName),
                    subtitle: Text('ID: ${member.userId}'),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
          const _CloseButton(),
        ],
      ),
    );
  }
}
