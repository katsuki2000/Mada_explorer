# Mada Explorer 🦎

Application Flutter connectée à un vrai backend (Node/Express), sur le thème
de **Madagascar** : découverte des parcs nationaux et de la faune endémique
(lémuriens, fossa, aye-aye...).

Projet réalisé pour valider les compétences API / architecture / persistence
sur une app full-stack.

## Sommaire

- [Aperçu fonctionnel](#aperçu-fonctionnel)
- [Architecture](#architecture)
- [API utilisée](#api-utilisée)
- [Configuration & lancement](#configuration--lancement)
- [Tests unitaires](#tests-unitaires)
- [Structure du projet](#structure-du-projet)

## Aperçu fonctionnel

- **Authentification** : inscription / connexion / déconnexion par JWT
  (access token 15 min + refresh token 7 jours, avec rotation).
- **3 écrans connectés à l'API** :
  1. **Parcs nationaux** (liste + détail avec les espèces observables)
  2. **Faune endémique** (liste avec statut de conservation)
  3. **Profil** (infos utilisateur + déconnexion)
- **Cache local** avec Hive pour les parcs, les espèces et le profil.
- **Mode hors ligne** : si le réseau est indisponible, les données en cache
  sont affichées avec un bandeau "Mode hors ligne".
- **Gestion des erreurs réseau** : messages utilisateur clairs (timeout,
  serveur injoignable, identifiants invalides...) au lieu d'exceptions brutes.
- **Thème visuel malgache** : couleurs baobab / terre de latérite / vert
  forêt tropicale, inspirées de l'Avenue des Baobabs et des parcs du pays.

## Architecture

**Clean Architecture, feature-first**, avec 3 couches par fonctionnalité :

```
lib/
  core/                      # transverse à toute l'app
    constants/               # URLs de l'API
    network/                 # DioClient, AuthInterceptor, NetworkInfo, TokenStorage
    error/                   # Failure (domaine) / Exception (data)
    usecases/                # UseCase<Type, Params> de base
    theme/                   # thème "Madagascar"
    di/                      # injection_container.dart (GetIt)
  features/
    auth/
      data/                  # models, datasources (remote Dio + local Hive), repository impl
      domain/                # entities, repository interface, usecases
      presentation/          # Cubit + écrans Login/Register
    parks/                   # même structure : Park, ParksRepository, ParksCubit, écrans liste/détail
    species/                 # même structure : Species, SpeciesRepository, SpeciesCubit, écran liste
    profile/
      presentation/          # écran Profil (lit AuthCubit)
  shared/widgets/            # OfflineBanner, etc.
  app.dart                   # MultiBlocProvider + routage racine + shell à onglets
  main.dart                  # init Hive + DI + runApp
```

**Flux de dépendance** (règle stricte de Clean Architecture) :

```
presentation  →  domain  ←  data
   (Cubit)      (usecases,      (repository impl,
                 entities,       datasources,
                 repository       models)
                 interface)
```

- Le **domain** ne connaît ni Dio, ni Hive, ni Flutter : il ne dépend que de
  Dart pur (`Either<Failure, T>` via `dartz`).
- Le **repository pattern** est le seul point de contact entre `domain` et
  `data`. Chaque repository :
  1. vérifie la connectivité (`NetworkInfo`),
  2. appelle le datasource distant (Dio) si en ligne,
  3. met en cache la réponse (Hive) en cas de succès,
  4. **retombe sur le cache** en cas d'échec réseau ou d'absence de connexion.
- La **présentation** utilise `flutter_bloc` (Cubit) : chaque écran a son
  Cubit, alimenté par un usecase, injecté via **GetIt** (`core/di/injection_container.dart`).

### Authentification & intercepteur

- `AuthInterceptor` (Dio `QueuedInterceptor`) injecte automatiquement
  `Authorization: Bearer <accessToken>` sur chaque requête.
- Si une requête échoue en 401, l'intercepteur appelle `/auth/refresh`
  **une seule fois** (grâce à `QueuedInterceptor`, qui met en file les autres
  requêtes en attente pendant le refresh), rejoue la requête originale avec
  le nouveau token, et si le refresh échoue lui-même, déclenche une
  déconnexion forcée (`AuthCubit.forceLogout()`).
- Les tokens sont stockés dans `flutter_secure_storage` (jamais dans Hive,
  qui sert uniquement au cache de contenu, pas aux secrets).

### Mode hors ligne

Chaque repository de données (`ParksRepositoryImpl`, `SpeciesRepositoryImpl`)
suit le même principe "offline-first" :

1. Si connecté → requête réseau → mise en cache Hive → retour des données.
2. Si la requête réseau échoue (serveur down, timeout...) → tentative de
   lecture du cache Hive avant d'échouer.
3. Si pas de connexion du tout → lecture directe du cache Hive.
4. Si le cache est vide → `Failure` explicite affichée à l'utilisateur
   ("Connectez-vous à internet au moins une fois").

Le Cubit expose un flag `isOffline` dans son état, ce qui permet à l'UI
d'afficher le bandeau `OfflineBanner` sans complexifier le repository.

## API utilisée

Ce projet utilise **son propre backend** (`/backend`), car aucune API
publique ne couvre les parcs nationaux et la faune de Madagascar. C'est un
serveur Express minimaliste mais réel :

| Méthode | Route            | Description                                   | Protégée |
|---------|------------------|------------------------------------------------|----------|
| POST    | `/auth/register` | Créer un compte, retourne `user` + tokens       | non      |
| POST    | `/auth/login`    | Se connecter, retourne `user` + tokens          | non      |
| POST    | `/auth/refresh`  | Échange un refresh token contre une nouvelle paire | non   |
| POST    | `/auth/logout`   | Invalide le refresh token côté serveur          | non      |
| GET     | `/profile`       | Profil de l'utilisateur connecté                | oui      |
| GET     | `/parks`         | Liste des parcs nationaux malgaches             | oui      |
| GET     | `/parks/:id`     | Détail d'un parc                                | oui      |
| GET     | `/species`       | Liste des espèces endémiques                    | oui      |
| GET     | `/species/:id`   | Détail d'une espèce                             | oui      |

Données de démonstration incluses : 6 parcs nationaux (Ranomafana,
Andasibe-Mantadia, Isalo, Tsingy de Bemaraha, Masoala, Montagne d'Ambre) et
6 espèces endémiques (Indri, Aye-aye, *Lemur catta*, Sifaka, Fossa, microcèbe).

> Le backend stocke les utilisateurs **en mémoire** (redémarrage = comptes
> perdus) : c'est volontaire, pour rester simple à lancer en local sans base
> de données externe. Pour un vrai déploiement, remplacer le tableau `users`
> par une vraie base (Postgres, SQLite, MongoDB...).

## Configuration & lancement

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env   # optionnel : personnaliser les secrets JWT
npm start               # démarre sur http://localhost:3000
```

Vérifier que ça tourne : `curl http://localhost:3000/health` → `{"status":"ok"}`

### 2. Application Flutter

```bash
cd flutter_app
flutter pub get
flutter run
```

Configurer l'URL du backend dans
`lib/core/constants/api_constants.dart` :

- **Émulateur Android** : `http://10.0.2.2:3000` (déjà configuré par défaut)
- **Simulateur iOS / desktop / web** : `http://localhost:3000`
- **Appareil physique** : `http://<IP_LAN_de_votre_machine>:3000`

### 3. Utilisation

1. Créer un compte depuis l'écran d'inscription.
2. Parcourir les parcs nationaux et la faune endémique.
3. Couper le Wi-Fi / les données mobiles : les écrans continuent d'afficher
   les données déjà chargées, avec le bandeau "Mode hors ligne".
4. Se déconnecter depuis l'onglet Profil.

## Tests unitaires

3 suites de tests sur la couche repository, avec **Mocktail** :

```bash
cd flutter_app
flutter test
```

- `test/features/auth/data/repositories/auth_repository_impl_test.dart`
  Connexion réussie (tokens persistés + user mis en cache), identifiants
  invalides (`AuthFailure`), absence de réseau (`NetworkFailure` sans appel API).
- `test/features/parks/data/repositories/parks_repository_impl_test.dart`
  Récupération en ligne (+ mise en cache), lecture du cache hors ligne,
  échec propre quand hors ligne ET cache vide.
- `test/features/species/data/repositories/species_repository_impl_test.dart`
  Priorité au réseau, repli sur le cache si le serveur échoue, échec avec le
  message d'origine si serveur ET cache échouent tous les deux.

## Structure du projet

```
Real_backend_app/
├── backend/                # API Node/Express (JWT + Madagascar data)
│   ├── data/                 parks.json, species.json
│   ├── server.js
│   └── package.json
└── flutter_app/             # App Flutter (Clean Architecture, feature-first)
    ├── lib/
    │   ├── core/
    │   ├── features/
    │   │   ├── auth/
    │   │   ├── parks/
    │   │   ├── species/
    │   │   └── profile/
    │   ├── shared/
    │   ├── app.dart
    │   └── main.dart
    ├── test/
    └── pubspec.yaml
```

## Pistes d'amélioration

- Passer le backend sur une vraie base de données (persistance des comptes).
- Ajouter la pagination côté `/parks` et `/species`.
- Ajouter des tests de widgets sur les Cubits (`bloc_test`) et des tests
  d'intégration sur l'`AuthInterceptor` (refresh token).
- Générer les TypeAdapters Hive (`hive_generator`) si le modèle de données
  se complexifie au-delà de simples `Map`/`List` JSON-safe.
