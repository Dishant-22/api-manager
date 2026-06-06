import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../services/http/dio_client.dart';
import '../../../core/errors/app_exception.dart';
import '../../environments/providers/environment_provider.dart';
import '../../history/providers/history_provider.dart';
import '../../settings/providers/settings_provider.dart';
import '../models/api_request.dart';
import 'tab_provider.dart';
import 'package:dio/dio.dart';

class RequestExecutor {
  final Ref _ref;
  final Map<String, CancelToken> _cancelTokens = {};

  RequestExecutor(this._ref);

  Future<void> sendRequest(int tabIndex) async {
    final tabState = _ref.read(tabProvider);
    if (tabIndex < 0 || tabIndex >= tabState.tabs.length) return;

    final tab = tabState.tabs[tabIndex];
    final request = tab.request;

    if (request.url.isEmpty) return;

    // Cancel any existing request for this tab
    cancelRequest(tabIndex);
    final cancelToken = CancelToken();
    _cancelTokens[tab.id] = cancelToken;

    final tabNotifier = _ref.read(tabProvider.notifier);
    tabNotifier.setTabLoading(tabIndex);

    final settings = _ref.read(settingsProvider);
    final resolvedVars = _ref.read(resolvedVariablesProvider);

    try {
      final response = await DioClient.execute(
        request: request,
        resolvedVariables: resolvedVars,
        timeoutSeconds: settings.requestTimeoutSeconds,
        followRedirects: settings.followRedirects,
        verifySsl: settings.verifySsl,
        cancelToken: cancelToken,
      );

      _cancelTokens.remove(tab.id);
      tabNotifier.setTabResponse(tabIndex, response);

      if (settings.autoSaveHistory) {
        await _ref.read(historyProvider.notifier).addEntry(
              request: request,
              response: response,
            );
      }
    } on CancelException {
      _cancelTokens.remove(tab.id);
      tabNotifier.setTabError(tabIndex, 'Request cancelled');
    } on TimeoutException catch (e) {
      _cancelTokens.remove(tab.id);
      tabNotifier.setTabError(tabIndex, e.message);
      if (settings.autoSaveHistory) {
        await _ref.read(historyProvider.notifier).addEntry(
              request: request,
              isError: true,
              errorMessage: e.message,
            );
      }
    } on AppException catch (e) {
      _cancelTokens.remove(tab.id);
      tabNotifier.setTabError(tabIndex, e.message);
      if (settings.autoSaveHistory) {
        await _ref.read(historyProvider.notifier).addEntry(
              request: request,
              isError: true,
              errorMessage: e.message,
            );
      }
    } catch (e) {
      _cancelTokens.remove(tab.id);
      tabNotifier.setTabError(tabIndex, e.toString());
    }
  }

  void cancelRequest(int tabIndex) {
    final tabState = _ref.read(tabProvider);
    if (tabIndex < 0 || tabIndex >= tabState.tabs.length) return;
    final tabId = tabState.tabs[tabIndex].id;
    _cancelTokens[tabId]?.cancel('User cancelled');
    _cancelTokens.remove(tabId);
  }

  Future<void> sendHistoryRequest(ApiRequest request) async {
    final tabNotifier = _ref.read(tabProvider.notifier);
    tabNotifier.openRequestInTab(request);
    // A small delay to let the tab open and get its index
    await Future<void>.delayed(const Duration(milliseconds: 50));
    final tabState = _ref.read(tabProvider);
    final idx = tabState.tabs.indexWhere((t) => t.request.id == request.id);
    if (idx >= 0) await sendRequest(idx);
  }
}

final requestExecutorProvider = Provider<RequestExecutor>((ref) {
  return RequestExecutor(ref);
});
