// lib/presentation/pages/settings/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/sync_service.dart';
import '../../../domain/entities/settings_entity.dart';
import '../../providers/app_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isLogged = ref.watch(authStateProvider);
    final lastSync = ref.watch(lastSyncProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Paramètres')),
      body: ListView(children: [
        // ── DEVISE ────────────────────────────────────────────────────────
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

        // ── ALERTES ───────────────────────────────────────────────────────
        _header(context, 'ALERTES BUDGET'),
        _Card(children: [
          _SliderTile(
            icon: Icons.notifications_outlined,
            title: 'Première alerte',
            value: settings.alertThreshold1,
            color: Colors.green.shade600,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(alertThreshold1: v)),
          ),
          _divider(context),
          _SliderTile(
            icon: Icons.notifications_active_outlined,
            title: 'Deuxième alerte',
            value: settings.alertThreshold2,
            color: Colors.orange.shade600,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(alertThreshold2: v)),
          ),
          _divider(context),
          _InfoBanner(
            icon: Icons.error_outline_rounded,
            message: 'Une alerte à 100% du budget est toujours activée.',
            color: Colors.red,
          ),
        ]),

        // ── RAPPEL DU SOIR ────────────────────────────────────────────────
        _header(context, 'RAPPEL DU SOIR'),
        _Card(children: [
          _SwitchTile(
            icon: Icons.bedtime_outlined,
            title: 'Rappel quotidien',
            subtitle: 'Si aucune transaction enregistrée dans la journée',
            value: settings.eveningReminder,
            onChanged: (v) => ref
                .read(settingsProvider.notifier)
                .update(settings.copyWith(eveningReminder: v)),
          ),
          if (settings.eveningReminder) ...[
            _divider(context),
            _Tile(
              icon: Icons.access_time_rounded,
              title: 'Heure du rappel',
              subtitle: _fmt(settings.reminderHour, settings.reminderMinute),
              onTap: () => _pickTime(context, ref, settings),
            ),
          ],
        ]),

        // ── APPARENCE ─────────────────────────────────────────────────────
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

        // ── SAUVEGARDE ────────────────────────────────────────────────────
        // _header(context, 'SAUVEGARDE GOOGLE DRIVE'),
        // _Card(children: [
        //   if (!isLogged) ...[
        //     _InfoBanner(
        //       icon: Icons.info_outline_rounded,
        //       message:
        //           'Connectez-vous pour sauvegarder vos données automatiquement '
        //           'chaque nuit à 2h00 sur votre Google Drive.',
        //       color: Theme.of(context).colorScheme.primary,
        //     ),
        //     _divider(context),
        //     _Tile(
        //       icon: Icons.login_rounded,
        //       title: 'Se connecter',
        //       subtitle: 'Email + code OTP — rapide et sans mot de passe',
        //       onTap: () => context.push('/auth'),
        //     ),
        //   ] else ...[
        //     // Logged in
        //     _InfoRow(
        //       icon: Icons.account_circle_outlined,
        //       label: 'Compte',
        //       value: AuthService().currentEmail ?? '',
        //     ),
        //     _divider(context),
        //     lastSync.when(
        //       data: (dt) => _InfoRow(
        //         icon: Icons.sync_rounded,
        //         label: 'Dernière sync',
        //         value: dt != null ? _formatSync(dt) : 'Jamais',
        //       ),
        //       loading: () => _InfoRow(
        //           icon: Icons.sync_rounded, label: 'Dernière sync', value: '…'),
        //       error: (_, __) => _InfoRow(
        //           icon: Icons.sync_rounded, label: 'Dernière sync', value: '—'),
        //     ),
        //     _divider(context),
        //     _Tile(
        //       icon: Icons.backup_outlined,
        //       title: 'Sauvegarder maintenant',
        //       subtitle: 'Envoyer les données vers Google Drive',
        //       onTap: () => _doBackupNow(context, ref),
        //     ),
        //     _divider(context),
        //     _Tile(
        //       icon: Icons.restore_rounded,
        //       title: 'Restaurer',
        //       subtitle: 'Récupérer les données depuis Google Drive',
        //       onTap: () => _doRestore(context, ref),
        //     ),
        //     _divider(context),
        //     _Tile(
        //       icon: Icons.logout_rounded,
        //       title: 'Se déconnecter',
        //       subtitle: 'Les données locales restent intactes',
        //       onTap: () => _doLogout(context, ref),
        //       danger: true,
        //     ),
        //   ],
        // ]),

        // ── À PROPOS ──────────────────────────────────────────────────────
        _header(context, 'À PROPOS'),
        _Card(children: [
          _Tile(
              icon: Icons.info_outline,
              title: 'Version',
              subtitle: AppConstants.appVersion),
        ]),

        const SizedBox(height: 40),
      ]),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  String _formatSync(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'À l\'instant';
    if (diff.inHours < 1) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${dt.day}/${dt.month}/${dt.year} à ${_fmt(dt.hour, dt.minute)}';
  }

  Widget _header(BuildContext context, String t) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        child: Text(t,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(fontWeight: FontWeight.w700, letterSpacing: 1)),
      );

  Widget _divider(BuildContext context) =>
      Divider(height: 1, indent: 56, color: Theme.of(context).dividerColor);

  // ── Actions ───────────────────────────────────────────────────────────────

  Future<void> _doBackupNow(BuildContext context, WidgetRef ref) async {
    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(const SnackBar(
      content: Row(children: [
        SizedBox(
            width: 18,
            height: 18,
            child:
                CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
        SizedBox(width: 12),
        Text('Sauvegarde en cours…'),
      ]),
      duration: Duration(seconds: 30),
    ));
    final err = await SyncService().backupNow();
    snack.clearSnackBars();
    ref.invalidate(lastSyncProvider);
    if (err != null) {
      snack.showSnackBar(
          SnackBar(content: Text(err), backgroundColor: Colors.red));
    } else {
      snack.showSnackBar(const SnackBar(
          content: Text('Sauvegarde réussie !'),
          backgroundColor: Colors.green));
    }
  }

  Future<void> _doRestore(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Restaurer les données ?'),
        content: const Text(
            'Les données de votre Drive seront fusionnées avec celles '
            'actuellement sur votre téléphone. Aucune donnée locale ne sera supprimée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Restaurer')),
        ],
      ),
    );
    if (confirm != true) return;

    final snack = ScaffoldMessenger.of(context);
    snack.showSnackBar(const SnackBar(
      content: Text('Restauration en cours…'),
      duration: Duration(seconds: 30),
    ));
    try {
      final count = await SyncService().restoreNow();
      ref.read(transactionsProvider.notifier).load();
      snack.clearSnackBars();
      if (context.mounted)
        snack.showSnackBar(SnackBar(
            content: Text('$count transactions restaurées !'),
            backgroundColor: Colors.green));
    } catch (e) {
      snack.clearSnackBars();
      if (context.mounted)
        snack.showSnackBar(SnackBar(
            content: Text('Erreur : $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _doLogout(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Se déconnecter ?'),
        content: const Text('Vos données locales restent intactes. '
            'La synchronisation automatique sera désactivée.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Déconnecter'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AuthService().signOut();
    await SyncService().cancelSync();
    ref.read(authStateProvider.notifier).state = false;
  }

  Future<void> _pickTime(
      BuildContext context, WidgetRef ref, SettingsEntity s) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: s.reminderHour, minute: s.reminderMinute),
      builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!),
    );
    if (t != null)
      ref
          .read(settingsProvider.notifier)
          .update(s.copyWith(reminderHour: t.hour, reminderMinute: t.minute));
  }

  void _showBudgetDialog(
      BuildContext context, WidgetRef ref, SettingsEntity s) {
    final ctrl = TextEditingController(
        text: s.monthlyBudget > 0 ? s.monthlyBudget.toStringAsFixed(0) : '');
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              title: const Text('Budget mensuel'),
              content: TextField(
                controller: ctrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                    labelText: 'Montant', suffixText: s.currencySymbol),
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
                        .update(s.copyWith(monthlyBudget: 0));
                    Navigator.pop(ctx);
                  },
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final v =
                        double.tryParse(ctrl.text.replaceAll(',', '.')) ?? 0;
                    ref
                        .read(settingsProvider.notifier)
                        .update(s.copyWith(monthlyBudget: v));
                    Navigator.pop(ctx);
                  },
                  child: const Text('Confirmer'),
                ),
              ],
            ));
  }

  void _showCurrencyPicker(
      BuildContext context, WidgetRef ref, SettingsEntity s) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (_, ctrl) => Column(children: [
          Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Choisir une devise',
                  style: Theme.of(context).textTheme.titleMedium)),
          Expanded(
              child: ListView.separated(
            controller: ctrl,
            itemCount: AppConstants.supportedCurrencies.length,
            separatorBuilder: (_, __) => Divider(
                height: 1, indent: 20, color: Theme.of(context).dividerColor),
            itemBuilder: (ctx, i) {
              final c = AppConstants.supportedCurrencies[i];
              final sel = s.currencyCode == c['code'];
              return ListTile(
                leading: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8)),
                  child: Center(
                      child: Text(c['symbol']!.isNotEmpty ? c['symbol']! : '?',
                          style: const TextStyle(fontWeight: FontWeight.w700))),
                ),
                title: Text(c['code']!),
                subtitle: Text(c['name']!),
                trailing: sel
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  ref.read(settingsProvider.notifier).update(s.copyWith(
                      currencyCode: c['code'],
                      currencySymbol: c['symbol'],
                      currencyName: c['name']));
                  Navigator.pop(ctx);
                },
              );
            },
          )),
        ]),
      ),
    );
  }
}

// ── Reusable widgets ──────────────────────────────────────────────────────────

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
  final bool danger;
  const _Tile(
      {required this.icon,
      required this.title,
      this.subtitle,
      this.onTap,
      this.danger = false});
  @override
  Widget build(BuildContext context) {
    final color = danger ? Colors.red : Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: color, size: 18),
      ),
      title: Text(title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(color: danger ? Colors.red : null)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3))
          : null,
      onTap: onTap,
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label, value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8)),
          child: Icon(icon,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ),
        const SizedBox(width: 12),
        Text(label, style: Theme.of(context).textTheme.titleSmall),
        const Spacer(),
        Text(value, style: Theme.of(context).textTheme.bodySmall),
      ]),
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
    final p = Theme.of(context).colorScheme.primary;
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
            color: p.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: p, size: 18),
      ),
      title: Text(title, style: Theme.of(context).textTheme.titleSmall),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall)
          : null,
      trailing:
          Switch.adaptive(value: value, onChanged: onChanged, activeColor: p),
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
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
            borderRadius: BorderRadius.circular(10)),
        child: Row(children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
              child:
                  Text(message, style: TextStyle(fontSize: 12, color: color))),
        ]),
      );
}
