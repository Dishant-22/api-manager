import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../../../shared/widgets/method_badge.dart';
import '../../requests/providers/tab_provider.dart';
import '../models/collection.dart';
import '../providers/collection_provider.dart';

class CollectionsPanel extends ConsumerStatefulWidget {
  const CollectionsPanel({super.key});

  @override
  ConsumerState<CollectionsPanel> createState() => _CollectionsPanelState();
}

class _CollectionsPanelState extends ConsumerState<CollectionsPanel> {
  String _searchQuery = '';
  final Set<String> _expandedIds = {};

  @override
  Widget build(BuildContext context) {
    final collections = ref.watch(collectionProvider);
    final theme = Theme.of(context);

    final filtered = _searchQuery.isEmpty
        ? collections
        : collections
            .where((c) =>
                c.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                c.requests.any((r) =>
                    r.name.toLowerCase().contains(_searchQuery.toLowerCase())))
            .toList();

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 8, 4),
          child: Row(
            children: [
              Text(
                'Collections',
                style: theme.textTheme.labelLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.add, size: 18),
                onPressed: () => _showCreateCollectionDialog(context),
                tooltip: 'New Collection',
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
              hintText: 'Search collections...',
              hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(100)),
              prefixIcon: Icon(Icons.search, size: 16,
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
            onChanged: (v) => setState(() => _searchQuery = v),
          ),
        ),
        // List
        Expanded(
          child: filtered.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.folder_open,
                  title: 'No collections',
                  subtitle: 'Create a collection to save your requests.',
                  action: FilledButton.icon(
                    onPressed: () => _showCreateCollectionDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('New Collection',
                        style: TextStyle(fontSize: 12)),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: 8),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) => _CollectionTile(
                    collection: filtered[i],
                    isExpanded: _expandedIds.contains(filtered[i].id),
                    onToggleExpand: () => setState(() {
                      if (_expandedIds.contains(filtered[i].id)) {
                        _expandedIds.remove(filtered[i].id);
                      } else {
                        _expandedIds.add(filtered[i].id);
                      }
                    }),
                    onRequestTap: (req) {
                      ref.read(tabProvider.notifier).openRequestInTab(req);
                    },
                    onDelete: () => ref
                        .read(collectionProvider.notifier)
                        .deleteCollection(filtered[i].id),
                    onRename: (name) => ref
                        .read(collectionProvider.notifier)
                        .updateCollection(filtered[i].copyWith(name: name)),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _showCreateCollectionDialog(BuildContext context) async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Collection'),
        content: TextField(
          controller: nameCtrl,
          decoration: const InputDecoration(labelText: 'Collection name'),
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, true),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Create')),
        ],
      ),
    );
    if (result == true && nameCtrl.text.isNotEmpty) {
      ref
          .read(collectionProvider.notifier)
          .addCollection(Collection(name: nameCtrl.text));
    }
    nameCtrl.dispose();
  }
}

class _CollectionTile extends StatelessWidget {
  final Collection collection;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final ValueChanged<dynamic> onRequestTap;
  final VoidCallback onDelete;
  final ValueChanged<String> onRename;

  const _CollectionTile({
    required this.collection,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onRequestTap,
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: onToggleExpand,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              children: [
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 16,
                  color: theme.colorScheme.onSurface.withAlpha(160),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.folder,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    collection.name,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  '${collection.totalRequests}',
                  style: TextStyle(
                    fontSize: 10,
                    color: theme.colorScheme.onSurface.withAlpha(100),
                  ),
                ),
                const SizedBox(width: 4),
                _CollectionMenuButton(
                  onDelete: onDelete,
                  onRename: () async {
                    final ctrl =
                        TextEditingController(text: collection.name);
                    final result = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Rename Collection'),
                        content: TextField(
                          controller: ctrl,
                          decoration: const InputDecoration(
                              labelText: 'Name'),
                          autofocus: true,
                        ),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Cancel')),
                          FilledButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Rename')),
                        ],
                      ),
                    );
                    if (result == true && ctrl.text.isNotEmpty) {
                      onRename(ctrl.text);
                    }
                    ctrl.dispose();
                  },
                ),
              ],
            ),
          ),
        ),
        if (isExpanded) ...[
          ...collection.requests.map(
            (req) => _RequestTile(
              name: req.name,
              method: req.request.method,
              url: req.request.url,
              onTap: () => onRequestTap(req.request),
            ),
          ),
          ...collection.folders.map(
            (folder) => _FolderTile(
              folder: folder,
              onRequestTap: onRequestTap,
            ),
          ),
        ],
      ],
    );
  }
}

class _FolderTile extends StatefulWidget {
  final CollectionFolder folder;
  final ValueChanged<dynamic> onRequestTap;

  const _FolderTile({required this.folder, required this.onRequestTap});

  @override
  State<_FolderTile> createState() => _FolderTileState();
}

class _FolderTileState extends State<_FolderTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 5, 8, 5),
            child: Row(
              children: [
                Icon(
                  _expanded
                      ? Icons.keyboard_arrow_down
                      : Icons.keyboard_arrow_right,
                  size: 14,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
                const SizedBox(width: 4),
                Icon(Icons.folder_open, size: 14,
                    color: theme.colorScheme.secondary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    widget.folder.name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (_expanded)
          ...widget.folder.requests.map(
            (req) => _RequestTile(
              name: req.name,
              method: req.request.method,
              url: req.request.url,
              onTap: () => widget.onRequestTap(req.request),
              indent: 40,
            ),
          ),
      ],
    );
  }
}

class _RequestTile extends StatelessWidget {
  final String name;
  final String method;
  final String url;
  final VoidCallback onTap;
  final double indent;

  const _RequestTile({
    required this.name,
    required this.method,
    required this.url,
    required this.onTap,
    this.indent = 24,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: EdgeInsets.fromLTRB(indent, 4, 8, 4),
        child: Row(
          children: [
            MethodBadge(method: method, fontSize: 9),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (url.isNotEmpty)
                    Text(
                      url,
                      style: TextStyle(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withAlpha(100),
                        fontFamily: 'RobotoMono',
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CollectionMenuButton extends StatelessWidget {
  final VoidCallback onDelete;
  final VoidCallback onRename;

  const _CollectionMenuButton({
    required this.onDelete,
    required this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: Icon(Icons.more_vert, size: 14,
          color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
      padding: EdgeInsets.zero,
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'rename', child: Text('Rename')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
      onSelected: (v) {
        if (v == 'delete') onDelete();
        if (v == 'rename') onRename();
      },
    );
  }
}
