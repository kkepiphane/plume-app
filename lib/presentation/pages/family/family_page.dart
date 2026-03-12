// lib/presentation/pages/family/family_page.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/family_service.dart';
import '../../../core/utils/formatters.dart';
import '../../../domain/entities/transaction_entity.dart';
import '../../providers/app_providers.dart';

class FamilyPage extends ConsumerStatefulWidget {
  const FamilyPage({super.key});
  @override
  ConsumerState<FamilyPage> createState() => _FamilyPageState();
}

class _FamilyPageState extends ConsumerState<FamilyPage> {
  final _nameCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  bool _loading   = false;
  String? _error;

  // Live feed of family transactions received this session
  final List<FamilyTransaction> _feed = [];

  @override
  void initState() {
    super.initState();
    FamilyService().onTransaction = (ft) {
      if (mounted) setState(() => _feed.insert(0, ft));
    };
    FamilyService().onMemberEvent = (msg) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('👤 $msg'),
            duration: const Duration(seconds: 2)));
    };
  }

  @override
  void dispose() {
    _nameCtrl.dispose(); _codeCtrl.dispose(); super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final svc      = FamilyService();
    final isInFam  = svc.isInFamily;
    final symbol   = ref.watch(settingsProvider).currencySymbol;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mode Famille'),
        actions: [
          if (isInFam)
            IconButton(
              icon: const Icon(Icons.logout_rounded),
              tooltip: 'Quitter la famille',
              onPressed: _confirmLeave,
            ),
        ],
      ),
      body: isInFam
          ? _buildFamilyView(svc, symbol)
          : _buildJoinView(),
    );
  }

  // ── Not in a family ────────────────────────────────────────────────────────
  Widget _buildJoinView() {
    final cs = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const SizedBox(height: 16),
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: cs.primary.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.people_rounded, size: 40, color: cs.primary),
        ),
        const SizedBox(height: 20),
        Text('Budget partagé en famille',
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
            textAlign: TextAlign.center),
        const SizedBox(height: 10),
        Text(
          'Créez un espace partagé pour que toute la famille '
          'voie les dépenses en temps réel. Chaque membre ajoute '
          'ses propres transactions.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: 32),

        TextField(
          controller: _nameCtrl,
          decoration: const InputDecoration(
            labelText: 'Votre prénom',
            prefixIcon: Icon(Icons.person_outline_rounded),
          ),
        ),
        const SizedBox(height: 24),

        if (_error != null)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10)),
            child: Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),

        // Create button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: _loading
                ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2,
                        color: Colors.white))
                : const Icon(Icons.add_home_rounded),
            label: const Text('Créer une famille',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _loading ? null : _createRoom,
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
        const SizedBox(height: 16),

        // Divider
        Row(children: [
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Text('ou rejoindre',
                style: Theme.of(context).textTheme.bodySmall)),
          Expanded(child: Divider(color: Theme.of(context).dividerColor)),
        ]),
        const SizedBox(height: 16),

        // Join with code
        TextField(
          controller: _codeCtrl,
          textCapitalization: TextCapitalization.characters,
          maxLength: 6,
          decoration: const InputDecoration(
            labelText: 'Code famille (6 caractères)',
            prefixIcon: Icon(Icons.vpn_key_outlined),
            counterText: '',
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('Rejoindre',
                style: TextStyle(fontWeight: FontWeight.w700)),
            onPressed: _loading ? null : _joinRoom,
            style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14)),
          ),
        ),
      ]),
    );
  }

  // ── Already in a family ────────────────────────────────────────────────────
  Widget _buildFamilyView(FamilyService svc, String symbol) {
    final cs = Theme.of(context).colorScheme;
    return Column(children: [
      // Family header
      Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [cs.primary, cs.primary.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          const Icon(Icons.people_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Famille de ${svc.memberName}',
                  style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w800,
                    fontSize: 16)),
              Text('Code : ${svc.roomId.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          )),
          // Copy code button
          IconButton(
            icon: const Icon(Icons.copy_rounded, color: Colors.white70),
            tooltip: 'Copier le code',
            onPressed: () {
              Clipboard.setData(ClipboardData(
                  text: svc.roomId.substring(0, 6).toUpperCase()));
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Code copié !'),
                  duration: Duration(seconds: 2)));
            },
          ),
        ]),
      ),

      // Live feed header
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        child: Row(children: [
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: Colors.green, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text('Activité en temps réel',
              style: Theme.of(context).textTheme.titleSmall),
        ]),
      ),

      // Feed list
      Expanded(child: _feed.isEmpty
          ? Center(child: Column(
              mainAxisSize: MainAxisSize.min, children: [
              const Text('📡', style: TextStyle(fontSize: 40)),
              const SizedBox(height: 12),
              Text('En attente des transactions des membres...',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center),
            ]))
          : ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _feed.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final ft = _feed[i];
                final isAdd = ft.action == 'add';
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    child: Text(
                      ft.memberName.isNotEmpty
                          ? ft.memberName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context)
                            .colorScheme.onPrimaryContainer),
                    ),
                  ),
                  title: Text(
                    '${ft.memberName} ${isAdd ? 'a ajouté' : 'a supprimé'}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${ft.tx.categoryLabel}'
                    '${ft.tx.note?.isNotEmpty == true ? ' · ${ft.tx.note}' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  trailing: Text(
                    '${ft.tx.isExpense ? '-' : '+'}'
                    '${CurrencyFormatter.formatCompact(ft.tx.amount, symbol)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 14,
                      color: ft.tx.isExpense
                          ? Colors.red.shade600 : Colors.green.shade600),
                  ),
                );
              },
            )),
    ]);
  }

  // ── Actions ────────────────────────────────────────────────────────────────
  Future<void> _createRoom() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Entrez votre prénom.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final code = await FamilyService().createRoom(name);
      if (mounted) {
        setState(() {});
        _showCodeDialog(code);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _joinRoom() async {
    final name = _nameCtrl.text.trim();
    final code = _codeCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Entrez votre prénom.');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = 'Le code doit contenir 6 caractères.');
      return;
    }
    setState(() { _loading = true; _error = null; });
    final err = await FamilyService().joinRoom(code, name);
    if (mounted) {
      if (err != null) {
        setState(() { _error = err; _loading = false; });
      } else {
        setState(() { _loading = false; });
      }
    }
  }

  void _showCodeDialog(String code) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Famille créée ! 🎉'),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Partagez ce code avec vos proches :'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12)),
            child: Text(code,
                style: TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w900,
                  letterSpacing: 8,
                  color: Theme.of(context).colorScheme.onPrimaryContainer)),
          ),
          const SizedBox(height: 12),
          const Text(
            'Ils entrent ce code dans leur application Plume '
            'pour rejoindre votre espace familial.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12),
          ),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: code));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Code copié !')));
            },
            child: const Text('Copier le code'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Super !'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeave() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Quitter la famille ?'),
        content: const Text(
            'Vous ne recevrez plus les transactions des autres membres. '
            'Vos propres données restent sauvegardées.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Quitter'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FamilyService().leaveRoom();
      if (mounted) setState(() {});
    }
  }
}