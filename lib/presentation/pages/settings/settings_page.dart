// lib/presentation/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/utils/backup_service.dart';
import '../../../domain/entities/settings_entity.dart';
import '../../providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(
        children: [
          // ── DEVISE ──────────────────────────────────────────────────────
          _header(context, 'COMPTE & DEVISE'),
          _Card(children: [
            _Tile(
              icon: Icons.monetization_on_outlined,
              title: 'Devise',
              subtitle: '${settings.currencyCode} (${settings.currencySymbol})',
              onTap: () => _showCurrencyPicker(context, ref, settings),
            ),
            _divider(context),
            _Tile(
              icon: Icons.account_balance_wallet_outlined,
              title: 'Budget mensuel',
              subtitle: settings.monthlyBudget > 0
                  ? '${settings.monthlyBudget.toStringAsFixed(0)} ${settings.currencySymbol}'
                  : 'Non défini',
              onTap: () => _showBudgetDialog(context, ref, settings),
            ),
          ]),

          // ── ALERTES ─────────────────────────────────────────────────────
          _header(context, 'ALERTES BUDGET'),
          _Card(children: [
            _SliderTile(
              icon: Icons.notifications_outlined,
              title: 'Première alerte',
              value: settings.alertThreshold1,
              color: Colors.green.shade600,
              onChanged: (v) => ref.read(settingsProvider.notifier)
                  .update(settings.copyWith(alertThreshold1: v)),
            ),
            _divider(context),
            _SliderTile(
              icon: Icons.notifications_active_outlined,
              title: 'Deuxième alerte',
              value: settings.alertThreshold2,
              color: Colors.orange.shade600,
              onChanged: (v) => ref.read(settingsProvider.notifier)
                  .update(settings.copyWith(alertThreshold2: v)),
            ),
            _divider(context),
            _InfoBanner(
              icon: Icons.error_outline_rounded,
              message: 'Une alerte à 100% est toujours activée.',
              color: Colors.red,
            ),
          ]),

          // ── RAPPEL DU SOIR ──────────────────────────────────────────────
          _header(context, 'RAPPEL DU SOIR'),
          _Card(children: [
            _SwitchTile(
              icon: Icons.bedtime_outlined,
              title: 'Rappel quotidien',
              subtitle: 'Notification si aucune transaction enregistrée',
              value: settings.eveningReminder,
              onChanged: (v) => ref.read(settingsProvider.notifier)
                  .update(settings.copyWith(eveningReminder: v)),
            ),
            if (settings.eveningReminder) ...[
              _divider(context),
              _Tile(
                icon: Icons.access_time_rounded,
                title: "Heure du rappel",
                subtitle: _formatTime(settings.reminderHour, settings.reminderMinute),
                onTap: () => _pickReminderTime(context, ref, settings),
              ),
            ],
          ]),

          // ── SAUVEGARDE ──────────────────────────────────────────────────
          _header(context, 'SAUVEGARDE & RESTAURATION'),
          _Card(children: [
            _InfoBanner(
              icon: Icons.info_outline_rounded,
              message:
                  'Sauvegardez vos transactions en les envoyant à votre propre email. '
                  'Pour restaurer, collez le contenu de l\'email reçu.',
              color: Colors.blue,
            ),
            _divider(context),
            _Tile(
              icon: Icons.email_outlined,
              title: 'Email de sauvegarde',
              subtitle: settings.backupEmail?.isNotEmpty == true
                  ? settings.backupEmail!
                  : 'Non défini — appuyez pour configurer',
              onTap: () => _showEmailDialog(context, ref, settings),
            ),
            _divider(context),
            _Tile(
              icon: Icons.backup_outlined,
              title: 'Envoyer une sauvegarde',
              subtitle: 'Envoyer vos données à votre email',
              onTap: () => _doBackup(context, ref, settings),
            ),
            _divider(context),
            _Tile(
              icon: Icons.restore_rounded,
              title: 'Restaurer',
              subtitle: 'Coller le code de sauvegarde reçu par email',
              onTap: () => _showRestoreDialog(context, ref),
            ),
          ]),

          // ── APPARENCE ───────────────────────────────────────────────────
          _header(context, 'APPARENCE'),
          _Card(children: [
            _SwitchTile(
              icon: Icons.dark_mode_outlined,
              title: 'Mode sombre',
              value: settings.isDarkMode,
              onChanged: (_) =>
                  ref.read(settingsProvider.notifier).toggleDarkMode(),
            ),
          ]),

          // ── À PROPOS ────────────────────────────────────────────────────
          _header(context, 'À PROPOS'),
          _Card(children: [
            _Tile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: AppConstants.appVersion,
            ),
          ]),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ── helpers ───────────────────────────────────────────────────────────────

  String _formatTime(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  Widget _header(BuildContext context, String title) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
    child: Text(title,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700, letterSpacing: 1)),
  );

  Widget _divider(BuildContext context) =>
      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor);

  // ── ACTIONS ───────────────────────────────────────────────────────────────

  Future<void> _pickReminderTime(
      BuildContext context, WidgetRef ref, SettingsEntity settings) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
          hour: settings.reminderHour, minute: settings.reminderMinute),
      helpText: 'Heure du rappel du soir',
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(settingsProvider.notifier).update(
            settings.copyWith(
                reminderHour: picked.hour, reminderMinute: picked.minute),
          );
    }
  }

  void _showCurrencyPicker(
      BuildContext context, WidgetRef ref, SettingsEntity settings) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, controller) => Column(children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Choisir une devise',
                style: Theme.of(context).textTheme.titleMedium),
          ),
          Expanded(
            child: ListView.separated(
              controller: controller,
              itemCount: AppConstants.supportedCurrencies.length,
              separatorBuilder: (_, __) => Divider(
                  height: 1,
                  indent: 20,
                  color: Theme.of(context).dividerColor),
              itemBuilder: (ctx, i) {
                final c = AppConstants.supportedCurrencies[i];
                final isSelected = settings.currencyCode == c['code'];
                return ListTile(
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8)),
                    child: Center(
                        child: Text(
                            c['symbol']!.isNotEmpty ? c['symbol']! : '?',
                            style: const TextStyle(fontWeight: FontWeight.w700))),
                  ),
                  title: Text(c['code']!),
                  subtitle: Text(c['name']!),
                  trailing: isSelected
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    if (c['code'] == 'CUSTOM') {
                      Navigator.pop(ctx);
                      _showCustomCurrencyDialog(context, ref, settings);
                    } else {
                      ref.read(settingsProvider.notifier).update(
                            settings.copyWith(
                              currencyCode:   c['code'],
                              currencySymbol: c['symbol'],
                              currencyName:   c['name'],
                            ),
                          );
                      Navigator.pop(ctx);
                    }
                  },
                );
              },
            ),
          ),
        ]),
      ),
    );
  }

  void _showCustomCurrencyDialog(
      BuildContext context, WidgetRef ref, SettingsEntity settings) {
    final ctrl = TextEditingController();
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Devise personnalisée'),
              content: TextField(
                  controller: ctrl,
                  decoration: const InputDecoration(labelText: 'Symbole (ex: DA, TND)'),
                  textCapitalization: TextCapitalization.characters),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Annuler')),
                ElevatedButton(
                    onPressed: () {
                      if (ctrl.text.isNotEmpty)
                        ref.read(settingsProvider.notifier).update(
                              settings.copyWith(
                                currencyCode:   'CUSTOM',
                                currencySymbol: ctrl.text.toUpperCase(),
                                currencyName:   'Devise personnalisée',
                              ),
                            );
                      Navigator.pop(ctx);
                    },
                    child: const Text('Confirmer')),
              ],
            ));
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, SettingsEntity settings) {
    final ctrl = TextEditingController(
        text: settings.monthlyBudget > 0
            ? settings.monthlyBudget.toStringAsFixed(0)
            : '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Budget mensuel'),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
              labelText: 'Montant',
              suffixText: settings.currencySymbol),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () {
              ref
                  .read(settingsProvider.notifier)
                  .update(settings.copyWith(monthlyBudget: 0));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
          ElevatedButton(
              onPressed: () {
                final v = double.tryParse(
                        ctrl.text.replaceAll(',', '.')) ??
                    0;
                ref
                    .read(settingsProvider.notifier)
                    .update(settings.copyWith(monthlyBudget: v));
                Navigator.pop(ctx);
              },
              child: const Text('Confirmer')),
        ],
      ),
    );
  }

  void _showEmailDialog(
      BuildContext context, WidgetRef ref, SettingsEntity settings) {
    final ctrl =
        TextEditingController(text: settings.backupEmail ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Email de sauvegarde'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          decoration: const InputDecoration(
            labelText: 'Votre adresse email',
            hintText: 'exemple@mail.com',
            prefixIcon: Icon(Icons.email_outlined),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () {
                ref.read(settingsProvider.notifier).update(
                      settings.copyWith(backupEmail: ctrl.text.trim()),
                    );
                Navigator.pop(ctx);
              },
              child: const Text('Enregistrer')),
        ],
      ),
    );
  }

  Future<void> _doBackup(
      BuildContext context, WidgetRef ref, SettingsEntity settings) async {
    final email = settings.backupEmail;
    if (email == null || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text(
                'Veuillez d\'abord configurer votre email de sauvegarde.')),
      );
      return;
    }
    try {
      await BackupService().sendBackupByEmail(email: email);
    } catch (e) {
      if (context.mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
    }
  }

  void _showRestoreDialog(BuildContext context, WidgetRef ref) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restaurer mes données'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Copiez le contenu du corps de votre email de sauvegarde et collez-le ici.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: const InputDecoration(
                hintText: 'Collez le code de sauvegarde ici...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                final count =
                    await BackupService().restoreFromText(ctrl.text);
                // Reload transactions after restore
                ref.read(transactionsProvider.notifier).load();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('$count transactions restaurées avec succès.'),
                    backgroundColor: Colors.green.shade700,
                  ));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Erreur: $e'),
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            child: const Text('Restaurer'),
          ),
        ],
      ),
    );
  }
}

// ── Reusable setting widgets ──────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final List<Widget> children;
  const _Card({required this.children});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).dividerColor),
        ),
        child: Column(children: children),
      );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  const _Tile(
      {required this.icon, required this.title, this.subtitle, this.onTap});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: primary, size: 18),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right,
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withOpacity(0.3))
          : null,
      onTap: onTap,
    );
  }
}

class _SwitchTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _SwitchTile(
      {required this.icon,
      required this.title,
      this.subtitle,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
            color: primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: primary, size: 18),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: Switch.adaptive(
          value: value, onChanged: onChanged, activeColor: primary),
    );
  }
}

class _SliderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final Color color;
  final ValueChanged<double> onChanged;
  const _SliderTile(
      {required this.icon,
      required this.title,
      required this.value,
      required this.color,
      required this.onChanged});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(title,
                            style:
                                Theme.of(context).textTheme.titleSmall),
                        Text('${value.toInt()}%',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: color)),
                      ]),
                  Slider(
                      value: value,
                      min: 10,
                      max: 95,
                      divisions: 17,
                      activeColor: color,
                      onChanged: onChanged),
                ]),
          ),
        ]),
      );
}

class _InfoBanner extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;
  const _InfoBanner(
      {required this.icon, required this.message, required this.color});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child: Text(message,
                  style: TextStyle(fontSize: 12, color: color))),
        ]),
      );
}