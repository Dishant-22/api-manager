import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/json_formatter.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/json_viewer.dart';
import '../../../shared/widgets/method_badge.dart';
import '../models/request_tab.dart';
import '../providers/tab_provider.dart';

class ResponsePanel extends ConsumerWidget {
  final int tabIndex;
  const ResponsePanel({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();
    final tab = tabState.tabs[tabIndex];

    switch (tab.status) {
      case TabStatus.idle:
        return const _IdleState();
      case TabStatus.loading:
        return const _LoadingState();
      case TabStatus.error:
        return _ErrorState(message: tab.errorMessage ?? 'Unknown error');
      case TabStatus.success:
        if (tab.response == null) return const _IdleState();
        return _ResponseContent(tab: tab);
    }
  }
}

class _IdleState extends StatelessWidget {
  const _IdleState();

  @override
  Widget build(BuildContext context) {
    return const EmptyStateWidget(
      icon: Icons.send_outlined,
      title: 'Send a request',
      subtitle: 'Enter a URL and press Send to see the response here.',
    );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Sending request...'),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  const _ErrorState({required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline,
                size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(
              'Request Failed',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                message,
                style: TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 12,
                  color: theme.colorScheme.onErrorContainer,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResponseContent extends StatefulWidget {
  final RequestTab tab;
  const _ResponseContent({required this.tab});

  @override
  State<_ResponseContent> createState() => _ResponseContentState();
}

class _ResponseContentState extends State<_ResponseContent>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final response = widget.tab.response!;
    final theme = Theme.of(context);

    return Column(
      children: [
        // Status bar
        _ResponseStatusBar(tab: widget.tab),
        // Tab bar
        TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Body', height: 36),
            Tab(text: 'Headers', height: 36),
          ],
          labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerHeight: 0,
        ),
        Divider(height: 1, color: theme.dividerColor),
        // Content
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              ResponseBodyViewer(
                body: response.body,
                contentType: response.contentType,
              ),
              _ResponseHeadersView(headers: response.headers),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResponseStatusBar extends StatelessWidget {
  final RequestTab tab;
  const _ResponseStatusBar({required this.tab});

  @override
  Widget build(BuildContext context) {
    final response = tab.response!;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          StatusCodeBadge(statusCode: response.statusCode),
          const SizedBox(width: 8),
          Text(
            response.statusMessage,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.statusColor(response.statusCode),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(width: 16),
          _StatChip(
            icon: Icons.timer_outlined,
            label: JsonFormatter.formatDuration(response.duration),
          ),
          const SizedBox(width: 8),
          _StatChip(
            icon: Icons.data_usage,
            label: JsonFormatter.formatBytes(response.sizeBytes),
          ),
          const Spacer(),
          MethodBadge(method: tab.request.method),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _StatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13,
            color: theme.colorScheme.onSurface.withAlpha(120)),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: theme.colorScheme.onSurface.withAlpha(160),
            fontFamily: 'RobotoMono',
          ),
        ),
      ],
    );
  }
}

class _ResponseHeadersView extends StatelessWidget {
  final Map<String, String> headers;
  const _ResponseHeadersView({required this.headers});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final entries = headers.entries.toList();

    if (entries.isEmpty) {
      return const EmptyStateWidget(
        icon: Icons.table_rows_outlined,
        title: 'No headers',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      separatorBuilder: (_, __) =>
          Divider(height: 1, color: theme.dividerColor.withAlpha(60)),
      itemBuilder: (ctx, i) {
        final entry = entries[i];
        return Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 180,
                child: Text(
                  entry.key,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.primary,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.value,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'RobotoMono',
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
