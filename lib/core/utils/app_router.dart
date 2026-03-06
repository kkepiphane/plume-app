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
import '../../presentation/providers/app_providers.dart';

final _rootNavigatorKey  = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final settingsRepo = ref.read(settingsRepositoryProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: settingsRepo.isOnboardingDone() ? '/home' : '/onboarding',
    routes: [
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: '/auth',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, __) => const AuthPage(),
      ),
      GoRoute(
        path: '/add-transaction',
        parentNavigatorKey: _rootNavigatorKey,
        builder: (_, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return AddTransactionPage(
            isExpense:   extra?['isExpense'] ?? true,
            transaction: extra?['transaction'],
          );
        },
      ),
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (_, __, child) => MainShell(child: child),
        routes: [
          GoRoute(path: '/home',
              pageBuilder: (_, __) => const NoTransitionPage(child: HomePage())),
          GoRoute(path: '/transactions',
              pageBuilder: (_, __) => const NoTransitionPage(child: TransactionsPage())),
          GoRoute(path: '/statistics',
              pageBuilder: (_, __) => const NoTransitionPage(child: StatisticsPage())),
          GoRoute(path: '/settings',
              pageBuilder: (_, __) => const NoTransitionPage(child: SettingsPage())),
        ],
      ),
    ],
  );
});

class MainShell extends StatelessWidget {
  final Widget child;
  const MainShell({super.key, required this.child});

  static int _locationToIndex(String loc) {
    if (loc.startsWith('/home'))         return 0;
    if (loc.startsWith('/transactions')) return 1;
    if (loc.startsWith('/statistics'))   return 2;
    if (loc.startsWith('/settings'))     return 3;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    final idx      = _locationToIndex(location);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');         break;
            case 1: context.go('/transactions'); break;
            case 2: context.go('/statistics');   break;
            case 3: context.go('/settings');     break;
          }
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home), label: 'Accueil'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined),
              selectedIcon: Icon(Icons.receipt_long), label: 'Transactions'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart), label: 'Statistiques'),
          NavigationDestination(icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings), label: 'Paramètres'),
        ],
      ),
    );
  }
}