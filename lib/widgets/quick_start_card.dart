import 'package:flutter/material.dart';

class QuickStartCard extends StatelessWidget {
  const QuickStartCard({
    super.key,
    required this.platform,
    required this.onPressed,
    required this.enabled,
  });

  final String platform;
  final VoidCallback? onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.rocket_launch,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Démarrage rapide',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('Plateforme sélectionnée: $platform'),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: enabled ? onPressed : null,
              icon: const Icon(Icons.open_in_new),
              label: Text(
                enabled
                    ? 'Lancer recherche (ouvrir + chrono)'
                    : 'Configurer une URL pour cette plateforme',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
