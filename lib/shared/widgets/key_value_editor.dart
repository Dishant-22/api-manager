import 'package:flutter/material.dart';
import '../../features/requests/models/key_value_pair.dart';
import 'variable_text_field.dart';

class KeyValueEditor extends StatefulWidget {
  final List<KeyValuePair> pairs;
  final ValueChanged<List<KeyValuePair>> onChanged;
  final String keyHint;
  final String valueHint;
  final bool showDescription;
  /// When provided, {{variable}} in value fields will be highlighted.
  final Map<String, String> resolvedVariables;

  const KeyValueEditor({
    super.key,
    required this.pairs,
    required this.onChanged,
    this.keyHint = 'Key',
    this.valueHint = 'Value',
    this.showDescription = false,
    this.resolvedVariables = const {},
  });

  @override
  State<KeyValueEditor> createState() => _KeyValueEditorState();
}

class _KeyValueEditorState extends State<KeyValueEditor> {
  late List<KeyValuePair> _pairs;

  @override
  void initState() {
    super.initState();
    _pairs = List.from(widget.pairs);
    if (_pairs.isEmpty || _pairs.last.key.isNotEmpty) {
      _pairs.add(KeyValuePair.empty());
    }
  }

  @override
  void didUpdateWidget(KeyValueEditor old) {
    super.didUpdateWidget(old);
    if (old.pairs != widget.pairs) {
      _pairs = List.from(widget.pairs);
      if (_pairs.isEmpty || _pairs.last.key.isNotEmpty) {
        _pairs.add(KeyValuePair.empty());
      }
    }
  }

  void _notify() {
    final nonEmpty = _pairs.where((p) => p.key.isNotEmpty).toList();
    widget.onChanged(nonEmpty);
  }

  void _update(int index, KeyValuePair updated) {
    setState(() {
      _pairs[index] = updated;
      if (index == _pairs.length - 1 && updated.key.isNotEmpty) {
        _pairs.add(KeyValuePair.empty());
      }
    });
    _notify();
  }

  void _delete(int index) {
    setState(() => _pairs.removeAt(index));
    _notify();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              const SizedBox(width: 32),
              Expanded(
                child: Text(
                  widget.keyHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  widget.valueHint,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: theme.colorScheme.onSurface.withAlpha(120),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 32),
            ],
          ),
        ),
        const Divider(height: 1),
        // Rows
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _pairs.length,
          itemBuilder: (context, index) {
            final pair = _pairs[index];
            final isPlaceholder =
                index == _pairs.length - 1 && pair.key.isEmpty;

            return _KeyValueRow(
              pair: pair,
              keyHint: widget.keyHint,
              valueHint: widget.valueHint,
              isPlaceholder: isPlaceholder,
              isDark: isDark,
              resolvedVariables: widget.resolvedVariables,
              onChanged: (updated) => _update(index, updated),
              onDelete: isPlaceholder ? null : () => _delete(index),
            );
          },
        ),
      ],
    );
  }
}

class _KeyValueRow extends StatefulWidget {
  final KeyValuePair pair;
  final String keyHint;
  final String valueHint;
  final bool isPlaceholder;
  final bool isDark;
  final Map<String, String> resolvedVariables;
  final ValueChanged<KeyValuePair> onChanged;
  final VoidCallback? onDelete;

  const _KeyValueRow({
    required this.pair,
    required this.keyHint,
    required this.valueHint,
    required this.isPlaceholder,
    required this.isDark,
    required this.resolvedVariables,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_KeyValueRow> createState() => _KeyValueRowState();
}

class _KeyValueRowState extends State<_KeyValueRow> {
  late TextEditingController _keyCtrl;
  late VariableHighlightController _valueCtrl;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.pair.key);
    _valueCtrl = VariableHighlightController(
      text: widget.pair.value,
      resolvedVariables: widget.resolvedVariables,
    );
    _enabled = widget.pair.enabled;
  }

  @override
  void didUpdateWidget(_KeyValueRow old) {
    super.didUpdateWidget(old);
    if (old.pair.key != widget.pair.key && _keyCtrl.text != widget.pair.key) {
      _keyCtrl.text = widget.pair.key;
    }
    if (old.pair.value != widget.pair.value &&
        _valueCtrl.text != widget.pair.value) {
      _valueCtrl.text = widget.pair.value;
    }
    if (old.resolvedVariables != widget.resolvedVariables) {
      _valueCtrl.resolvedVariables = widget.resolvedVariables;
      _valueCtrl.refreshHighlights();
    }
    _enabled = widget.pair.enabled;
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: theme.dividerColor.withAlpha(60),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: [
          // Enabled toggle
          SizedBox(
            width: 32,
            child: widget.isPlaceholder
                ? const SizedBox()
                : Checkbox(
                    value: _enabled,
                    onChanged: (v) {
                      setState(() => _enabled = v ?? true);
                      widget.onChanged(
                          widget.pair.copyWith(enabled: v ?? true));
                    },
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
          ),
          // Key field (plain, no variable highlighting in keys)
          Expanded(
            child: TextField(
              controller: _keyCtrl,
              onChanged: (v) =>
                  widget.onChanged(widget.pair.copyWith(key: v)),
              style: const TextStyle(
                  fontSize: 13, fontFamily: 'RobotoMono'),
              decoration: InputDecoration(
                hintText: widget.keyHint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          // Separator
          Container(
            width: 1,
            height: 32,
            color: theme.dividerColor.withAlpha(80),
          ),
          // Value field with variable highlighting
          Expanded(
            child: TextField(
              controller: _valueCtrl,
              onChanged: (v) =>
                  widget.onChanged(widget.pair.copyWith(value: v)),
              style: const TextStyle(
                  fontSize: 13, fontFamily: 'RobotoMono'),
              decoration: InputDecoration(
                hintText: widget.valueHint,
                hintStyle: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withAlpha(80),
                ),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                isDense: true,
              ),
            ),
          ),
          // Delete button
          SizedBox(
            width: 32,
            child: widget.onDelete == null
                ? const SizedBox()
                : IconButton(
                    icon: Icon(
                      Icons.close,
                      size: 14,
                      color: theme.colorScheme.onSurface.withAlpha(100),
                    ),
                    onPressed: widget.onDelete,
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                  ),
          ),
        ],
      ),
    );
  }
}
