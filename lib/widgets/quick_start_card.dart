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
    final scheme = Theme.of(context).colorScheme;
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.rocket_launch, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Widget Démarrage Rapide',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text('Plateforme sélectionnée: $platform'),
            const SizedBox(height: 4),
            const Text(
              'Ouvre la plateforme et démarre automatiquement le chrono.',
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(46),
              ),
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
