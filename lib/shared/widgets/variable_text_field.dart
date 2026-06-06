import 'package:flutter/material.dart';

/// A TextEditingController that renders {{variable}} spans with color.
/// Green (tertiary) = resolved in active environment, Orange = unresolved.
class VariableHighlightController extends TextEditingController {
  Map<String, String> resolvedVariables;

  VariableHighlightController({
    super.text,
    this.resolvedVariables = const {},
  });

  static final _varRegex = RegExp(r'\{\{([^}]+)\}\}');

  /// Call this when resolvedVariables changes to force a repaint.
  void refreshHighlights() => notifyListeners();

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final str = value.text;
    if (str.isEmpty || !str.contains('{{')) {
      return TextSpan(style: style, text: str);
    }

    final theme = Theme.of(context);
    final resolvedColor = theme.colorScheme.tertiary;
    const unresolvedColor = Color(0xFFE67E22);

    final spans = <TextSpan>[];
    int lastEnd = 0;

    for (final match in _varRegex.allMatches(str)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(
          text: str.substring(lastEnd, match.start),
          style: style,
        ));
      }

      final varName = match.group(1)!.trim();
      final isResolved = resolvedVariables.containsKey(varName);
      final color = isResolved ? resolvedColor : unresolvedColor;

      spans.add(TextSpan(
        text: match.group(0),
        style: (style ?? const TextStyle()).copyWith(
          color: color,
          backgroundColor: color.withAlpha(30),
          fontWeight: FontWeight.w600,
        ),
      ));

      lastEnd = match.end;
    }

    if (lastEnd < str.length) {
      spans.add(TextSpan(
        text: str.substring(lastEnd),
        style: style,
      ));
    }

    return TextSpan(style: style, children: spans);
  }
}

/// A text field that highlights {{variable}} placeholders inline.
class VariableAwareTextField extends StatefulWidget {
  final String value;
  final Map<String, String> resolvedVariables;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String hintText;
  final TextStyle? style;
  final InputDecoration? decoration;
  final int? maxLines;
  final bool expands;
  final TextAlignVertical? textAlignVertical;
  final FocusNode? focusNode;

  const VariableAwareTextField({
    super.key,
    required this.value,
    required this.resolvedVariables,
    this.onChanged,
    this.onSubmitted,
    this.hintText = '',
    this.style,
    this.decoration,
    this.maxLines = 1,
    this.expands = false,
    this.textAlignVertical,
    this.focusNode,
  });

  @override
  State<VariableAwareTextField> createState() =>
      _VariableAwareTextFieldState();
}

class _VariableAwareTextFieldState extends State<VariableAwareTextField> {
  late VariableHighlightController _ctrl;
  FocusNode? _ownedFocus;

  FocusNode get _focus => widget.focusNode ?? (_ownedFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _ctrl = VariableHighlightController(
      text: widget.value,
      resolvedVariables: widget.resolvedVariables,
    );
  }

  @override
  void didUpdateWidget(VariableAwareTextField old) {
    super.didUpdateWidget(old);

    // Sync resolved variables and force repaint
    if (old.resolvedVariables != widget.resolvedVariables) {
      _ctrl.resolvedVariables = widget.resolvedVariables;
      _ctrl.refreshHighlights();
    }

    // Only sync text value when not focused (avoids caret jump mid-edit)
    if (!_focus.hasFocus && old.value != widget.value) {
      final sel = _ctrl.selection;
      _ctrl.text = widget.value;
      final len = _ctrl.text.length;
      if (sel.start <= len && sel.end <= len) {
        _ctrl.selection = sel;
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _ownedFocus?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveStyle = widget.style ??
        TextStyle(
          fontSize: 13,
          fontFamily: 'RobotoMono',
          color: theme.colorScheme.onSurface,
        );

    final effectiveDecoration = widget.decoration ??
        InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(
            color: theme.colorScheme.onSurface.withAlpha(80),
            fontSize: effectiveStyle.fontSize ?? 13,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          isDense: true,
        );

    return TextField(
      controller: _ctrl,
      focusNode: _focus,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      maxLines: widget.maxLines,
      expands: widget.expands,
      textAlignVertical: widget.textAlignVertical,
      style: effectiveStyle,
      decoration: effectiveDecoration,
    );
  }
}
