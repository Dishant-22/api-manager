import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/collections/providers/collection_provider.dart';
import '../models/api_request.dart';
import '../../../shared/widgets/code_snippet_dialog.dart';
import '../../../shared/widgets/resizable_panel.dart';
import '../providers/tab_provider.dart';
import '../widgets/auth_tab.dart';
import '../widgets/body_tab.dart';
import '../widgets/request_params_tab.dart';
import '../widgets/request_url_bar.dart';
import '../widgets/response_panel.dart';

class RequestScreen extends ConsumerStatefulWidget {
  final int tabIndex;

  const RequestScreen({super.key, required this.tabIndex});

  @override
  ConsumerState<RequestScreen> createState() => _RequestScreenState();
}

class _RequestScreenState extends ConsumerState<RequestScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tabState = ref.watch(tabProvider);
    if (widget.tabIndex >= tabState.tabs.length) return const SizedBox();
    final tab = tabState.tabs[widget.tabIndex];
    final theme = Theme.of(context);

    return Column(
      children: [
        // URL Bar
        RequestUrlBar(tabIndex: widget.tabIndex),
        // Request / Response split
        Expanded(
          child: ResizableVerticalPanel(
            initialTopFraction: 0.45,
            top: Column(
              children: [
                // Request tabs
                Container(
                  color: theme.colorScheme.surface,
                  child: Row(
                    children: [
                      Expanded(
                        child: TabBar(
                          controller: _tabController,
                          tabs: const [
                            Tab(text: 'Params', height: 36),
                            Tab(text: 'Headers', height: 36),
                            Tab(text: 'Auth', height: 36),
                            Tab(text: 'Body', height: 36),
                          ],
                          labelStyle: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w600),
                          unselectedLabelStyle:
                              const TextStyle(fontSize: 12),
                          indicatorSize: TabBarIndicatorSize.tab,
                          dividerHeight: 0,
                        ),
                      ),
                      // Save to Collection button
                      IconButton(
                        icon: const Icon(Icons.save_outlined, size: 18),
                        tooltip: 'Save to collection',
                        onPressed: () =>
                            _showSaveDialog(context, ref, tab.request),
                        visualDensity: VisualDensity.compact,
                      ),
                      // Code snippet button
                      IconButton(
                        icon: const Icon(Icons.code, size: 18),
                        tooltip: 'Generate code snippet',
                        onPressed: () =>
                            CodeSnippetDialog.show(context, tab.request),
                        visualDensity: VisualDensity.compact,
                      ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
                Divider(height: 1, color: theme.dividerColor),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      RequestParamsTab(tabIndex: widget.tabIndex),
                      RequestHeadersTab(tabIndex: widget.tabIndex),
                      AuthTab(tabIndex: widget.tabIndex),
                      BodyTab(tabIndex: widget.tabIndex),
                    ],
                  ),
                ),
              ],
            ),
            bottom: ResponsePanel(tabIndex: widget.tabIndex),
          ),
        ),
      ],
    );
  }

  Future<void> _showSaveDialog(
    BuildContext context,
    WidgetRef ref,
    ApiRequest request,
  ) async {
    final collections = ref.read(collectionProvider);
    if (collections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Create a collection first from the Collections panel.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final nameCtrl = TextEditingController(text: request.displayName);
    String? selCollId = collections.first.id;
    String? selFolderId;

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final selColl = collections
              .where((c) => c.id == selCollId)
              .firstOrNull;

          return AlertDialog(
            title: const Text('Save to Collection'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    autofocus: true,
                    decoration: const InputDecoration(
                      labelText: 'Request name',
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: selCollId,
                    decoration: const InputDecoration(
                      labelText: 'Collection',
                    ),
                    items: collections
                        .map((c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) => setS(() {
                      selCollId = v;
                      selFolderId = null;
                    }),
                  ),
                  if (selColl != null && selColl.folders.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String?>(
                      initialValue: selFolderId,
                      decoration: const InputDecoration(
                        labelText: 'Folder (optional)',
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                          child: Text('No folder — save at root'),
                        ),
                        ...selColl.folders.map((f) => DropdownMenuItem(
                              value: f.id,
                              child: Text(f.name),
                            )),
                      ],
                      onChanged: (v) => setS(() => selFolderId = v),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () async {
                  final n = nameCtrl.text.trim();
                  if (n.isEmpty || selCollId == null) return;
                  await ref
                      .read(collectionProvider.notifier)
                      .saveRequestToCollection(
                        collectionId: selCollId!,
                        folderId: selFolderId,
                        request: request,
                        name: n,
                      );
                  if (ctx.mounted) Navigator.pop(ctx);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Saved "$n" to collection'),
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    nameCtrl.dispose();
  }
}
