import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/empty_state_widget.dart';
import '../models/environment.dart';
import '../providers/environment_provider.dart';

class EnvironmentsScreen extends ConsumerWidget {
  const EnvironmentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final envState = ref.watch(environmentProvider);
    final selectedId = ref.watch(selectedEnvIdProvider);
    final theme = Theme.of(context);

    // Auto-select first env when the screen opens and nothing is selected
    final effectiveId = selectedId ??
        (envState.environments.isNotEmpty
            ? envState.environments.first.id
            : null);

    // Keep provider in sync with the auto-selected value
    if (effectiveId != selectedId) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(selectedEnvIdProvider.notifier).state = effectiveId;
      });
    }

    final selectedEnv = effectiveId == null
        ? null
        : envState.environments
            .where((e) => e.id == effectiveId)
            .firstOrNull;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Environments'),
        actions: [
          TextButton.icon(
            onPressed: () => _createEnvironment(context, ref),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Environment'),
          ),
        ],
      ),
      body: Row(
        children: [
          // ── Environment list ──────────────────────────────────────────
          SizedBox(
            width: 220,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: Text(
                    'Environments',
                    style: theme.textTheme.labelLarge
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: envState.environments.length,
                    itemBuilder: (ctx, i) {
                      final env = envState.environments[i];
                      final isSelected = env.id == effectiveId;
                      final isActive =
                          env.id == envState.activeEnvironmentId;
                      return ListTile(
                        selected: isSelected,
                        dense: true,
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                env.name,
                                style: const TextStyle(fontSize: 13),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (env.isGlobal)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 4, vertical: 1),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primary
                                      .withAlpha(30),
                                  borderRadius:
                                      BorderRadius.circular(3),
                                ),
                                child: Text(
                                  'Global',
                                  style: TextStyle(
                                    fontSize: 9,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: isActive
                            ? Text(
                                'Active',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: theme.colorScheme.primary,
                                ),
                              )
                            : null,
                        onTap: () => ref
                            .read(selectedEnvIdProvider.notifier)
                            .state = env.id,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, size: 14),
                          itemBuilder: (_) => [
                            PopupMenuItem(
                              value: 'activate',
                              child: Text(
                                isActive ? 'Deactivate' : 'Set as Active',
                              ),
                            ),
                            if (!env.isGlobal)
                              const PopupMenuItem(
                                value: 'delete',
                                child: Text('Delete'),
                              ),
                          ],
                          onSelected: (v) async {
                            if (v == 'activate') {
                              await ref
                                  .read(environmentProvider.notifier)
                                  .setActiveEnvironment(
                                      isActive ? null : env.id);
                            } else if (v == 'delete') {
                              await ref
                                  .read(environmentProvider.notifier)
                                  .deleteEnvironment(env.id);
                              if (effectiveId == env.id) {
                                ref
                                    .read(selectedEnvIdProvider.notifier)
                                    .state = null;
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          VerticalDivider(width: 1, color: theme.dividerColor),
          // ── Variable editor ───────────────────────────────────────────
          Expanded(
            child: selectedEnv == null
                ? const EmptyStateWidget(
                    icon: Icons.tune,
                    title: 'Select an environment',
                    subtitle:
                        'Choose an environment to edit its variables.',
                  )
                : _EnvironmentEditor(
                    key: ValueKey(selectedEnv.id),
                    env: selectedEnv,
                    onUpdate: (updated) => ref
                        .read(environmentProvider.notifier)
                        .updateEnvironment(updated),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _createEnvironment(
      BuildContext context, WidgetRef ref) async {
    final nameCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('New Environment'),
        content: TextField(
          controller: nameCtrl,
          decoration:
              const InputDecoration(labelText: 'Environment name'),
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
      final newEnv = Environment(name: nameCtrl.text);
      await ref.read(environmentProvider.notifier).addEnvironment(newEnv);
      // Auto-select the newly created environment
      ref.read(selectedEnvIdProvider.notifier).state = newEnv.id;
    }
    nameCtrl.dispose();
  }
}

// ── Environment variable editor ─────────────────────────────────────────────

class _EnvironmentEditor extends StatefulWidget {
  final Environment env;
  final ValueChanged<Environment> onUpdate;

  const _EnvironmentEditor({
    super.key,
    required this.env,
    required this.onUpdate,
  });

  @override
  State<_EnvironmentEditor> createState() => _EnvironmentEditorState();
}

class _EnvironmentEditorState extends State<_EnvironmentEditor> {
  late List<EnvVariable> _variables;

  @override
  void initState() {
    super.initState();
    _variables = List.from(widget.env.variables);
    _ensureEmptyRow();
  }

  void _ensureEmptyRow() {
    if (_variables.isEmpty || _variables.last.key.isNotEmpty) {
      _variables.add(EnvVariable.empty());
    }
  }

  /// Auto-saves immediately — no explicit Save button press required.
  void _save() {
    final nonEmpty = _variables.where((v) => v.key.isNotEmpty).toList();
    widget.onUpdate(widget.env.copyWith(variables: nonEmpty));
  }

  void _updateVariable(int index, EnvVariable v) {
    setState(() {
      _variables[index] = v;
      if (index == _variables.length - 1 && v.key.isNotEmpty) {
        _variables.add(EnvVariable.empty());
      }
    });
    _save();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Row(
            children: [
              Text(
                widget.env.name,
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              if (widget.env.isGlobal)
                const Chip(
                  label: Text('Global'),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              const Spacer(),
              // Auto-save indicator
              Text(
                'Auto-saved',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(100),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Variable',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Initial Value',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w600),
                ),
              ),
              Expanded(
                child: Text(
                  'Current Value',
                  style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurface.withAlpha(120),
                      fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(width: 60),
            ],
          ),
        ),
        const Divider(),
        Expanded(
          child: ListView.builder(
            itemCount: _variables.length,
            itemBuilder: (ctx, i) => _VariableRow(
              variable: _variables[i],
              onChanged: (v) => _updateVariable(i, v),
              onDelete: i == _variables.length - 1 &&
                      _variables[i].key.isEmpty
                  ? null
                  : () {
                      setState(() => _variables.removeAt(i));
                      _save();
                    },
            ),
          ),
        ),
      ],
    );
  }
}

class _VariableRow extends StatefulWidget {
  final EnvVariable variable;
  final ValueChanged<EnvVariable> onChanged;
  final VoidCallback? onDelete;

  const _VariableRow({
    required this.variable,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_VariableRow> createState() => _VariableRowState();
}

class _VariableRowState extends State<_VariableRow> {
  late TextEditingController _keyCtrl;
  late TextEditingController _initCtrl;
  late TextEditingController _currCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.variable.key);
    _initCtrl =
        TextEditingController(text: widget.variable.initialValue ?? '');
    _currCtrl = TextEditingController(text: widget.variable.value);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _initCtrl.dispose();
    _currCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: _Field(
              controller: _keyCtrl,
              hint: 'variableName',
              onChanged: (v) =>
                  widget.onChanged(widget.variable.copyWith(key: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Field(
              controller: _initCtrl,
              hint: 'initial value',
              onChanged: (v) => widget
                  .onChanged(widget.variable.copyWith(initialValue: v)),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _Field(
              controller: _currCtrl,
              hint: 'current value',
              onChanged: (v) =>
                  widget.onChanged(widget.variable.copyWith(value: v)),
            ),
          ),
          SizedBox(
            width: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Checkbox(
                  value: widget.variable.enabled,
                  onChanged: (v) => widget
                      .onChanged(widget.variable.copyWith(enabled: v ?? true)),
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: Icon(Icons.close,
                        size: 14,
                        color: theme.colorScheme.onSurface.withAlpha(120)),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;

  const _Field({
    required this.controller,
    required this.hint,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 12, fontFamily: 'RobotoMono'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 11),
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      ),
    );
  }
}
