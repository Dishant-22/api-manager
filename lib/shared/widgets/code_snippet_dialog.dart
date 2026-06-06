import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/utils/code_generator.dart';
import '../../features/requests/models/api_request.dart';
import 'json_viewer.dart';

class CodeSnippetDialog extends StatefulWidget {
  final ApiRequest request;

  const CodeSnippetDialog({super.key, required this.request});

  static Future<void> show(BuildContext context, ApiRequest request) {
    return showDialog(
      context: context,
      builder: (_) => CodeSnippetDialog(request: request),
    );
  }

  @override
  State<CodeSnippetDialog> createState() => _CodeSnippetDialogState();
}

class _CodeSnippetDialogState extends State<CodeSnippetDialog> {
  CodeLanguage _selectedLanguage = CodeLanguage.curl;
  bool _copied = false;

  String get _snippet =>
      CodeGenerator.generate(widget.request, _selectedLanguage);

  String get _highlightLanguage {
    switch (_selectedLanguage) {
      case CodeLanguage.curl:
        return 'bash';
      case CodeLanguage.dartDio:
        return 'dart';
      case CodeLanguage.jsFetch:
      case CodeLanguage.jsAxios:
        return 'javascript';
      case CodeLanguage.pythonRequests:
        return 'python';
      case CodeLanguage.javaOkHttp:
        return 'java';
    }
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: _snippet));
    setState(() => _copied = true);
    await Future<void>.delayed(const Duration(seconds: 2));
    if (mounted) setState(() => _copied = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: size.height * 0.8,
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
              child: Row(
                children: [
                  const Icon(Icons.code, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Code Snippet',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            // Language selector
            SizedBox(
              height: 44,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                children: CodeLanguage.values.map((lang) {
                  final selected = _selectedLanguage == lang;
                  return Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(lang.displayName, style: const TextStyle(fontSize: 12)),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _selectedLanguage = lang),
                      visualDensity: VisualDensity.compact,
                    ),
                  );
                }).toList(),
              ),
            ),
            const Divider(height: 1),
            // Snippet
            Expanded(
              child: SingleChildScrollView(
                child: SyntaxViewer(
                  content: _snippet,
                  language: _highlightLanguage,
                  prettify: false,
                ),
              ),
            ),
            // Actions
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FilledButton.icon(
                    onPressed: _copy,
                    icon: Icon(_copied ? Icons.check : Icons.copy, size: 16),
                    label: Text(_copied ? 'Copied!' : 'Copy to clipboard'),
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
