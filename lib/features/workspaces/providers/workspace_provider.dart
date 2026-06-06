import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/storage/hive_service.dart';
import '../models/workspace.dart';

class WorkspaceNotifier extends StateNotifier<List<Workspace>> {
  WorkspaceNotifier() : super([]) {
    _load();
  }

  void _load() {
    var workspaces = HiveService.getWorkspaces();
    if (workspaces.isEmpty) {
      final defaultWs = Workspace(
        name: 'My Workspace',
        description: 'Default workspace',
      );
      workspaces = [defaultWs];
      HiveService.saveWorkspaces(workspaces);
      HiveService.saveActiveWorkspaceId(defaultWs.id);
    }
    state = workspaces;
  }

  Future<void> addWorkspace(Workspace workspace) async {
    state = [...state, workspace];
    await HiveService.saveWorkspaces(state);
  }

  Future<void> updateWorkspace(Workspace workspace) async {
    state = state.map((w) => w.id == workspace.id ? workspace : w).toList();
    await HiveService.saveWorkspaces(state);
  }

  Future<void> deleteWorkspace(String id) async {
    state = state.where((w) => w.id != id).toList();
    await HiveService.saveWorkspaces(state);
  }
}

final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, List<Workspace>>((ref) {
  return WorkspaceNotifier();
});
