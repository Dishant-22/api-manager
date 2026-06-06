import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../core/constants/storage_keys.dart';
import '../../core/errors/app_exception.dart';
import '../../features/collections/models/collection.dart';
import '../../features/environments/models/environment.dart';
import '../../features/history/models/history_entry.dart';
import '../../features/requests/models/request_tab.dart';
import '../../features/workspaces/models/workspace.dart';

class HiveService {
  static late Box<String> _collectionsBox;
  static late Box<String> _environmentsBox;
  static late Box<String> _historyBox;
  static late Box<String> _tabsBox;
  static late Box<String> _workspacesBox;

  static Future<void> initialize() async {
    await Hive.initFlutter();
    _collectionsBox = await Hive.openBox<String>(StorageKeys.collectionsBox);
    _environmentsBox = await Hive.openBox<String>(StorageKeys.environmentsBox);
    _historyBox = await Hive.openBox<String>(StorageKeys.historyBox);
    _tabsBox = await Hive.openBox<String>(StorageKeys.tabsBox);
    _workspacesBox = await Hive.openBox<String>(StorageKeys.workspacesBox);
  }

  // ─── Collections ──────────────────────────────────────────────────────────

  static List<Collection> getCollections() {
    try {
      final raw = _collectionsBox.get(StorageKeys.collectionsKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Collection.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveCollections(List<Collection> collections) async {
    try {
      final encoded = json.encode(collections.map((c) => c.toJson()).toList());
      await _collectionsBox.put(StorageKeys.collectionsKey, encoded);
    } catch (e) {
      throw StorageException(message: 'Failed to save collections: $e');
    }
  }

  // ─── Environments ─────────────────────────────────────────────────────────

  static List<Environment> getEnvironments() {
    try {
      final raw = _environmentsBox.get(StorageKeys.environmentsKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Environment.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveEnvironments(List<Environment> environments) async {
    try {
      final encoded =
          json.encode(environments.map((e) => e.toJson()).toList());
      await _environmentsBox.put(StorageKeys.environmentsKey, encoded);
    } catch (e) {
      throw StorageException(message: 'Failed to save environments: $e');
    }
  }

  // ─── History ──────────────────────────────────────────────────────────────

  static List<HistoryEntry> getHistory() {
    try {
      final raw = _historyBox.get(StorageKeys.historyKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => HistoryEntry.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveHistory(List<HistoryEntry> history) async {
    try {
      final encoded = json.encode(history.map((e) => e.toJson()).toList());
      await _historyBox.put(StorageKeys.historyKey, encoded);
    } catch (e) {
      throw StorageException(message: 'Failed to save history: $e');
    }
  }

  // ─── Tabs ─────────────────────────────────────────────────────────────────

  static List<RequestTab> getTabs() {
    try {
      final raw = _tabsBox.get(StorageKeys.tabsKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => RequestTab.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveTabs(List<RequestTab> tabs) async {
    try {
      final encoded = json.encode(tabs.map((t) => t.toJson()).toList());
      await _tabsBox.put(StorageKeys.tabsKey, encoded);
    } catch (e) {
      throw StorageException(message: 'Failed to save tabs: $e');
    }
  }

  static String? getActiveTabId() {
    return _tabsBox.get(StorageKeys.activeTabKey);
  }

  static Future<void> saveActiveTabId(String tabId) async {
    await _tabsBox.put(StorageKeys.activeTabKey, tabId);
  }

  // ─── Workspaces ───────────────────────────────────────────────────────────

  static List<Workspace> getWorkspaces() {
    try {
      final raw = _workspacesBox.get(StorageKeys.workspacesKey);
      if (raw == null) return [];
      final list = json.decode(raw) as List<dynamic>;
      return list
          .map((e) => Workspace.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> saveWorkspaces(List<Workspace> workspaces) async {
    try {
      final encoded =
          json.encode(workspaces.map((w) => w.toJson()).toList());
      await _workspacesBox.put(StorageKeys.workspacesKey, encoded);
    } catch (e) {
      throw StorageException(message: 'Failed to save workspaces: $e');
    }
  }

  static String? getActiveWorkspaceId() {
    return _workspacesBox.get(StorageKeys.activeWorkspaceKey);
  }

  static Future<void> saveActiveWorkspaceId(String id) async {
    await _workspacesBox.put(StorageKeys.activeWorkspaceKey, id);
  }
}
