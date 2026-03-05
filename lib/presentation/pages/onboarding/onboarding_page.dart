// lib/presentation/pages/onboarding/onboarding_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../domain/entities/settings_entity.dart';
import '../../providers/app_providers.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final _pageController = PageController();
  int _currentPage = 0;

  String _selectedCurrency = 'XOF';
  String _currencySymbol = 'F';
  String _currencyName = 'Franc CFA (BCEAO)';
  String _customCurrency = '';
  final _budgetController = TextEditingController();
  double _alertThreshold1 = 50;
  double _alertThreshold2 = 75;

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
    } else {
      _finishOnboarding();
    }
  }

  Future<void> _finishOnboarding() async {
    final budget = double.tryParse(_budgetController.text.replaceAll(',', '.')) ?? 0;
    final settings = SettingsEntity(
      currencyCode: _selectedCurrency,
      currencySymbol: _selectedCurrency == 'CUSTOM' ? _customCurrency : _currencySymbol,
      currencyName: _currencyName,
      monthlyBudget: budget,
      alertThreshold1: _alertThreshold1,
      alertThreshold2: _alertThreshold2,
    );
    await ref.read(settingsProvider.notifier).update(settings);
    await ref.read(settingsRepositoryProvider).setOnboardingDone();
    if (mounted) context.go('/home');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 4,
                    decoration: BoxDecoration(
                      color: i <= _currentPage ? cs.primary : cs.surfaceVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (p) => setState(() => _currentPage = p),
                children: [
                  _WelcomePage(onNext: _nextPage),
                  _CurrencyPage(
                    selected: _selectedCurrency,
                    onSelect: (code, symbol, name) => setState(() {
                      _selectedCurrency = code; _currencySymbol = symbol; _currencyName = name;
                    }),
                    onCustomChange: (v) => setState(() => _customCurrency = v),
                    onNext: _nextPage,
                  ),
                  _BudgetPage(
                    budgetController: _budgetController,
                    currencySymbol: _selectedCurrency == 'CUSTOM' ? _customCurrency : _currencySymbol,
                    threshold1: _alertThreshold1,
                    threshold2: _alertThreshold2,
                    onThreshold1Change: (v) => setState(() => _alertThreshold1 = v),
                    onThreshold2Change: (v) => setState(() => _alertThreshold2 = v),
                    onFinish: _finishOnboarding,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  final VoidCallback onNext;
  const _WelcomePage({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96, height: 96,
            decoration: BoxDecoration(color: cs.primary.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(Icons.account_balance_wallet_rounded, size: 52, color: cs.primary),
          ),
          const SizedBox(height: 32),
          Text('Bienvenue sur\nMonnaie',
              style: Theme.of(context).textTheme.displayLarge?.copyWith(height: 1.1),
              textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text('Gérez vos finances personnelles simplement et rapidement. Enregistrez une transaction en moins de 3 secondes.',
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center),
          const SizedBox(height: 40),
          _Feature(icon: Icons.bolt_rounded, text: 'Ultra rapide — moins de 3 secondes par transaction'),
          const SizedBox(height: 12),
          _Feature(icon: Icons.wifi_off_rounded, text: 'Fonctionne sans connexion internet'),
          const SizedBox(height: 12),
          _Feature(icon: Icons.bar_chart_rounded, text: 'Statistiques claires et visuelles'),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onNext,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              child: const Text('Commencer', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}

class _Feature extends StatelessWidget {
  final IconData icon;
  final String text;
  const _Feature({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: Theme.of(context).colorScheme.primary, size: 22),
    const SizedBox(width: 12),
    Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
  ]);
}

class _CurrencyPage extends StatelessWidget {
  final String selected;
  final Function(String, String, String) onSelect;
  final ValueChanged<String> onCustomChange;
  final VoidCallback onNext;

  const _CurrencyPage({required this.selected, required this.onSelect,
      required this.onCustomChange, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choisissez votre devise', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Vous pourrez la modifier plus tard dans les paramètres.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 24),
          Expanded(
            child: ListView.separated(
              itemCount: AppConstants.supportedCurrencies.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final c = AppConstants.supportedCurrencies[i];
                final isSelected = selected == c['code'];
                return GestureDetector(
                  onTap: () => onSelect(c['code']!, c['symbol']!, c['name']!),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isSelected ? cs.primary.withOpacity(0.08) : Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: isSelected ? cs.primary : Theme.of(context).dividerColor,
                          width: isSelected ? 2 : 1),
                    ),
                    child: Row(children: [
                      Container(width: 44, height: 44,
                          decoration: BoxDecoration(color: cs.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(
                              c['symbol']!.isNotEmpty ? c['symbol']! : '?',
                              style: TextStyle(fontSize: c['symbol']!.length > 1 ? 14 : 20, fontWeight: FontWeight.w700, color: cs.primary)))),
                      const SizedBox(width: 12),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c['code']!, style: Theme.of(context).textTheme.titleSmall),
                        Text(c['name']!, style: Theme.of(context).textTheme.bodySmall),
                      ])),
                      if (isSelected) Icon(Icons.check_circle, color: cs.primary),
                    ]),
                  ),
                );
              },
            ),
          ),
          if (selected == 'CUSTOM') ...[
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                  labelText: 'Symbole de votre devise (ex: DA, TND...)',
                  prefixIcon: Icon(Icons.monetization_on_outlined)),
              onChanged: onCustomChange,
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: onNext,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Continuer', style: TextStyle(fontSize: 16)))),
        ],
      ),
    );
  }
}

class _BudgetPage extends StatelessWidget {
  final TextEditingController budgetController;
  final String currencySymbol;
  final double threshold1, threshold2;
  final ValueChanged<double> onThreshold1Change, onThreshold2Change;
  final VoidCallback onFinish;

  const _BudgetPage({required this.budgetController, required this.currencySymbol,
      required this.threshold1, required this.threshold2,
      required this.onThreshold1Change, required this.onThreshold2Change, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Configurez votre budget', style: Theme.of(context).textTheme.headlineLarge),
          const SizedBox(height: 8),
          Text('Définissez un budget mensuel et des seuils d\'alerte.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 32),
          Text('Budget mensuel', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          TextField(
            controller: budgetController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(hintText: 'Ex: 150000', suffixText: currencySymbol,
                prefixIcon: const Icon(Icons.account_balance_wallet_outlined)),
          ),
          const SizedBox(height: 8),
          Text('Laissez vide pour ne pas définir de budget',
              style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 32),
          Text('Alertes de dépenses', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 16),
          _ThresholdSlider(label: 'Première alerte', value: threshold1,
              onChanged: onThreshold1Change, color: Colors.green.shade600),
          const SizedBox(height: 16),
          _ThresholdSlider(label: 'Deuxième alerte', value: threshold2,
              onChanged: onThreshold2Change, color: Colors.orange.shade600),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              const Icon(Icons.error_outline_rounded, color: Colors.red, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text('Une alerte à 100% est toujours activée',
                  style: const TextStyle(fontSize: 12, color: Colors.red))),
            ]),
          ),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity,
              child: ElevatedButton(onPressed: onFinish,
                  style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                  child: const Text('Commencer à utiliser Monnaie', style: TextStyle(fontSize: 16)))),
          const SizedBox(height: 8),
          Center(child: TextButton(onPressed: onFinish, child: const Text('Ignorer pour l\'instant'))),
        ],
      ),
    );
  }
}

class _ThresholdSlider extends StatelessWidget {
  final String label;
  final double value;
  final ValueChanged<double> onChanged;
  final Color color;
  const _ThresholdSlider({required this.label, required this.value, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text('${value.toInt()}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
      ]),
      Slider(value: value, min: 10, max: 95, divisions: 17, activeColor: color, onChanged: onChanged),
    ],
  );
}