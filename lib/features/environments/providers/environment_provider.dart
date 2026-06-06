import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../services/storage/hive_service.dart';
import '../models/environment.dart';

class EnvironmentState {
  final List<Environment> environments;
  final String? activeEnvironmentId;

  const EnvironmentState({
    this.environments = const [],
    this.activeEnvironmentId,
  });

  Environment? get activeEnvironment => activeEnvironmentId == null
      ? null
      : environments.where((e) => e.id == activeEnvironmentId).firstOrNull;

  Map<String, String> get resolvedVariables {
    final globalEnv = environments.where((e) => e.isGlobal).firstOrNull;
    final activeEnv = activeEnvironment;
    return {
      if (globalEnv != null) ...globalEnv.resolvedVariables,
      if (activeEnv != null) ...activeEnv.resolvedVariables,
    };
  }

  EnvironmentState copyWith({
    List<Environment>? environments,
    String? activeEnvironmentId,
    bool clearActive = false,
  }) =>
      EnvironmentState(
        environments: environments ?? this.environments,
        activeEnvironmentId:
            clearActive ? null : (activeEnvironmentId ?? this.activeEnvironmentId),
      );
}

class EnvironmentNotifier extends StateNotifier<EnvironmentState> {
  EnvironmentNotifier() : super(const EnvironmentState()) {
    _load();
  }

  Future<void> _load() async {
    var environments = HiveService.getEnvironments();
    if (environments.isEmpty) {
      environments = [
        Environment(name: 'Global', isGlobal: true),
        Environment(name: 'Development', variables: [
          const EnvVariable(id: '1', key: 'baseUrl', value: 'https://api.example.com'),
          const EnvVariable(id: '2', key: 'apiKey', value: 'dev_api_key_here'),
        ]),
        Environment(name: 'Production', variables: [
          const EnvVariable(id: '3', key: 'baseUrl', value: 'https://api.production.com'),
          const EnvVariable(id: '4', key: 'apiKey', value: 'prod_api_key_here'),
        ]),
      ];
      await HiveService.saveEnvironments(environments);
    }

    // Restore the previously active environment from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final savedActiveId = prefs.getString(StorageKeys.activeEnvironmentId);

    // Validate: the saved ID must still exist in the environment list
    final validActiveId = savedActiveId != null &&
            environments.any((e) => e.id == savedActiveId)
        ? savedActiveId
        : null;

    state = EnvironmentState(
      environments: environments,
      activeEnvironmentId: validActiveId,
    );
  }

  Future<void> addEnvironment(Environment env) async {
    final updated = [...state.environments, env];
    state = state.copyWith(environments: updated);
    await HiveService.saveEnvironments(updated);
  }

  Future<void> updateEnvironment(Environment env) async {
    final updated = state.environments
        .map((e) => e.id == env.id ? env : e)
        .toList();
    state = state.copyWith(environments: updated);
    await HiveService.saveEnvironments(updated);
  }

  Future<void> deleteEnvironment(String id) async {
    final updated = state.environments.where((e) => e.id != id).toList();
    final clearActive = state.activeEnvironmentId == id;
    state = state.copyWith(
      environments: updated,
      clearActive: clearActive,
    );
    await HiveService.saveEnvironments(updated);
    if (clearActive) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.activeEnvironmentId);
    }
  }

  Future<void> setActiveEnvironment(String? id) async {
    state = state.copyWith(
      activeEnvironmentId: id,
      clearActive: id == null,
    );
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(StorageKeys.activeEnvironmentId);
    } else {
      await prefs.setString(StorageKeys.activeEnvironmentId, id);
    }
  }
}

final environmentProvider =
    StateNotifierProvider<EnvironmentNotifier, EnvironmentState>((ref) {
  return EnvironmentNotifier();
});

final activeEnvironmentProvider = Provider<Environment?>((ref) {
  return ref.watch(environmentProvider).activeEnvironment;
});

final resolvedVariablesProvider = Provider<Map<String, String>>((ref) {
  return ref.watch(environmentProvider).resolvedVariables;
});

/// Tracks which environment is currently open in the Environments screen.
/// Stored in a provider so it survives screen pops and re-pushes.
final selectedEnvIdProvider = StateProvider<String?>((ref) => null);
