import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/category_item.dart';
import '../models/tag_item.dart';
import '../models/transaction_entry.dart';
import 'ledger_repository.dart';

class FirestoreSyncService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final LedgerRepository _repository;
  StreamSubscription<User?>? _authSubscription;
  StreamSubscription? _txnSubscription;
  String? _currentUid;

  FirestoreSyncService(this._repository);

  void init() {
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        _currentUid = user.uid;
        _startSync(user.uid);
      } else {
        _currentUid = null;
        _stopSync();
      }
    });
  }

  void dispose() {
    _authSubscription?.cancel();
    _stopSync();
  }

  void _stopSync() {
    _txnSubscription?.cancel();
    _txnSubscription = null;
  }

  Future<void> _startSync(String uid) async {
    try {
      final userDoc = _firestore.collection('users').doc(uid);

      // 1. Sync User Profile Settings
      await userDoc.set({
        'currency': _repository.settings.currency,
        'weekStartsOn': _repository.settings.weekStartsOn,
        'monthStartDay': _repository.settings.monthStartDay,
        'isVellumTheme': _repository.settings.isVellumTheme,
        'monthlyBudgetPaise': _repository.settings.monthlyBudgetPaise,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // 2. Initial push of local data if Firestore is empty
      final catSnap = await userDoc.collection('categories').limit(1).get();
      if (catSnap.docs.isEmpty) {
        await _pushAllLocalToFirestore(uid);
      } else {
        // Pull remote data and merge
        await _pullRemoteData(uid);
      }

      // 3. Listen for changes from other devices (FR-32)
      _txnSubscription = userDoc
          .collection('transactions')
          .orderBy('updatedAt', descending: true)
          .limit(100)
          .snapshots()
          .listen((snapshot) {
        _handleRemoteTransactionsChange(snapshot);
      });
    } catch (e) {
      debugPrint('FirestoreSyncService: startSync error: $e');
    }
  }

  Future<void> _pushAllLocalToFirestore(String uid) async {
    final batch = _firestore.batch();
    final userDoc = _firestore.collection('users').doc(uid);

    // Push categories
    for (final c in _repository.categories) {
      final docRef = userDoc.collection('categories').doc(c.id);
      batch.set(docRef, {
        'id': c.id,
        'name': c.name,
        'kind': c.kind,
        'iconName': c.iconName,
        'colorToken': c.colorToken,
        'order': c.order,
        'archived': c.archived,
        'createdAt': Timestamp.fromDate(c.createdAt),
      });
    }

    // Push tags
    for (final t in _repository.tags) {
      final docRef = userDoc.collection('tags').doc(t.id);
      batch.set(docRef, {
        'id': t.id,
        'name': t.name,
        'createdAt': Timestamp.fromDate(t.createdAt),
      });
    }

    // Push transactions
    for (final t in _repository.transactions) {
      final docRef = userDoc.collection('transactions').doc(t.id);
      batch.set(docRef, {
        'id': t.id,
        'type': t.type,
        'amountPaise': t.amountPaise,
        'categoryId': t.categoryId,
        'accountId': t.accountId,
        'tagIds': t.tagIds,
        'note': t.note,
        'occurredAt': Timestamp.fromDate(t.occurredAt),
        'dayKey': t.dayKey,
        'weekKey': t.weekKey,
        'monthKey': t.monthKey,
        'yearKey': t.yearKey,
        'createdAt': Timestamp.fromDate(t.createdAt),
        'updatedAt': Timestamp.fromDate(t.updatedAt),
        'deletedAt': t.deletedAt != null ? Timestamp.fromDate(t.deletedAt!) : null,
      });
    }

    // Push summaries
    for (final s in _repository.summaries.values) {
      final docRef = userDoc.collection('summaries').doc(s.monthKey);
      batch.set(docRef, {
        'monthKey': s.monthKey,
        'outPaise': s.outPaise,
        'inPaise': s.inPaise,
        'byCategory': s.byCategory,
        'byDay': s.byDay,
        'updatedAt': Timestamp.fromDate(s.updatedAt),
      });
    }

    await batch.commit();
  }

  Future<void> _pullRemoteData(String uid) async {
    final userDoc = _firestore.collection('users').doc(uid);

    // Categories
    final catSnap = await userDoc.collection('categories').get();
    for (final doc in catSnap.docs) {
      final data = doc.data();
      final cat = CategoryItem(
        id: data['id'] as String? ?? doc.id,
        name: data['name'] as String? ?? 'Unnamed',
        kind: data['kind'] as String? ?? 'expense',
        iconName: data['iconName'] as String? ?? 'category',
        colorToken: data['colorToken'] as String? ?? 'brass',
        order: (data['order'] as num?)?.toInt() ?? 0,
        archived: data['archived'] as bool? ?? false,
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
      if (!_repository.categories.any((c) => c.id == cat.id)) {
        await _repository.updateCategory(cat);
      }
    }

    // Transactions
    final txnSnap = await userDoc.collection('transactions').get();
    for (final doc in txnSnap.docs) {
      final data = doc.data();
      final entry = TransactionEntry(
        id: data['id'] as String? ?? doc.id,
        type: data['type'] as String? ?? 'expense',
        amountPaise: (data['amountPaise'] as num?)?.toInt() ?? 0,
        categoryId: data['categoryId'] as String? ?? '',
        accountId: data['accountId'] as String?,
        tagIds: (data['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
        note: data['note'] as String? ?? '',
        occurredAt: (data['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        dayKey: data['dayKey'] as String? ?? '',
        weekKey: data['weekKey'] as String? ?? '',
        monthKey: data['monthKey'] as String? ?? '',
        yearKey: data['yearKey'] as String? ?? '',
        createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
        isSynced: true,
      );

      final existingIndex = _repository.transactions.indexWhere((t) => t.id == entry.id);
      if (existingIndex == -1) {
        await _repository.updateTransaction(entry);
      }
    }
  }

  void _handleRemoteTransactionsChange(QuerySnapshot snapshot) {
    // Sync remote updates
    for (final change in snapshot.docChanges) {
      if (change.type == DocumentChangeType.added || change.type == DocumentChangeType.modified) {
        final data = change.doc.data() as Map<String, dynamic>?;
        if (data != null) {
          final entry = TransactionEntry(
            id: data['id'] as String? ?? change.doc.id,
            type: data['type'] as String? ?? 'expense',
            amountPaise: (data['amountPaise'] as num?)?.toInt() ?? 0,
            categoryId: data['categoryId'] as String? ?? '',
            accountId: data['accountId'] as String?,
            tagIds: (data['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
            note: data['note'] as String? ?? '',
            occurredAt: (data['occurredAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            dayKey: data['dayKey'] as String? ?? '',
            weekKey: data['weekKey'] as String? ?? '',
            monthKey: data['monthKey'] as String? ?? '',
            yearKey: data['yearKey'] as String? ?? '',
            createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
            deletedAt: (data['deletedAt'] as Timestamp?)?.toDate(),
            isSynced: true,
          );
          _repository.updateTransaction(entry);
        }
      }
    }
  }

  // --- Real-time write hooks ---

  Future<void> syncTransaction(TransactionEntry entry) async {
    if (_currentUid == null) return;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('transactions')
          .doc(entry.id);

      await docRef.set({
        'id': entry.id,
        'type': entry.type,
        'amountPaise': entry.amountPaise,
        'categoryId': entry.categoryId,
        'accountId': entry.accountId,
        'tagIds': entry.tagIds,
        'note': entry.note,
        'occurredAt': Timestamp.fromDate(entry.occurredAt),
        'dayKey': entry.dayKey,
        'weekKey': entry.weekKey,
        'monthKey': entry.monthKey,
        'yearKey': entry.yearKey,
        'createdAt': Timestamp.fromDate(entry.createdAt),
        'updatedAt': Timestamp.fromDate(entry.updatedAt),
        'deletedAt': entry.deletedAt != null ? Timestamp.fromDate(entry.deletedAt!) : null,
      }, SetOptions(merge: true));

      // Also update summary in Firestore using WriteBatch
      await _syncMonthSummary(entry.monthKey);
    } catch (e) {
      debugPrint('FirestoreSync: syncTransaction note: $e');
    }
  }

  Future<void> _syncMonthSummary(String monthKey) async {
    if (_currentUid == null) return;
    final summary = _repository.summaries[monthKey];
    if (summary == null) return;

    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('summaries')
          .doc(monthKey);

      await docRef.set({
        'monthKey': summary.monthKey,
        'outPaise': summary.outPaise,
        'inPaise': summary.inPaise,
        'byCategory': summary.byCategory,
        'byDay': summary.byDay,
        'updatedAt': Timestamp.fromDate(summary.updatedAt),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSync: syncMonthSummary note: $e');
    }
  }

  Future<void> syncCategory(CategoryItem category) async {
    if (_currentUid == null) return;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('categories')
          .doc(category.id);

      await docRef.set({
        'id': category.id,
        'name': category.name,
        'kind': category.kind,
        'iconName': category.iconName,
        'colorToken': category.colorToken,
        'order': category.order,
        'archived': category.archived,
        'createdAt': Timestamp.fromDate(category.createdAt),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSync: syncCategory note: $e');
    }
  }

  Future<void> syncTag(TagItem tag) async {
    if (_currentUid == null) return;
    try {
      final docRef = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('tags')
          .doc(tag.id);

      await docRef.set({
        'id': tag.id,
        'name': tag.name,
        'createdAt': Timestamp.fromDate(tag.createdAt),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirestoreSync: syncTag note: $e');
    }
  }
}
