# Mada Explorer 🦎

[![CI](https://github.com/katsuki2000/Mada_explorer/actions/workflows/ci.yml/badge.svg)](https://github.com/katsuki2000/Mada_explorer/actions/workflows/ci.yml)

Application Flutter connectée à un vrai backend (Node/Express), sur le thème
de **Madagascar** : découverte des parcs nationaux et de la faune endémique
(lémuriens, fossa, aye-aye...).

Projet réalisé pour valider les compétences API / architecture / persistence
sur une app full-stack.

## Sommaire

- [Aperçu fonctionnel](#aperçu-fonctionnel)
- [Architecture](#architecture)
- [Pourquoi ces choix d'architecture](#pourquoi-ces-choix-darchitecture)
- [API utilisée](#api-utilisée)
- [Configuration & lancement](#configuration--lancement)
- [Tests unitaires](#tests-unitaires)
- [Intégration continue](#intégration-continue)
- [Dépannage](#dépannage)
- [Structure du projet](#structure-du-projet)
- [Pistes d'amélioration](#pistes-damélioration)

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
- Le client Dio utilisé en interne par l'intercepteur (pour l'appel de
  refresh et le replay de la requête d'origine) est injectable via le
  constructeur (`plainDio`). En production, `main.dart` ne fournit rien et
  un `Dio` réel pointant vers l'API est créé par défaut ; en test, on injecte
  un `Dio` mocké (Mocktail) pour simuler succès/échec du refresh sans réseau.

### Session au démarrage (`getCurrentUser`) et déconnexion

- Au lancement, `AuthCubit.restoreSession()` appelle
  `AuthRepository.getCurrentUser()` : si l'appareil est en ligne, le profil
  est re-téléchargé (`GET /profile`) et le cache est rafraîchi ; sinon (ou si
  l'appel échoue), le profil est lu depuis le cache Hive (`auth_box`). Si
  aucune session n'a jamais été mise en cache, une `CacheFailure` explicite
  est renvoyée et l'utilisateur atterrit sur l'écran de connexion.
- `AuthRepository.logout()` appelle `POST /auth/logout` pour invalider le
  refresh token côté serveur, **puis** nettoie systématiquement la session
  locale (`TokenStorage.clear()` + `AuthLocalDataSource.clearUser()`),
  y compris si l'appel réseau échoue ou s'il n'y avait pas de refresh token
  stocké : l'utilisateur ne reste jamais bloqué "connecté localement" à
  cause d'un serveur injoignable.

### Modèle d'erreurs : `Exception` (data) → `Failure` (domain)

| Exception (levée par les datasources) | Failure (renvoyée par le repository) | Cause typique                                    |
|----------------------------------------|----------------------------------------|---------------------------------------------------|
| `AuthException`                       | `AuthFailure`                          | Identifiants invalides, email déjà utilisé (401/409) |
| `ServerException`                     | `ServerFailure`                        | Erreur HTTP 5xx, timeout, réponse inattendue        |
| `CacheException`                      | `CacheFailure`                         | Box Hive vide, donnée corrompue, écriture échouée   |
| *(aucune connectivité détectée)*      | `NetworkFailure`                       | `NetworkInfo.isConnected == false`                  |
| *(tout le reste)*                     | `UnexpectedFailure`                    | Filet de sécurité générique                         |

Les datasources locales (`AuthLocalDataSource`, `ParksLocalDataSource`,
`SpeciesLocalDataSource`) encapsulent systématiquement leurs opérations Hive
(`put`, `get`, `delete`, désérialisation JSON) dans des `try/catch` qui
retraduisent toute erreur bas niveau en `CacheException`, afin que le
repository n'ait jamais à gérer une exception Hive brute.

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

## Pourquoi ces choix d'architecture

- **Feature-first plutôt que layer-first global** : chaque fonctionnalité
  (`auth`, `parks`, `species`, `profile`) est un dossier autonome avec ses
  propres `data/domain/presentation`. Cela évite d'avoir un unique dossier
  `models/` ou `repositories/` fourre-tout à la racine de `lib/`, et permet
  d'ajouter ou de retirer une fonctionnalité sans toucher au reste de l'app.
  Le `core/` reste volontairement réduit à ce qui est *vraiment* transverse
  (réseau, erreurs, thème, DI) — pas à de la logique métier.
- **`Either<Failure, T>` (dartz) plutôt que des exceptions qui remontent
  jusqu'à l'UI** : la couche `domain` ne peut jamais planter silencieusement
  ni forcer la présentation à écrire des `try/catch` partout. Chaque usecase
  retourne explicitement soit un succès, soit un échec typé, que le Cubit
  transforme en état (`SpeciesError(message)`, etc.).
- **Repository comme unique frontière data ↔ domain** : la présentation et
  le domaine ne savent pas que Dio ou Hive existent. On pourrait remplacer
  Hive par Isar ou SQLite, ou Dio par `http`, en ne touchant qu'à la couche
  `data`, sans toucher aux Cubits ni aux écrans.
- **GetIt (service locator) plutôt qu'un `Provider` d'injection manuel** :
  plus simple à câbler pour un projet de cette taille, et les tests peuvent
  quand même bypasser complètement GetIt en instanciant les classes à la
  main avec des mocks Mocktail (voir la section Tests).
- **Tokens hors de Hive** : Hive est un cache de *contenu*, pas un coffre-fort.
  Les secrets (access/refresh token) vivent dans `flutter_secure_storage`,
  qui chiffre au niveau du Keystore (Android) / Keychain (iOS), pour qu'un
  accès au fichier `.hive` seul ne suffise pas à voler une session.

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

4 suites de tests sur la couche repository et le réseau, avec **Mocktail**
(22 tests au total) :

```bash
cd flutter_app
flutter test
```

- `test/features/auth/data/repositories/auth_repository_impl_test.dart` (10 tests)
  - `login` : connexion réussie (tokens persistés + user mis en cache),
    identifiants invalides (`AuthFailure`), absence de réseau
    (`NetworkFailure` sans appel API).
  - `logout` : nettoyage local après un appel serveur réussi, nettoyage
    local même sans refresh token stocké, nettoyage local même si l'appel
    serveur échoue (logout ne doit jamais laisser une session "fantôme").
  - `getCurrentUser` : profil rafraîchi depuis l'API quand en ligne, repli
    sur le cache quand l'appel API échoue, lecture directe du cache hors
    ligne, `CacheFailure` explicite si hors ligne et jamais de session en
    cache.
- `test/core/network/auth_interceptor_test.dart` (6 tests)
  Injection du header `Authorization`, refresh du token puis rejeu de la
  requête d'origine sur un 401, déconnexion forcée si le refresh échoue,
  déconnexion forcée immédiate si aucun refresh token n'est disponible,
  aucune tentative de refresh sur une erreur non-401, pas de double retry.
- `test/features/parks/data/repositories/parks_repository_impl_test.dart` (3 tests)
  Récupération en ligne (+ mise en cache), lecture du cache hors ligne,
  échec propre quand hors ligne ET cache vide.
- `test/features/species/data/repositories/species_repository_impl_test.dart` (3 tests)
  Priorité au réseau, repli sur le cache si le serveur échoue, échec avec le
  message d'origine si serveur ET cache échouent tous les deux.

Le test de l'intercepteur mocke directement le `Dio` interne
(`AuthInterceptor(plainDio: mockDio, ...)`) plutôt que de faire de vrais
appels HTTP, ce qui le rend rapide et déterministe (pas de backend requis
pour lancer `flutter test`).

## Intégration continue

Un workflow GitHub Actions (`.github/workflows/ci.yml`) tourne sur chaque
push et pull request vers `main` :

- **Job `flutter`** : `flutter pub get`, `flutter analyze`,
  `dart format --set-exit-if-changed .`, puis `flutter test`.
- **Job `backend`** : `npm ci`, démarre `server.js`, et vérifie que
  `GET /health` répond avant de couper le serveur.

Les deux jobs tournent en parallèle sur `ubuntu-latest`. Le badge en haut de
ce README reflète l'état du dernier run sur `main`.

## Dépannage

- **`flutter run` reste bloqué / l'app affiche une erreur réseau
  immédiatement** : le backend n'est probablement pas démarré, ou l'URL dans
  `api_constants.dart` ne correspond pas à votre cible (`10.0.2.2` pour
  l'émulateur Android, `localhost` pour desktop/iOS, IP LAN pour un appareil
  physique — voir la section Configuration).
- **`Bad state: Box has already been closed` ou erreur Hive au démarrage** :
  Hive doit être initialisé (`Hive.initFlutter()`) et les box ouvertes
  (`Hive.openBox(...)`) **avant** `runApp()` dans `main.dart`. Si vous avez
  ajouté un nouveau champ à un modèle sans régénérer les adapters, videz les
  box de dev : désinstallez l'app du simulateur/émulateur pour repartir
  d'un stockage local propre.
- **`flutter pub get` échoue avec un conflit de versions** : vérifiez la
  version de Flutter/Dart (`flutter --version`) — ce projet cible Flutter
  stable récent (Dart ≥ 3.3). Un `flutter upgrade` résout la plupart des
  incompatibilités de contraintes SDK.
- **Le backend démarre mais `curl http://localhost:3000/health` échoue** :
  un autre processus occupe déjà le port 3000. Changez le port dans
  `backend/server.js` (ou `.env`) et mettez à jour `api_constants.dart` en
  conséquence, ou tuez le processus existant (`lsof -i :3000` sur macOS/Linux).
- **401 en boucle malgré un compte valide** : le backend garde les comptes
  **en mémoire** — s'il a redémarré depuis votre inscription, le compte
  n'existe plus côté serveur. Recréez un compte via `/auth/register`.
- **Les tests échouent avec `Bad state: No host specified in URI` ou
  similaire dans `auth_interceptor_test.dart`** : ce test n'appelle jamais
  le vrai réseau — si Mocktail signale un appel non stubé, c'est
  probablement qu'un nouveau chemin de code appelle une méthode du `Dio`
  mocké qui n'a pas encore de `when(...)` correspondant ; ajoutez le stub
  manquant plutôt que de retirer l'assertion.
- **`dart format --set-exit-if-changed .` échoue en CI mais pas en local** :
  lancez `dart format .` (sans `--output=none`) en local avant de commit
  pour appliquer le même style que la CI, puis relancez `flutter analyze`
  pour vérifier qu'aucun lint (ex. `curly_braces_in_flow_control_structures`)
  n'apparaît après le reformatage.

## Structure du projet

```
Real_backend_app/
├── .github/workflows/ci.yml  # pipeline CI (analyze + format + tests + backend smoke test)
├── backend/                  # API Node/Express (JWT + Madagascar data)
│   ├── data/                   parks.json, species.json
│   ├── server.js
│   └── package.json
└── flutter_app/               # App Flutter (Clean Architecture, feature-first)
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
    │   ├── core/network/                    # AuthInterceptor
    │   └── features/{auth,parks,species}/    # Repositories
    └── pubspec.yaml
```

## Pistes d'amélioration

- Passer le backend sur une vraie base de données (persistance des comptes).
- Ajouter la pagination côté `/parks` et `/species`.
- Ajouter des tests de widgets sur les Cubits (`bloc_test`), notamment pour
  vérifier que le bandeau `OfflineBanner` s'affiche bien quand `isOffline`
  passe à `true`.
- Générer les TypeAdapters Hive (`hive_generator`) si le modèle de données
  se complexifie au-delà de simples `Map`/`List` JSON-safe.
- Découper davantage `core/network` si de nouveaux besoins transverses
  apparaissent (ex. un client HTTP dédié pour un futur service tiers), pour
  que `core/` reste strictement limité à ce qui est partagé par toutes les
  features.
