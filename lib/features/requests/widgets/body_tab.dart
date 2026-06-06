import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../../shared/widgets/key_value_editor.dart';
import '../models/request_body.dart';
import '../providers/tab_provider.dart';

class BodyTab extends ConsumerWidget {
  final int tabIndex;
  const BodyTab({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();
    final request = tabState.tabs[tabIndex].request;
    final body = request.body;

    void updateBody(RequestBody updated) {
      ref.read(tabProvider.notifier).updateActiveRequest(
            request.copyWith(body: updated),
          );
    }

    return Column(
      children: [
        _BodyTypeSelector(
          selected: body.type,
          onChanged: (type) => updateBody(body.copyWith(type: type)),
        ),
        const Divider(height: 1),
        Expanded(child: _BodyEditor(body: body, onChanged: updateBody)),
      ],
    );
  }
}

class _BodyTypeSelector extends StatelessWidget {
  final BodyType selected;
  final ValueChanged<BodyType> onChanged;

  const _BodyTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: BodyType.values.map((type) {
          final isSelected = type == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: ChoiceChip(
              label: Text(_typeLabel(type), style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              visualDensity: VisualDensity.compact,
              selectedColor: theme.colorScheme.primaryContainer,
            ),
          );
        }).toList(),
      ),
    );
  }

  String _typeLabel(BodyType type) {
    switch (type) {
      case BodyType.none:
        return 'None';
      case BodyType.rawJson:
        return 'JSON';
      case BodyType.rawText:
        return 'Text';
      case BodyType.rawXml:
        return 'XML';
      case BodyType.formData:
        return 'form-data';
      case BodyType.formUrlEncoded:
        return 'x-www-form-urlencoded';
    }
  }
}

class _BodyEditor extends StatelessWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  const _BodyEditor({required this.body, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    switch (body.type) {
      case BodyType.none:
        return const _NoneBody();
      case BodyType.rawJson:
      case BodyType.rawText:
      case BodyType.rawXml:
        return _RawBodyEditor(body: body, onChanged: onChanged);
      case BodyType.formData:
        return _FormDataEditor(body: body, onChanged: onChanged);
      case BodyType.formUrlEncoded:
        return _UrlEncodedEditor(body: body, onChanged: onChanged);
    }
  }
}

class _NoneBody extends StatelessWidget {
  const _NoneBody();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'This request has no body.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurface.withAlpha(100),
            ),
      ),
    );
  }
}

class _RawBodyEditor extends StatefulWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  const _RawBodyEditor({required this.body, required this.onChanged});

  @override
  State<_RawBodyEditor> createState() => _RawBodyEditorState();
}

class _RawBodyEditorState extends State<_RawBodyEditor> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.body.rawContent ?? '');
  }

  @override
  void didUpdateWidget(_RawBodyEditor old) {
    super.didUpdateWidget(old);
    if (old.body.type != widget.body.type ||
        (old.body.rawContent != widget.body.rawContent &&
            _ctrl.text != widget.body.rawContent)) {
      _ctrl.text = widget.body.rawContent ?? '';
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _hint {
    switch (widget.body.type) {
      case BodyType.rawJson:
        return '{\n  "key": "value"\n}';
      case BodyType.rawXml:
        return '<?xml version="1.0"?>\n<root>\n  <key>value</key>\n</root>';
      default:
        return 'Enter request body...';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextField(
      controller: _ctrl,
      maxLines: null,
      expands: true,
      textAlignVertical: TextAlignVertical.top,
      style: const TextStyle(fontSize: 13, fontFamily: 'RobotoMono', height: 1.5),
      decoration: InputDecoration(
        hintText: _hint,
        hintStyle: TextStyle(
          color: theme.colorScheme.onSurface.withAlpha(60),
          fontSize: 12,
          fontFamily: 'RobotoMono',
        ),
        contentPadding: const EdgeInsets.all(12),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      onChanged: (v) => widget.onChanged(widget.body.copyWith(rawContent: v)),
    );
  }
}

class _UrlEncodedEditor extends StatelessWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  const _UrlEncodedEditor({required this.body, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return KeyValueEditor(
      pairs: body.urlEncodedFields,
      onChanged: (pairs) => onChanged(body.copyWith(urlEncodedFields: pairs)),
    );
  }
}

class _FormDataEditor extends StatelessWidget {
  final RequestBody body;
  final ValueChanged<RequestBody> onChanged;

  const _FormDataEditor({required this.body, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final fields = List<MultipartField>.from(body.formFields);
    if (fields.isEmpty || fields.last.key.isNotEmpty) {
      fields.add(MultipartField.empty());
    }

    return ListView.builder(
      itemCount: fields.length,
      itemBuilder: (ctx, i) {
        final field = fields[i];
        final isPlaceholder = i == fields.length - 1 && field.key.isEmpty;

        return _FormDataRow(
          field: field,
          isPlaceholder: isPlaceholder,
          onChanged: (updated) {
            final newFields = List<MultipartField>.from(body.formFields);
            if (i < newFields.length) {
              newFields[i] = updated;
            } else {
              newFields.add(updated);
            }
            onChanged(body.copyWith(
              formFields: newFields.where((f) => f.key.isNotEmpty).toList(),
            ));
          },
          onDelete: isPlaceholder
              ? null
              : () {
                  final newFields = List<MultipartField>.from(body.formFields)
                    ..removeAt(i);
                  onChanged(body.copyWith(formFields: newFields));
                },
        );
      },
    );
  }
}

class _FormDataRow extends StatefulWidget {
  final MultipartField field;
  final bool isPlaceholder;
  final ValueChanged<MultipartField> onChanged;
  final VoidCallback? onDelete;

  const _FormDataRow({
    required this.field,
    required this.isPlaceholder,
    required this.onChanged,
    this.onDelete,
  });

  @override
  State<_FormDataRow> createState() => _FormDataRowState();
}

class _FormDataRowState extends State<_FormDataRow> {
  late TextEditingController _keyCtrl;
  late TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _keyCtrl = TextEditingController(text: widget.field.key);
    _valueCtrl = TextEditingController(text: widget.field.value);
  }

  @override
  void dispose() {
    _keyCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null && result.files.isNotEmpty) {
      final path = result.files.first.path;
      if (path == null) return;
      _valueCtrl.text = path;
      widget.onChanged(widget.field.copyWith(
        key: _keyCtrl.text,
        value: path,
        isFile: true,
        filePath: path,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: theme.dividerColor.withAlpha(60)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _keyCtrl,
              style: const TextStyle(fontSize: 13),
              decoration: const InputDecoration(
                hintText: 'Key',
                isDense: true,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              ),
              onChanged: (v) =>
                  widget.onChanged(widget.field.copyWith(key: v)),
            ),
          ),
          Container(
              width: 1,
              height: 32,
              color: theme.dividerColor.withAlpha(80)),
          Expanded(
            child: widget.field.isFile
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.field.filePath
                                  ?.split('\\')
                                  .last
                                  .split('/')
                                  .last ??
                              '',
                          style: const TextStyle(fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, size: 14),
                        onPressed: () => widget.onChanged(
                          MultipartField(
                            id: widget.field.id,
                            key: widget.field.key,
                            value: '',
                          ),
                        ),
                      ),
                    ],
                  )
                : TextField(
                    controller: _valueCtrl,
                    style: const TextStyle(fontSize: 13),
                    decoration: const InputDecoration(
                      hintText: 'Value',
                      isDense: true,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    ),
                    onChanged: (v) =>
                        widget.onChanged(widget.field.copyWith(value: v)),
                  ),
          ),
          if (!widget.isPlaceholder)
            IconButton(
              icon: Icon(
                widget.field.isFile
                    ? Icons.insert_drive_file
                    : Icons.attach_file,
                size: 16,
              ),
              onPressed: _pickFile,
              tooltip: 'Attach file',
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
          if (widget.onDelete != null)
            IconButton(
              icon: Icon(Icons.close,
                  size: 14,
                  color: theme.colorScheme.onSurface.withAlpha(100)),
              onPressed: widget.onDelete,
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
