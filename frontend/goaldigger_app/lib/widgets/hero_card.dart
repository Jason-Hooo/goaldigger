part of '../main.dart';

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onPressed,
  });

  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.savings_rounded, color: AppColors.pinkPrimary),
                SizedBox(width: 8),
                Text('小豬閃亮模式'),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: Theme.of(
                context,
              ).textTheme.bodyLarge?.copyWith(color: AppColors.inkLight),
            ),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: onPressed, child: Text(actionText)),
          ],
        ),
      ),
    );
  }
}
