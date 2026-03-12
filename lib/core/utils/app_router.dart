// lib/core/utils/app_router.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../presentation/pages/home/home_page.dart';
import '../../presentation/pages/transactions/transactions_page.dart';
import '../../presentation/pages/transactions/add_transaction_page.dart';
import '../../presentation/pages/statistics/statistics_page.dart';
import '../../presentation/pages/settings/settings_page.dart';
import '../../presentation/pages/onboarding/onboarding_page.dart';
import '../../presentation/pages/auth/auth_page.dart';
import '../../presentation/pages/savings/savings_page.dart';
import '../../presentation/pages/subscriptions/subscriptions_page.dart';
import '../../presentation/pages/reports/reports_page.dart';
import '../../presentation/pages/family/family_page.dart';
import '../../presentation/pages/anomalies/anomalies_page.dart';
import '../../presentation/providers/app_providers.dart';

final _rootKey  = GlobalKey<NavigatorState>();
final _shellKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final settingsRepo = ref.read(settingsRepositoryProvider);
  return GoRouter(
    navigatorKey: _rootKey,
    initialLocation: settingsRepo.isOnboardingDone() ? '/home' : '/onboarding',
    routes: [
      GoRoute(path: '/onboarding',
          builder: (_, __) => const OnboardingPage()),
      GoRoute(path: '/auth',
          parentNavigatorKey: _rootKey,
          builder: (_, __) => const AuthPage()),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionPage(
            isExpense:   extra?['isExpense'] ?? true,
            transaction: extra?['transaction'],
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: HomePage())),
          GoRoute(path: '/transactions',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: TransactionsPage())),
          GoRoute(path: '/statistics',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: StatisticsPage())),
          GoRoute(path: '/savings',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SavingsPage())),
          GoRoute(path: '/subscriptions',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SubscriptionsPage())),
          GoRoute(path: '/reports',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: ReportsPage())),
          GoRoute(path: '/family',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: FamilyPage())),
          GoRoute(path: '/anomalies',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: AnomaliesPage())),
          GoRoute(path: '/settings',
              pageBuilder: (_, __) =>
                  const NoTransitionPage(child: SettingsPage())),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static int _idx(String loc) {
    if (loc.startsWith('/home'))          return 0;
    if (loc.startsWith('/transactions'))  return 1;
    if (loc.startsWith('/statistics'))    return 2;
    if (loc.startsWith('/savings'))       return 3;
    if (loc.startsWith('/settings'))      return 4;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).uri.toString();
    // Hide nav bar on subscriptions page (accessed from settings or home)
    if (loc.startsWith('/subscriptions') ||
        loc.startsWith('/reports') ||
        loc.startsWith('/family') ||
        loc.startsWith('/anomalies')) {
      return Scaffold(body: child);
    }
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _idx(loc),
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');         break;
            case 1: context.go('/transactions'); break;
            case 2: context.go('/statistics');   break;
            case 3: context.go('/savings');      break;
            case 4: context.go('/settings');     break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long_rounded),
              label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart_rounded),
              label: 'Stats'),
          NavigationDestination(icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings_rounded),
              label: 'Épargne'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings_rounded),
              label: 'Réglages'),
        ],
      ),
    );
  }
}