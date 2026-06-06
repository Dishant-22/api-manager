import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../features/environments/providers/environment_provider.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../providers/tab_provider.dart';

class RequestParamsTab extends ConsumerWidget {
  final int tabIndex;
  const RequestParamsTab({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();
    final request = tabState.tabs[tabIndex].request;
    final resolvedVars = ref.watch(resolvedVariablesProvider);

    return KeyValueEditor(
      pairs: request.queryParams,
      keyHint: 'Parameter',
      resolvedVariables: resolvedVars,
      onChanged: (pairs) {
        ref.read(tabProvider.notifier).updateActiveRequest(
              request.copyWith(queryParams: pairs),
            );
      },
    );
  }
}

class RequestHeadersTab extends ConsumerWidget {
  final int tabIndex;
  const RequestHeadersTab({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();
    final request = tabState.tabs[tabIndex].request;
    final resolvedVars = ref.watch(resolvedVariablesProvider);

    return Column(
      children: [
        // Default headers hint
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          color: Theme.of(context).colorScheme.primary.withAlpha(15),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 14,
                color: Theme.of(context).colorScheme.primary.withAlpha(180),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Headers like Accept and Content-Type are set automatically based on your request.',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withAlpha(140),
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: KeyValueEditor(
            pairs: request.headers,
            keyHint: 'Header',
            resolvedVariables: resolvedVars,
            onChanged: (pairs) {
              ref.read(tabProvider.notifier).updateActiveRequest(
                    request.copyWith(headers: pairs),
                  );
            },
          ),
        ),
      ],
    );
  }
}

class PresetHeaderChip extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const PresetHeaderChip({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
    );
  }
}
