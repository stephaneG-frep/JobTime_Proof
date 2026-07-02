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
            title: '1. Déclarer une session',
            icon: Icons.play_circle_outline,
            bullets: const [
              'Allez dans l\'onglet Session.',
              'Choisissez une plateforme et un type d\'action.',
              'Indiquez Candidature Oui/Non si vous savez déjà que la session contient une candidature.',
              'Utilisez Ouverture rapide pour ouvrir la plateforme si besoin.',
              'Estimez le temps passé par tranches de 10 minutes.',
            ],
          ),
          _HelpSection(
            title: '2. Notes et sauvegarde',
            icon: Icons.pause_circle_outline,
            bullets: const [
              'Ajoutez des notes pour garder le contexte.',
              'Ajoutez éventuellement les URLs consultées.',
              'Les liens ajoutés à la session deviennent des preuves URL sauvegardées.',
              'Sauvegarder la session l’ajoute directement à l’historique.',
            ],
          ),
          _HelpSection(
            title: '3. Ajouter des preuves',
            icon: Icons.verified_outlined,
            bullets: const [
              'Depuis Historique, ouvrez une session.',
              'Ajoutez une preuve: image (caméra/galerie), PDF, URL ou note.',
              'Touchez une preuve pour l\'ouvrir: image en aperçu, PDF via app externe, URL dans navigateur.',
              'Sur chaque preuve URL, utilisez le bouton coche pour marquer postulé/non postulé.',
              'Chaque preuve est horodatée et conservée en local.',
            ],
          ),
          _HelpSection(
            title: '4. Consulter l\'historique',
            icon: Icons.history,
            bullets: const [
              'Filtrez par plateforme, type d\'action et date.',
              'Activez le filtre Sans preuve pour repérer les sessions à compléter.',
              'Utilisez la recherche mot-clé pour retrouver rapidement une session.',
              'Dans le détail, utilisez J\'ai postulé (Oui/Non) pour qualifier la session.',
              'Les sessions sans preuve sont signalées avec une icône d\'alerte.',
              'Vous pouvez supprimer une session depuis son détail.',
            ],
          ),
          _HelpSection(
            title: '5. Générer un rapport PDF',
            icon: Icons.picture_as_pdf_outlined,
            bullets: const [
              'Ouvrez l\'onglet Rapport.',
              'Sélectionnez une période.',
              'Vérifiez les stats (temps, sessions, candidatures) puis générez le PDF.',
              'Le PDF inclut toutes les preuves: images, PDF, liens (avec QR), notes.',
              'Les URLs marquées postulé apparaissent en vert dans le PDF.',
              'Utilisez aussi Rapport prêt à présenter pour une version synthétique (plus courte).',
              'Utilisez Export ZIP complet pour récupérer le JSON et les fichiers de preuve.',
            ],
          ),
          _HelpSection(
            title: '6. Paramètres utiles',
            icon: Icons.settings_outlined,
            bullets: const [
              'Définissez votre objectif hebdomadaire en heures.',
              'Activez le thème sombre si besoin.',
              'Ajoutez des plateformes personnalisées.',
              'Configurez la plateforme Autre (schéma app + URL web).',
              'Configurez l\'IA: clé API OpenAI + modèle (gpt-4.1-mini, gpt-4.1, gpt-4o-mini).',
              'Exportez/Importez vos données JSON.',
              'Exportez un ZIP complet pour sauvegarder aussi les fichiers de preuves.',
              'Utilisez Réparer les données locales pour nettoyer les plateformes en doublon.',
              'Une sauvegarde JSON automatique est lancée une fois par jour au démarrage.',
            ],
          ),
          _HelpSection(
            title: '7. Assistant IA',
            icon: Icons.auto_awesome,
            bullets: const [
              'Ouvrez Paramètres > Ouvrir Assistant IA.',
              'Collez une annonce, des notes ou un texte libre.',
              'L\'IA génère un résumé pro et une suggestion postulé oui/non.',
              'Utilisez Copier pour réutiliser le texte dans vos notes ou preuves.',
            ],
          ),
          _HelpSection(
            title: '8. Partage de lien',
            icon: Icons.share_outlined,
            bullets: const [
              'Depuis une annonce, utilisez Partager vers JobTime Proof.',
              'Le lien apparaît dans Session (Lien partagé reçu).',
              'Vous pouvez aussi coller manuellement un lien dans Session.',
              'Ajoutez le lien à la dernière session en un clic.',
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
                  Text(
                    '• Si une durée ne convient pas, ajustez-la par tranches de 10 minutes.',
                  ),
                  Text(
                    '• Si un lien partagé n\'apparaît pas, utilisez l\'ajout manuel dans Session.',
                  ),
                  Text(
                    '• Si une plateforme apparaît en doublon, utilisez Paramètres > Réparer les données locales.',
                  ),
                  Text(
                    '• Si une session affiche une alerte, ajoutez une preuve ou vérifiez qu\'elle est volontairement sans preuve.',
                  ),
                  Text(
                    '• Si l\'IA échoue, vérifiez la clé API et le modèle choisis.',
                  ),
                  Text(
                    '• Vérifiez régulièrement les exports JSON ou ZIP dans le stockage de l\'app.',
                  ),
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
