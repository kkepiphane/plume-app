# 💰 Monnaie — Application de gestion personnelle de l'argent

> Application Flutter **offline-first**, légère et ultra-rapide pour enregistrer vos dépenses et revenus en moins de 3 secondes.

---

## 📋 Table des matières

1. [Aperçu](#aperçu)
2. [Fonctionnalités](#fonctionnalités)
3. [Architecture](#architecture)
4. [Structure du projet](#structure-du-projet)
5. [Installation](#installation)
6. [Configuration](#configuration)
7. [Guide des dépendances](#guide-des-dépendances)
8. [Fonctionnement hors-ligne](#fonctionnement-hors-ligne)
9. [Exportation des données](#exportation-des-données)
10. [Personnalisation](#personnalisation)
11. [Performance](#performance)
12. [Roadmap](#roadmap)

---

## Aperçu

**Monnaie** est une application mobile Flutter conçue pour les marchés africains et internationaux. Elle permet à tout utilisateur de gérer ses finances personnelles de façon simple, rapide et sans connexion internet.

### Captures d'écran (description)

| Écran               | Description                                                   |
| ------------------- | ------------------------------------------------------------- |
| **Onboarding**      | Configuration initiale : devise, budget, seuils d'alerte      |
| **Tableau de bord** | Solde, dépenses du jour, actions rapides, insights            |
| **Ajout rapide**    | Montant → Catégorie → Enregistrer (< 3 secondes)              |
| **Transactions**    | Liste filtrée par période, recherche, glisser-supprimer       |
| **Statistiques**    | Graphiques camembert, courbe d'évolution, analyse par période |
| **Paramètres**      | Devise, budget, alertes, export, mode sombre                  |

---

## Fonctionnalités

### ✅ Implémentées

#### 1. Configuration initiale (Onboarding)

- Choix de devise : XOF, USD, EUR, CNY, GHS, XAF, GNF, MAD, NGN, ou devise personnalisée
- Définition du budget mensuel
- Seuils d'alerte configurables (ex. 50%, 75%, 100%)

#### 2. Gestion des transactions

- **Dépenses** : Transport, Nourriture, Téléphone, Loyer, Santé, Loisirs, Vêtements, Éducation, Eau/Électricité, Autres
- **Revenus** : Salaire, Transfert, Business, Investissement, Freelance, Cadeau, Autres
- Chaque transaction contient : montant, type, catégorie, note optionnelle, date, heure
- Interface ultra-rapide : montants prédéfinis pour saisie en 1 tap
- Modification et suppression par glissement

#### 3. Statistiques

- **Aujourd'hui** : total dépensé / gagné
- **Semaine** : vue hebdomadaire
- **Mois** : vue mensuelle avec camembert des dépenses
- **Année** : vue annuelle
- Métriques : revenu total, dépenses, solde, taux d'épargne

#### 4. Analyse financière automatique

- Détection si l'utilisateur économise ou dépense trop
- Messages personnalisés : "Vous économisez X% ce mois-ci"
- Alerte si les dépenses dépassent les revenus
- Indicateur de progression du budget

#### 5. Notifications intelligentes

- Alerte à 50%, 75% et 100% du budget (seuils configurables)
- Notification dès qu'un seuil est franchi lors d'un ajout

#### 6. Sauvegarde

- Stockage local avec **Hive** (NoSQL, ultra-rapide)
- Export CSV/Excel partageables
- Sauvegarde automatique configurable

#### 7. Interface utilisateur

- **Mode sombre** complet
- Navigation bottom bar (Accueil, Transactions, Stats, Paramètres)
- Recherche dans les transactions
- Filtres par période (Aujourd'hui, Semaine, Mois, Année, Tout)
- Suppression par glissement

---

## Architecture

L'application suit une **Clean Architecture** stricte avec 3 couches :

```
┌─────────────────────────────────────────────────┐
│          PRESENTATION LAYER                     │
│  Pages · Providers (Riverpod) · Widgets         │
├─────────────────────────────────────────────────┤
│            DOMAIN LAYER                         │
│  Entities · Repository Interfaces · Use Cases   │
├─────────────────────────────────────────────────┤
│             DATA LAYER                          │
│  Models (Hive) · Datasources · Repositories     │
└─────────────────────────────────────────────────┘
```

### Gestion d'état : Riverpod

- `StateNotifierProvider` pour les transactions et paramètres
- `Provider` pour les résumés financiers calculés
- Réactivité automatique : mise à jour de l'UI dès qu'une transaction est ajoutée

### Base de données : Hive

- NoSQL orienté clé-valeur, sans serveur
- Adapté aux téléphones peu puissants
- 3 boxes : `transactions`, `categories`, `settings`

---

## Structure du projet

```
lib/
├── main.dart                          # Point d'entrée
│
├── core/
│   ├── constants/
│   │   └── app_constants.dart         # Constantes globales, devises, catégories
│   ├── theme/
│   │   └── app_theme.dart             # Thème clair/sombre, couleurs
│   ├── utils/
│   │   ├── app_router.dart            # Navigation avec go_router
│   │   ├── formatters.dart            # Formatage devise, date, pourcentage
│   │   ├── notification_service.dart  # Notifications locales
│   │   └── export_service.dart        # Export CSV
│   └── widgets/
│       └── shared_widgets.dart        # Composants réutilisables
│
├── data/
│   ├── datasources/
│   │   └── local_datasource.dart      # Accès Hive (CRUD)
│   ├── models/
│   │   ├── transaction_model.dart     # Modèle Hive + adaptateur
│   │   └── transaction_model.g.dart  # Code généré (build_runner)
│   └── repositories/
│       └── repositories.dart          # Implémentations des repos
│
├── domain/
│   └── entities/
│       └── entities.dart              # Entités métier pures
│
└── presentation/
    ├── providers/
    │   └── app_providers.dart         # Providers Riverpod
    └── pages/
        ├── onboarding/
        │   └── onboarding_page.dart
        ├── home/
        │   └── home_page.dart
        ├── transactions/
        │   ├── transactions_page.dart
        │   └── add_transaction_page.dart
        ├── statistics/
        │   └── statistics_page.dart
        └── settings/
            └── settings_page.dart
```

---

## Installation

### Prérequis

- Flutter SDK ≥ 3.0.0
- Dart ≥ 3.0.0
- Android SDK (API 21+) ou iOS 12+

### Étapes

```bash
# 1. Cloner le projet
git clone <repo-url>
cd monnaie

# 2. Installer les dépendances
flutter pub get

# 3. Générer les adaptateurs Hive
flutter pub run build_runner build --delete-conflicting-outputs

# 4. Lancer l'application
flutter run
```

### Build de production

```bash
# APK Android
flutter build apk --release --split-per-abi

# App Bundle (Play Store)
flutter build appbundle --release

# iOS (sur macOS)
flutter build ipa --release
```

---

## Configuration

### Ajouter une nouvelle devise

Dans `lib/core/constants/app_constants.dart`, ajouter à `supportedCurrencies` :

```dart
{'code': 'MAD', 'symbol': 'DH', 'name': 'Dirham marocain'},
```

### Ajouter une catégorie par défaut

Dans `app_constants.dart`, ajouter à `ExpenseCategories.defaults` ou `IncomeCategories.defaults` :

```dart
{'id': 'abonnement', 'label': 'Abonnement', 'icon': '📺', 'color': 0xFF5C6BC0},
```

### Modifier les couleurs

Dans `lib/core/theme/app_theme.dart`, modifier `AppColors` :

```dart
static const Color primary = Color(0xFF00897B); // Teal principal
static const Color income  = Color(0xFF2E7D32); // Vert revenu
static const Color expense = Color(0xFFC62828); // Rouge dépense
```

---

## Guide des dépendances

| Package                         | Usage                          | Version |
| ------------------------------- | ------------------------------ | ------- |
| `flutter_riverpod`              | Gestion d'état                 | ^2.5.1  |
| `hive` + `hive_flutter`         | Base de données locale         | ^2.2.3  |
| `go_router`                     | Navigation déclarative         | ^13.2.4 |
| `fl_chart`                      | Graphiques (camembert, courbe) | ^0.68.0 |
| `flutter_local_notifications`   | Notifications push locales     | ^17.1.2 |
| `csv`                           | Export CSV                     | ^6.0.0  |
| `share_plus`                    | Partage de fichiers            | ^9.0.0  |
| `intl`                          | Formatage dates/devises        | ^0.19.0 |
| `path_provider`                 | Accès système de fichiers      | ^2.1.3  |
| `uuid`                          | Génération d'IDs uniques       | ^4.4.0  |
| `flutter_animate`               | Animations fluides             | ^4.5.0  |
| `pdf` + `printing`              | Export PDF (optionnel)         | ^3.10.8 |
| `google_sign_in` + `googleapis` | Sync Google Drive (optionnel)  | ^6.2.1  |

---

## Fonctionnement hors-ligne

L'application est **100% offline-first** :

1. Toutes les données sont stockées localement via **Hive**
2. Aucune requête réseau n'est effectuée pour le fonctionnement principal
3. La synchronisation Google Drive est optionnelle et ne bloque pas l'app
4. L'export CSV fonctionne sans connexion

---

## Exportation des données

### Format CSV

Le fichier exporté contient les colonnes :

```
ID ; Montant ; Type ; Catégorie ; Note ; Date ; Heure
```

Le fichier inclut un BOM UTF-8 pour une compatibilité optimale avec Excel.

### Partage

L'export utilise `share_plus` pour partager via n'importe quelle app (WhatsApp, Gmail, Google Drive, Dropbox, etc.)

---

## Personnalisation

### Catégories personnalisées

L'architecture permet d'ajouter des catégories personnalisées via l'interface `CategoryRepository` :

```dart
final repo = ref.watch(categoryRepositoryProvider);
await repo.save(CategoryEntity(
  id: 'custom_1',
  label: 'Mon Épargne',
  icon: '🏦',
  color: 0xFF1565C0,
  isExpense: false,
  isCustom: true,
));
```

### Intégration Google Drive

Pour activer la synchronisation Google Drive :

1. Configurer un projet dans [Google Cloud Console](https://console.cloud.google.com)
2. Activer l'API Google Drive
3. Ajouter les `client_id` dans `android/app/build.gradle` et `ios/Runner/Info.plist`
4. Implémenter le service de synchronisation en utilisant `googleapis`

---

## Performance

### Optimisations appliquées

- **Hive** : base de données en mémoire, accès O(1)
- `NeverScrollableScrollPhysics` pour les listes imbriquées
- `TextScaler.noScaling` pour éviter les redimensionnements
- Calculs de résumés en temps réel (pas de cache excessif)
- `NoTransitionPage` entre les tabs pour une navigation instantanée
- Orientation fixée en portrait pour économiser les ressources

### Cibles de performance

| Opération              | Objectif   | Résultat attendu |
| ---------------------- | ---------- | ---------------- |
| Démarrage              | < 1.5s     | ✅               |
| Ajout transaction      | < 3s       | ✅               |
| Chargement stats       | < 200ms    | ✅               |
| Recherche transactions | Temps réel | ✅               |

---

## Roadmap

### v1.1 (prochaine version)

- [ ] Synchronisation Google Drive complète
- [ ] Export PDF du rapport mensuel
- [ ] Widget Android pour afficher le solde
- [ ] Catégories personnalisables dans l'UI
- [ ] Budgets par catégorie

### v1.2

- [ ] Transactions récurrentes (abonnements)
- [ ] Objectifs d'épargne
- [ ] Graphiques de tendances sur 12 mois
- [ ] Import depuis CSV/Excel
- [ ] Support multilingue (EN, FR, AR)

### v2.0

- [ ] Synchronisation multi-appareils
- [ ] OCR de reçus (ajout automatique)
- [ ] IA pour la catégorisation automatique

---

## Contribuer

1. Fork le projet
2. Créez votre branche (`git checkout -b feature/ma-fonctionnalite`)
3. Committez vos changements (`git commit -m 'Ajout: ma fonctionnalité'`)
4. Push la branche (`git push origin feature/ma-fonctionnalite`)
5. Ouvrez une Pull Request

---

## Licence

MIT License — Libre d'utilisation, modification et distribution.

---

_Développé avec ❤️ pour simplifier la gestion financière quotidienne_
