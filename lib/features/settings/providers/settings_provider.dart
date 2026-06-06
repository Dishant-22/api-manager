import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../models/app_settings.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeIndex = prefs.getInt(StorageKeys.themeMode) ?? 0;
    state = AppSettings(
      themeMode: ThemeMode.values[themeModeIndex],
      requestTimeoutSeconds:
          prefs.getInt(StorageKeys.requestTimeout) ?? 30,
      followRedirects: prefs.getBool(StorageKeys.followRedirects) ?? true,
      verifySsl: prefs.getBool(StorageKeys.verifySsl) ?? true,
      sidebarWidth: prefs.getDouble(StorageKeys.sidebarWidth) ?? 260.0,
      isSidebarVisible: prefs.getBool(StorageKeys.isSidebarVisible) ?? true,
      activeEnvironmentId: prefs.getString(StorageKeys.activeEnvironmentId),
      activeWorkspaceId: prefs.getString(StorageKeys.activeWorkspaceId),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.themeMode, mode.index);
  }

  Future<void> setRequestTimeout(int seconds) async {
    state = state.copyWith(requestTimeoutSeconds: seconds);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(StorageKeys.requestTimeout, seconds);
  }

  Future<void> setFollowRedirects(bool value) async {
    state = state.copyWith(followRedirects: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.followRedirects, value);
  }

  Future<void> setVerifySsl(bool value) async {
    state = state.copyWith(verifySsl: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.verifySsl, value);
  }

  Future<void> setSidebarWidth(double width) async {
    state = state.copyWith(sidebarWidth: width);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(StorageKeys.sidebarWidth, width);
  }

  Future<void> setSidebarVisible(bool visible) async {
    state = state.copyWith(isSidebarVisible: visible);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(StorageKeys.isSidebarVisible, visible);
  }

  Future<void> setActiveEnvironment(String? id) async {
    if (id == null) {
      state = state.copyWith(clearActiveEnvironment: true);
    } else {
      state = state.copyWith(activeEnvironmentId: id);
    }
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(StorageKeys.activeEnvironmentId);
    } else {
      await prefs.setString(StorageKeys.activeEnvironmentId, id);
    }
  }

  Future<void> setActiveWorkspace(String id) async {
    state = state.copyWith(activeWorkspaceId: id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.activeWorkspaceId, id);
  }

  Future<void> setAutoSaveHistory(bool value) async {
    state = state.copyWith(autoSaveHistory: value);
  }

  void toggleSidebar() {
    state = state.copyWith(isSidebarVisible: !state.isSidebarVisible);
    SharedPreferences.getInstance().then(
      (p) => p.setBool(StorageKeys.isSidebarVisible, state.isSidebarVisible),
    );
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});
