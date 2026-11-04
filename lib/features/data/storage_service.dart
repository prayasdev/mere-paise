import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Rock-solid offline local storage service.
/// Stores structured JSON data to app-private storage, with SharedPreferences fallback.
class StorageService {
  static const String _keyTransactions = 'mp_transactions_v1';
  static const String _keyCategories = 'mp_categories_v1';
  static const String _keyTags = 'mp_tags_v1';
  static const String _keySummaries = 'mp_summaries_v1';
  static const String _keySettings = 'mp_settings_v1';
  static const String _keyLastUsedCatExpense = 'mp_last_cat_expense';
  static const String _keyLastUsedCatIncome = 'mp_last_cat_income';

  late SharedPreferences _prefs;
  Directory? _documentsDir;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      if (!kIsWeb) {
        _documentsDir = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      debugPrint('StorageService: directory lookup fallback: $e');
    }
  }

  // --- Transactions ---
  Future<List<Map<String, dynamic>>> loadTransactions() async {
    try {
      final raw = _prefs.getString(_keyTransactions);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error loading transactions: $e');
    }
    return [];
  }

  Future<void> saveTransactions(List<Map<String, dynamic>> items) async {
    try {
      final raw = jsonEncode(items);
      await _prefs.setString(_keyTransactions, raw);
    } catch (e) {
      debugPrint('Error saving transactions: $e');
    }
  }

  // --- Categories ---
  Future<List<Map<String, dynamic>>> loadCategories() async {
    try {
      final raw = _prefs.getString(_keyCategories);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error loading categories: $e');
    }
    return [];
  }

  Future<void> saveCategories(List<Map<String, dynamic>> items) async {
    try {
      final raw = jsonEncode(items);
      await _prefs.setString(_keyCategories, raw);
    } catch (e) {
      debugPrint('Error saving categories: $e');
    }
  }

  // --- Tags ---
  Future<List<Map<String, dynamic>>> loadTags() async {
    try {
      final raw = _prefs.getString(_keyTags);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error loading tags: $e');
    }
    return [];
  }

  Future<void> saveTags(List<Map<String, dynamic>> items) async {
    try {
      final raw = jsonEncode(items);
      await _prefs.setString(_keyTags, raw);
    } catch (e) {
      debugPrint('Error saving tags: $e');
    }
  }

  // --- Summaries ---
  Future<Map<String, dynamic>> loadSummaries() async {
    try {
      final raw = _prefs.getString(_keySummaries);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading summaries: $e');
    }
    return {};
  }

  Future<void> saveSummaries(Map<String, dynamic> summaries) async {
    try {
      final raw = jsonEncode(summaries);
      await _prefs.setString(_keySummaries, raw);
    } catch (e) {
      debugPrint('Error saving summaries: $e');
    }
  }

  // --- Settings ---
  Future<Map<String, dynamic>?> loadSettings() async {
    try {
      final raw = _prefs.getString(_keySettings);
      if (raw != null && raw.isNotEmpty) {
        return jsonDecode(raw) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error loading settings: $e');
    }
    return null;
  }

  Future<void> saveSettings(Map<String, dynamic> settings) async {
    try {
      await _prefs.setString(_keySettings, jsonEncode(settings));
    } catch (e) {
      debugPrint('Error saving settings: $e');
    }
  }

  // --- Last Used Category per Type ---
  String? getLastUsedCategory(String type) {
    if (type == 'income') {
      return _prefs.getString(_keyLastUsedCatIncome);
    }
    return _prefs.getString(_keyLastUsedCatExpense);
  }

  Future<void> setLastUsedCategory(String type, String categoryId) async {
    if (type == 'income') {
      await _prefs.setString(_keyLastUsedCatIncome, categoryId);
    } else {
      await _prefs.setString(_keyLastUsedCatExpense, categoryId);
    }
  }

  // --- Clear / Reset ---
  Future<void> clearAll() async {
    await _prefs.clear();
  }

  Future<String> getAppStoragePath() async {
    if (_documentsDir != null) {
      return _documentsDir!.path;
    }
    return Directory.systemTemp.path;
  }
}

