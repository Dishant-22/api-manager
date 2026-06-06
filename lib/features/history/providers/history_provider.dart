import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/hive_service.dart';
import '../models/history_entry.dart';
import '../../requests/models/api_request.dart';
import '../../requests/models/api_response.dart';

class HistoryNotifier extends StateNotifier<List<HistoryEntry>> {
  HistoryNotifier() : super([]) {
    _load();
  }

  void _load() {
    state = HiveService.getHistory();
  }

  Future<void> addEntry({
    required ApiRequest request,
    ApiResponse? response,
    bool isError = false,
    String? errorMessage,
  }) async {
    final entry = HistoryEntry(
      request: request,
      response: response,
      isError: isError,
      errorMessage: errorMessage,
    );
    var updated = [entry, ...state];
    if (updated.length > AppConstants.maxHistoryEntries) {
      updated = updated.take(AppConstants.maxHistoryEntries).toList();
    }
    state = updated;
    await HiveService.saveHistory(state);
  }

  Future<void> deleteEntry(String id) async {
    state = state.where((e) => e.id != id).toList();
    await HiveService.saveHistory(state);
  }

  Future<void> clearAll() async {
    state = [];
    await HiveService.saveHistory(state);
  }

  List<HistoryEntry> search(String query) {
    if (query.isEmpty) return state;
    final lower = query.toLowerCase();
    return state.where((e) {
      return e.request.url.toLowerCase().contains(lower) ||
          e.request.method.toLowerCase().contains(lower) ||
          e.request.name.toLowerCase().contains(lower);
    }).toList();
  }
}

final historyProvider =
    StateNotifierProvider<HistoryNotifier, List<HistoryEntry>>((ref) {
  return HistoryNotifier();
});

final historySearchProvider = StateProvider<String>((ref) => '');

final filteredHistoryProvider = Provider<List<HistoryEntry>>((ref) {
  final history = ref.watch(historyProvider);
  final query = ref.watch(historySearchProvider);
  if (query.isEmpty) return history;
  final lower = query.toLowerCase();
  return history.where((e) {
    return e.request.url.toLowerCase().contains(lower) ||
        e.request.method.toLowerCase().contains(lower) ||
        e.request.name.toLowerCase().contains(lower);
  }).toList();
});
