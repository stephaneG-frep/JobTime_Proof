# JobTime Proof - Checklist v1.0 Stable

## Build
- [ ] `flutter pub get`
- [ ] `flutter analyze` (0 error)
- [ ] `flutter test`
- [ ] `flutter build apk --release`

## Démarrage
- [ ] L'app démarre sans blocage (logo Flutter)
- [ ] Le thème clair/sombre fonctionne
- [ ] Le format date est bien en `dd/MM/yyyy`

## Persistance (après fermeture complète de l'app)
- [ ] Les sessions gardent plateforme, durée, notes et preuves
- [ ] Les réglages sont conservés (thème, objectif, plateformes, IA)
- [ ] Des notes saisies dans Session restent après un changement d'onglet

## Session
- [ ] `Ouverture rapide` ouvre l'app de la plateforme, sinon le site web
- [ ] Le temps estimé se règle par tranches de 10 min
- [ ] Ajout manuel d'un lien et case « postulé » fonctionnent
- [ ] `Sauvegarder la session` l'ajoute à l'historique

## Preuves
- [ ] Ajout image (caméra et galerie) fonctionne
- [ ] Import PDF fonctionne
- [ ] Ajout URL fonctionne
- [ ] QR visible pour preuve URL
- [ ] Décocher la dernière preuve « postulé » met à jour la session

## Historique
- [ ] Filtres plateforme / action / date fonctionnent (dernier jour inclus)
- [ ] Recherche mot-clé fonctionne
- [ ] Détail session affiché correctement
- [ ] Suppression d'une session demande confirmation

## Rapport
- [ ] Période sélectionnable (une période d'un seul jour fonctionne)
- [ ] Stats (temps, sessions, candidatures) cohérentes avec le PDF
- [ ] PDF généré proprement (accents, `•`, `’`, `€` lisibles)
- [ ] Images et QR URL présents dans le PDF

## Données
- [ ] Export JSON et ZIP ouvrent le partage Android
- [ ] Le ZIP s'ouvre et contient le JSON et les fichiers de preuve
- [ ] Import JSON : confirmation, puis données remplacées
- [ ] Import d'un fichier invalide : message d'erreur, données intactes
- [ ] Suppression complète efface sessions, preuves, réglages et clés API

## Partage Android
- [ ] Depuis navigateur/LinkedIn: `Partager` vers `JobTime Proof`
- [ ] Lien partagé détecté dans Session et dans le détail session
- [ ] `Ajouter en preuve URL` fonctionne

## APK final
- [ ] APK installé sur Pixel
- [ ] Version affichée: `1.0.0+2`
