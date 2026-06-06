import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../services/storage/hive_service.dart';
import '../models/api_request.dart';
import '../models/api_response.dart';
import '../models/request_tab.dart';

class TabState {
  final List<RequestTab> tabs;
  final int activeIndex;

  const TabState({
    this.tabs = const [],
    this.activeIndex = 0,
  });

  RequestTab? get activeTab =>
      tabs.isEmpty ? null : tabs[activeIndex.clamp(0, tabs.length - 1)];

  int get clampedIndex => activeIndex.clamp(0, (tabs.length - 1).clamp(0, 999));

  TabState copyWith({
    List<RequestTab>? tabs,
    int? activeIndex,
  }) =>
      TabState(
        tabs: tabs ?? this.tabs,
        activeIndex: activeIndex ?? this.activeIndex,
      );
}

class TabNotifier extends StateNotifier<TabState> {
  TabNotifier() : super(const TabState()) {
    _load();
  }

  void _load() {
    var tabs = HiveService.getTabs();
    if (tabs.isEmpty) {
      tabs = [RequestTab()];
    }
    final savedId = HiveService.getActiveTabId();
    int activeIndex = 0;
    if (savedId != null) {
      final idx = tabs.indexWhere((t) => t.id == savedId);
      if (idx >= 0) activeIndex = idx;
    }
    state = TabState(tabs: tabs, activeIndex: activeIndex);
  }

  void addTab({ApiRequest? request}) {
    if (state.tabs.length >= AppConstants.maxTabs) return;
    final newTab = RequestTab(request: request);
    final newTabs = [...state.tabs, newTab];
    state = state.copyWith(tabs: newTabs, activeIndex: newTabs.length - 1);
    _persist();
  }

  void closeTab(int index) {
    if (state.tabs.length <= 1) {
      // Reset to empty instead of closing the last tab
      final reset = RequestTab();
      state = state.copyWith(tabs: [reset], activeIndex: 0);
      _persist();
      return;
    }
    final newTabs = List<RequestTab>.from(state.tabs)..removeAt(index);
    final newIndex = (index >= newTabs.length)
        ? newTabs.length - 1
        : index;
    state = state.copyWith(tabs: newTabs, activeIndex: newIndex);
    _persist();
  }

  void setActiveTab(int index) {
    if (index < 0 || index >= state.tabs.length) return;
    state = state.copyWith(activeIndex: index);
    HiveService.saveActiveTabId(state.tabs[index].id);
  }

  void updateActiveRequest(ApiRequest request) {
    _updateTab(state.clampedIndex, (t) => t.copyWith(request: request));
  }

  void setTabLoading(int index) {
    _updateTab(index, (t) => t.copyWith(
          status: TabStatus.loading,
          clearResponse: true,
          clearError: true,
        ));
  }

  void setTabResponse(int index, ApiResponse response) {
    _updateTab(index, (t) => t.copyWith(
          response: response,
          status: TabStatus.success,
          clearError: true,
        ));
  }

  void setTabError(int index, String error) {
    _updateTab(index, (t) => t.copyWith(
          status: TabStatus.error,
          errorMessage: error,
          clearResponse: true,
        ));
  }

  void duplicateTab(int index) {
    if (state.tabs.length >= AppConstants.maxTabs) return;
    final original = state.tabs[index];
    // Duplicate with a brand-new ID by round-tripping through JSON
    final duplicateRequest = ApiRequest.fromJson(
      {...original.request.toJson(), 'id': null},
    );
    final duplicate = RequestTab(request: duplicateRequest);
    final newTabs = List<RequestTab>.from(state.tabs)
      ..insert(index + 1, duplicate);
    state = state.copyWith(tabs: newTabs, activeIndex: index + 1);
    _persist();
  }

  void openRequestInTab(ApiRequest request) {
    // Check if already open
    final existingIdx = state.tabs
        .indexWhere((t) => t.request.id == request.id);
    if (existingIdx >= 0) {
      setActiveTab(existingIdx);
      return;
    }
    addTab(request: request);
  }

  void _updateTab(int index, RequestTab Function(RequestTab) update) {
    if (index < 0 || index >= state.tabs.length) return;
    final newTabs = List<RequestTab>.from(state.tabs);
    newTabs[index] = update(newTabs[index]);
    state = state.copyWith(tabs: newTabs);
    _persist();
  }

  void _persist() {
    HiveService.saveTabs(state.tabs);
    if (state.tabs.isNotEmpty) {
      HiveService.saveActiveTabId(
          state.tabs[state.clampedIndex].id);
    }
  }
}

final tabProvider =
    StateNotifierProvider<TabNotifier, TabState>((ref) => TabNotifier());

final activeTabProvider = Provider<RequestTab?>((ref) {
  return ref.watch(tabProvider).activeTab;
});
