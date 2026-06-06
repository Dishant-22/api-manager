import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:flutter_highlight/themes/atom-one-light.dart';
import '../../core/utils/json_formatter.dart';

class SyntaxViewer extends StatelessWidget {
  final String content;
  final String language;
  final bool prettify;

  const SyntaxViewer({
    super.key,
    required this.content,
    this.language = 'json',
    this.prettify = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final displayContent =
        (prettify && language == 'json') ? JsonFormatter.prettyPrint(content) : content;

    return HighlightView(
      displayContent,
      language: language,
      theme: isDark ? atomOneDarkTheme : atomOneLightTheme,
      padding: const EdgeInsets.all(12),
      textStyle: const TextStyle(
        fontFamily: 'RobotoMono',
        fontSize: 13,
        height: 1.5,
      ),
    );
  }
}

class ResponseBodyViewer extends StatefulWidget {
  final String body;
  final String? contentType;

  const ResponseBodyViewer({
    super.key,
    required this.body,
    this.contentType,
  });

  @override
  State<ResponseBodyViewer> createState() => _ResponseBodyViewerState();
}

class _ResponseBodyViewerState extends State<ResponseBodyViewer> {
  bool _prettyPrint = true;
  bool _wordWrap = true;

  String get _language =>
      JsonFormatter.detectLanguage(widget.contentType, widget.body);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // Toolbar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            border: Border(
              bottom: BorderSide(
                color: theme.dividerColor,
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: [
              Text(
                _language.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (_language == 'json')
                _ToolbarToggle(
                  label: 'Pretty',
                  value: _prettyPrint,
                  onChanged: (v) => setState(() => _prettyPrint = v),
                ),
              const SizedBox(width: 8),
              _ToolbarToggle(
                label: 'Wrap',
                value: _wordWrap,
                onChanged: (v) => setState(() => _wordWrap = v),
              ),
              const SizedBox(width: 8),
              _CopyButton(content: widget.body),
            ],
          ),
        ),
        // Content
        Expanded(
          child: SingleChildScrollView(
            child: SingleChildScrollView(
              scrollDirection:
                  _wordWrap ? Axis.vertical : Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: SyntaxViewer(
                  content: widget.body,
                  language: _language,
                  prettify: _prettyPrint,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ToolbarToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToolbarToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: value
              ? theme.colorScheme.primary.withAlpha(30)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: value
                ? theme.colorScheme.primary.withAlpha(100)
                : theme.dividerColor,
            width: 0.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: value
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(120),
          ),
        ),
      ),
    );
  }
}

class _CopyButton extends StatefulWidget {
  final String content;
  const _CopyButton({required this.content});

  @override
  State<_CopyButton> createState() => _CopyButtonState();
}

class _CopyButtonState extends State<_CopyButton> {
  bool _copied = false;

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: widget.content));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _copy,
      icon: Icon(
        _copied ? Icons.check : Icons.copy,
        size: 14,
      ),
      label: Text(_copied ? 'Copied' : 'Copy', style: const TextStyle(fontSize: 11)),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
