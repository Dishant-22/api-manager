import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/environments/providers/environment_provider.dart';
import '../../../shared/widgets/variable_text_field.dart';
import '../models/request_tab.dart';
import '../providers/tab_provider.dart';
import '../providers/request_provider.dart';

class RequestUrlBar extends ConsumerWidget {
  final int tabIndex;

  const RequestUrlBar({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();

    final tab = tabState.tabs[tabIndex];
    final request = tab.request;
    final isLoading = tab.status == TabStatus.loading;
    final resolvedVars = ref.watch(resolvedVariablesProvider);
    final theme = Theme.of(context);

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          // Method dropdown
          _MethodDropdown(
            method: request.method,
            onChanged: (method) {
              ref.read(tabProvider.notifier).updateActiveRequest(
                    request.copyWith(method: method),
                  );
            },
          ),
          const SizedBox(width: 8),
          // URL input with variable highlighting
          Expanded(
            child: _UrlTextField(
              url: request.url,
              resolvedVariables: resolvedVars,
              onChanged: (url) {
                ref.read(tabProvider.notifier).updateActiveRequest(
                      request.copyWith(url: url),
                    );
              },
              onSubmitted: (_) {
                if (!isLoading) {
                  ref.read(requestExecutorProvider).sendRequest(tabIndex);
                }
              },
            ),
          ),
          const SizedBox(width: 8),
          // Send / Cancel button
          _SendButton(
            isLoading: isLoading,
            onSend: () =>
                ref.read(requestExecutorProvider).sendRequest(tabIndex),
            onCancel: () =>
                ref.read(requestExecutorProvider).cancelRequest(tabIndex),
          ),
        ],
      ),
    );
  }
}

class _MethodDropdown extends StatelessWidget {
  final String method;
  final ValueChanged<String> onChanged;

  const _MethodDropdown({required this.method, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.methodColor(method);
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: method,
          items: AppConstants.httpMethods
              .map((m) => DropdownMenuItem(
                    value: m,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        m,
                        style: TextStyle(
                          color: AppColors.methodColor(m),
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          fontFamily: 'RobotoMono',
                        ),
                      ),
                    ),
                  ))
              .toList(),
          onChanged: (v) => v != null ? onChanged(v) : null,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          icon: Icon(Icons.keyboard_arrow_down, size: 16, color: color),
          padding: const EdgeInsets.only(left: 8),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}

class _UrlTextField extends StatefulWidget {
  final String url;
  final Map<String, String> resolvedVariables;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  const _UrlTextField({
    required this.url,
    required this.resolvedVariables,
    required this.onChanged,
    required this.onSubmitted,
  });

  @override
  State<_UrlTextField> createState() => _UrlTextFieldState();
}

class _UrlTextFieldState extends State<_UrlTextField> {
  late VariableHighlightController _ctrl;
  late FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _ctrl = VariableHighlightController(
      text: widget.url,
      resolvedVariables: widget.resolvedVariables,
    );
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(_UrlTextField old) {
    super.didUpdateWidget(old);

    if (old.resolvedVariables != widget.resolvedVariables) {
      _ctrl.resolvedVariables = widget.resolvedVariables;
      _ctrl.refreshHighlights();
    }

    if (!_focus.hasFocus && old.url != widget.url) {
      _ctrl.text = widget.url;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      style: const TextStyle(fontSize: 14, fontFamily: 'RobotoMono'),
      decoration: InputDecoration(
        hintText: 'https://api.example.com/endpoint',
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(80),
          fontSize: 13,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        isDense: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(color: theme.dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              BorderSide(color: theme.colorScheme.primary, width: 1.5),
        ),
      ),
    );
  }
}

class _SendButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onSend;
  final VoidCallback onCancel;

  const _SendButton({
    required this.isLoading,
    required this.onSend,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return SizedBox(
        height: 36,
        child: OutlinedButton.icon(
          onPressed: onCancel,
          icon: const SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          label: const Text('Cancel', style: TextStyle(fontSize: 13)),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(horizontal: 14),
          ),
        ),
      );
    }

    return SizedBox(
      height: 36,
      child: FilledButton(
        onPressed: onSend,
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: const Text('Send',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
      ),
    );
  }
}
