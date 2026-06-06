import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/json_formatter.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/method_badge.dart';
import '../../requests/providers/request_provider.dart';
import '../../requests/providers/tab_provider.dart';
import '../models/history_entry.dart';
import '../providers/history_provider.dart';

class HistoryPanel extends ConsumerWidget {
  const HistoryPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(filteredHistoryProvider);
    final searchQuery = ref.watch(historySearchProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Row(
            children: [
              Text(
                'History',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (history.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_sweep, size: 18),
                  tooltip: 'Clear history',
                  onPressed: () => _confirmClear(context, ref),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
            ],
          ),
        ),
        // Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search history...',
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(100)),
              prefixIcon: Icon(Icons.search,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(120)),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
            ),
            style: const TextStyle(fontSize: 12),
            onChanged: (v) =>
                ref.read(historySearchProvider.notifier).state = v,
          ),
        ),
        // List
        Expanded(
          child: history.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.history,
                  title: searchQuery.isNotEmpty
                      ? 'No results'
                      : 'No history yet',
                  subtitle: searchQuery.isNotEmpty
                      ? null
                      : 'Your request history will appear here.',
                )
              : ListView.separated(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: history.length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 1, color: theme.dividerColor.withAlpha(60)),
                  itemBuilder: (ctx, i) => _HistoryTile(
                    entry: history[i],
                    onTap: () => ref
                        .read(requestExecutorProvider)
                        .sendHistoryRequest(history[i].request),
                    onOpen: () => ref
                        .read(tabProvider.notifier)
                        .openRequestInTab(history[i].request),
                    onDelete: () => ref
                        .read(historyProvider.notifier)
                        .deleteEntry(history[i].id),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('This will delete all history entries.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      ref.read(historyProvider.notifier).clearAll();
    }
  }
}

class _HistoryTile extends StatelessWidget {
  final HistoryEntry entry;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onDelete;

  const _HistoryTile({
    required this.entry,
    required this.onTap,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final response = entry.response;
    final fmt = DateFormat('HH:mm:ss');

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MethodBadge(method: entry.request.method, fontSize: 9),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.request.url,
                    style: const TextStyle(
                        fontSize: 11, fontFamily: 'RobotoMono'),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (entry.isError) ...[
                        Icon(Icons.error_outline,
                            size: 11, color: theme.colorScheme.error),
                        const SizedBox(width: 3),
                        Text(
                          'Error',
                          style: TextStyle(
                              fontSize: 10, color: theme.colorScheme.error),
                        ),
                      ] else if (response != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.statusColor(response.statusCode)
                                .withAlpha(30),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${response.statusCode}',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.statusColor(response.statusCode),
                              fontWeight: FontWeight.w700,
                              fontFamily: 'RobotoMono',
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          JsonFormatter.formatDuration(response.duration),
                          style: TextStyle(
                            fontSize: 10,
                            color: theme.colorScheme.onSurface.withAlpha(120),
                            fontFamily: 'RobotoMono',
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        fmt.format(entry.executedAt),
                        style: TextStyle(
                          fontSize: 10,
                          color: theme.colorScheme.onSurface.withAlpha(100),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert,
                  size: 14,
                  color: theme.colorScheme.onSurface.withAlpha(100)),
              padding: EdgeInsets.zero,
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'open', child: Text('Open in tab')),
                const PopupMenuItem(
                    value: 'retry', child: Text('Retry')),
                const PopupMenuItem(
                    value: 'delete', child: Text('Delete')),
              ],
              onSelected: (v) {
                if (v == 'open') onOpen();
                if (v == 'retry') onTap();
                if (v == 'delete') onDelete();
              },
            ),
          ],
        ),
      ),
    );
  }
}
