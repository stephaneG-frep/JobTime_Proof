import 'package:flutter/material.dart';

class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mode d\'emploi')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'JobTime Proof',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Application locale pour suivre votre temps de recherche d\'emploi et conserver des preuves d\'activité.',
          ),
          const SizedBox(height: 16),
          _HelpSection(
            title: '1. Démarrer une session',
            icon: Icons.play_circle_outline,
            bullets: const [
              'Allez dans l\'onglet Session.',
              'Choisissez une plateforme et un type d\'action.',
              'Utilisez Ouvrir la plateforme pour lancer app/site puis démarrer automatiquement le chrono.',
              'Vous pouvez aussi cliquer Démarrer manuellement.',
            ],
          ),
          _HelpSection(
            title: '2. Pause et fin',
            icon: Icons.pause_circle_outline,
            bullets: const [
              'Pause stoppe temporairement le chrono.',
              'Terminer sauvegarde automatiquement la session.',
              'Ajoutez des notes avant de terminer pour garder le contexte.',
            ],
          ),
          _HelpSection(
            title: '3. Ajouter des preuves',
            icon: Icons.verified_outlined,
            bullets: const [
              'Depuis Historique, ouvrez une session.',
              'Ajoutez une preuve: image, PDF, URL ou note.',
              'Chaque preuve est horodatée et conservée en local.',
            ],
          ),
          _HelpSection(
            title: '4. Consulter l\'historique',
            icon: Icons.history,
            bullets: const [
              'Filtrez par plateforme, type d\'action et date.',
              'Utilisez la recherche mot-clé pour retrouver rapidement une session.',
              'Vous pouvez supprimer une session depuis son détail.',
            ],
          ),
          _HelpSection(
            title: '5. Générer un rapport PDF',
            icon: Icons.picture_as_pdf_outlined,
            bullets: const [
              'Ouvrez l\'onglet Rapport.',
              'Sélectionnez une période.',
              'Générez le PDF avec temps total, sessions et preuves.',
            ],
          ),
          _HelpSection(
            title: '6. Paramètres utiles',
            icon: Icons.settings_outlined,
            bullets: const [
              'Définissez votre objectif hebdomadaire en heures.',
              'Ajoutez des plateformes personnalisées.',
              'Configurez la plateforme Autre (schéma app + URL web).',
              'Exportez/Importez vos données JSON.',
            ],
          ),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Dépannage rapide',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 6),
                  Text(
                    '• Si une app ne s\'ouvre pas: vérifiez qu\'elle est installée.',
                  ),
                  Text('• Sinon le fallback web s\'ouvre automatiquement.'),
                  Text('• Si le chrono ne tourne pas, relancez une session.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({
    required this.title,
    required this.icon,
    required this.bullets,
  });

  final String title;
  final IconData icon;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...bullets.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• $line'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
