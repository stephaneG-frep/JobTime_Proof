# JobTime Proof

Application Flutter personnelle (Android) pour suivre le temps passé à chercher un emploi et conserver des preuves d'activité. Tout est stocké en local, sans compte ni serveur.

## Fonctionnalités

- **Session** : plateforme, type d'action, temps estimé par tranches de 10 min, notes, liens consultés (cochables « postulé »).
- **Partage Android** : « Partager → JobTime Proof » depuis une annonce ajoute le lien à la session en cours.
- **Preuves** : image (caméra/galerie), PDF, URL (avec QR) ou note, rattachées à une session.
- **Historique** : filtres plateforme, action, date, mot-clé et « sans preuve ».
- **Rapports PDF** : rapport détaillé (preuves, QR, images) et rapport de présentation synthétique.
- **Données** : export JSON ou ZIP (JSON + fichiers de preuve) via le partage Android, import JSON, sauvegarde automatique quotidienne (7 dernières conservées).
- **Assistant IA** (optionnel) : OpenAI, Gemini ou Mistral avec votre propre clé API, stockée dans le stockage sécurisé du système.

## Développement

```bash
flutter pub get
flutter analyze
flutter test
flutter build apk --release
```

## Structure

| Dossier | Contenu |
| --- | --- |
| `lib/models` | Modèles (`JobSession`, `JobProof`, `AppSettings`) et adaptateurs Hive écrits à la main |
| `lib/providers` | État de l'app (`SessionProvider`, `SettingsProvider`) |
| `lib/services` | Hive, fichiers et exports, PDF, IA, stockage sécurisé, sauvegarde auto |
| `lib/screens`, `lib/widgets` | Interface |
| `android/.../MainActivity.kt` | Réception des liens partagés (canal `jobtime_proof/share`) |
| `assets/fonts` | DejaVu Sans, intégrée aux PDF (licence dans `DejaVu-LICENSE.txt`) |

## Points d'attention

- **Adaptateurs Hive** : les numéros de champ sont le format de stockage. Ne jamais réutiliser ni renuméroter un champ existant ; ajouter les nouveaux champs à la suite avec une valeur par défaut à la lecture. `test/hive_adapters_test.dart` vérifie l'aller-retour écriture/lecture.
- Si une box Hive est illisible au démarrage, une copie `*_corrupt_*.hive` est conservée dans le dossier documents de l'app avant sa réinitialisation.
