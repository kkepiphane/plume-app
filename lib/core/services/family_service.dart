// lib/core/services/family_service.dart
//
// Mode famille : partage d'un budget entre 2-5 membres via Supabase.
// Architecture :
//   - 1 "famille" = 1 room_id (UUID partagé)
//   - Chaque membre publie ses transactions sur le canal Realtime
//   - Les transactions des autres s'affichent dans la liste (marquées 👤)
//   - Données locales = seules données persistées (Hive)
//   - Supabase = canal temps réel + table `family_rooms`
//
// Table Supabase à créer (SQL dans les commentaires en bas de fichier)
//
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local_datasource.dart';
import '../../domain/entities/transaction_entity.dart';
import 'auth_service.dart';

class FamilyService {
  static final FamilyService _i = FamilyService._();
  factory FamilyService() => _i;
  FamilyService._();

  static const _roomKey      = 'family_room_id';
  static const _memberKey    = 'family_member_name';
  static const _channelName  = 'plume_family';

  RealtimeChannel? _channel;
  String?          _roomId;
  String?          _memberName;

  // Callbacks for UI
  void Function(FamilyTransaction)? onTransaction;
  void Function(String message)?    onMemberEvent;

  // ── State ──────────────────────────────────────────────────────────────────
  bool   get isInFamily    => _roomId != null;
  String get roomId        => _roomId ?? '';
  String get memberName    => _memberName ?? '';

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _roomId     = prefs.getString(_roomKey);
    _memberName = prefs.getString(_memberKey);
    if (_roomId != null) await _joinChannel(_roomId!);
  }

  // ── Create family room ─────────────────────────────────────────────────────
  /// Creates a new family room and returns the join code (6 chars)
  Future<String> createRoom(String name) async {
    final roomId   = const Uuid().v4();
    final joinCode = roomId.substring(0, 6).toUpperCase();
    _roomId     = roomId;
    _memberName = name;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_roomKey,   roomId);
    await prefs.setString(_memberKey, name);

    // Create room record in Supabase
    try {
      final client = Supabase.instance.client;
      await client.from('family_rooms').insert({
        'id':         roomId,
        'join_code':  joinCode,
        'created_by': AuthService().currentUserId ?? 'anonymous',
        'members':    [name],
      });
    } catch (_) {
      // If Supabase unavailable, still works locally
    }

    await _joinChannel(roomId);
    return joinCode;
  }

  // ── Join existing room ─────────────────────────────────────────────────────
  /// Joins a room by 6-char code. Returns error string or null on success.
  Future<String?> joinRoom(String code, String name) async {
    try {
      final client = Supabase.instance.client;
      final res = await client
          .from('family_rooms')
          .select()
          .eq('join_code', code.toUpperCase())
          .maybeSingle();

      if (res == null) return 'Code de famille introuvable.';

      _roomId     = res['id'] as String;
      _memberName = name;

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_roomKey,   _roomId!);
      await prefs.setString(_memberKey, name);

      // Add member to room
      final members = List<String>.from(res['members'] ?? []);
      if (!members.contains(name)) {
        members.add(name);
        await client.from('family_rooms')
            .update({'members': members})
            .eq('id', _roomId!);
      }

      await _joinChannel(_roomId!);
      return null;
    } on PostgrestException catch (e) {
      return e.message;
    } catch (e) {
      return 'Erreur réseau. Vérifiez votre connexion.';
    }
  }

  // ── Leave room ─────────────────────────────────────────────────────────────
  Future<void> leaveRoom() async {
    await _channel?.unsubscribe();
    _channel    = null;
    _roomId     = null;
    _memberName = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_roomKey);
    await prefs.remove(_memberKey);
  }

  // ── Broadcast a transaction ────────────────────────────────────────────────
  /// Call this after every transaction add/delete to sync with family
  Future<void> broadcastTransaction(
      TransactionEntity tx, String action) async {
    if (!isInFamily || _channel == null) return;
    try {
      await _channel!.sendBroadcastMessage(
        event: 'transaction',
        payload: {
          'action':     action, // 'add' | 'delete'
          'member':     _memberName,
          'transaction': _txToJson(tx),
        },
      );
    } catch (_) { /* offline — no-op */ }
  }

  // ── Private: join realtime channel ────────────────────────────────────────
  Future<void> _joinChannel(String roomId) async {
    await _channel?.unsubscribe();
    final client = Supabase.instance.client;
    _channel = client.channel('$_channelName:$roomId');

    _channel!
      .onBroadcast(
        event: 'transaction',
        callback: (payload) {
          try {
            final member = payload['member'] as String? ?? '?';
            if (member == _memberName) return; // ignore own messages
            final action = payload['action'] as String? ?? 'add';
            final txData = payload['transaction'] as Map<String, dynamic>;
            final tx = _txFromJson(txData);
            final ft = FamilyTransaction(
              tx:         tx,
              memberName: member,
              action:     action,
            );
            onTransaction?.call(ft);
          } catch (_) {}
        },
      )
      .onBroadcast(
        event: 'presence',
        callback: (payload) {
          final member = payload['member'] as String? ?? '?';
          onMemberEvent?.call('$member est en ligne');
        },
      )
      .subscribe();

    // Announce presence
    try {
      await _channel!.sendBroadcastMessage(
        event: 'presence',
        payload: {'member': _memberName},
      );
    } catch (_) {}
  }

  // ── JSON helpers ───────────────────────────────────────────────────────────
  Map<String, dynamic> _txToJson(TransactionEntity tx) => {
    'id':            tx.id,
    'amount':        tx.amount,
    'type':          tx.type.name,
    'categoryLabel': tx.categoryLabel,
    'categoryIcon':  tx.categoryIcon,
    'categoryColor': tx.categoryColor,
    'note':          tx.note,
    'date':          tx.date.toIso8601String(),
  };

  TransactionEntity _txFromJson(Map<String, dynamic> m) => TransactionEntity(
    id:            m['id'] as String,
    amount:        (m['amount'] as num).toDouble(),
    type:          m['type'] == 'expense'
        ? TransactionType.expense : TransactionType.income,
    categoryId:    m['categoryLabel'] as String,
    categoryLabel: m['categoryLabel'] as String,
    categoryIcon:  m['categoryIcon']  as String,
    categoryColor: (m['categoryColor'] as int?) ?? 0xFF607D8B,
    note:          m['note']    as String?,
    date:          DateTime.parse(m['date'] as String),
    createdAt:     DateTime.now(),
  );
}

// ── Family Transaction event ──────────────────────────────────────────────────
class FamilyTransaction {
  final TransactionEntity tx;
  final String            memberName;
  final String            action;   // 'add' | 'delete'
  const FamilyTransaction({
    required this.tx,
    required this.memberName,
    required this.action,
  });
}

/*
══════════════════════════════════════════════════════════════════════
SUPABASE SQL — À exécuter dans Supabase SQL Editor :

create table family_rooms (
  id          uuid primary key,
  join_code   text unique not null,
  created_by  text not null,
  members     text[] not null default '{}',
  created_at  timestamptz default now()
);

-- Enable Row Level Security (anyone with the code can join)
alter table family_rooms enable row level security;

create policy "Read by join_code"
  on family_rooms for select
  using (true);

create policy "Insert own room"
  on family_rooms for insert
  with check (true);

create policy "Update members"
  on family_rooms for update
  using (true);

-- Enable Realtime for channel broadcasts (no table needed)
══════════════════════════════════════════════════════════════════════
*/