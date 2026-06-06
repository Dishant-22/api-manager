import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/auth_config.dart';
import '../providers/tab_provider.dart';

class AuthTab extends ConsumerWidget {
  final int tabIndex;
  const AuthTab({super.key, required this.tabIndex});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);
    if (tabIndex >= tabState.tabs.length) return const SizedBox();
    final request = tabState.tabs[tabIndex].request;
    final auth = request.auth;

    void updateAuth(AuthConfig updated) {
      ref.read(tabProvider.notifier).updateActiveRequest(
            request.copyWith(auth: updated),
          );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Auth type selector
          _AuthTypeSelector(
            selected: auth.type,
            onChanged: (type) => updateAuth(auth.copyWith(type: type)),
          ),
          const SizedBox(height: 20),
          // Auth fields
          _AuthFields(auth: auth, onChanged: updateAuth),
        ],
      ),
    );
  }
}

class _AuthTypeSelector extends StatelessWidget {
  final AuthType selected;
  final ValueChanged<AuthType> onChanged;

  const _AuthTypeSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Auth Type',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: AuthType.values.map((type) {
            final label = _authTypeLabel(type);
            final isSelected = type == selected;
            return ChoiceChip(
              label: Text(label, style: const TextStyle(fontSize: 12)),
              selected: isSelected,
              onSelected: (_) => onChanged(type),
              visualDensity: VisualDensity.compact,
            );
          }).toList(),
        ),
      ],
    );
  }

  String _authTypeLabel(AuthType type) {
    switch (type) {
      case AuthType.none:
        return 'No Auth';
      case AuthType.bearerToken:
        return 'Bearer Token';
      case AuthType.basicAuth:
        return 'Basic Auth';
      case AuthType.apiKey:
        return 'API Key';
      case AuthType.oauth2:
        return 'OAuth 2.0';
    }
  }
}

class _AuthFields extends StatelessWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const _AuthFields({required this.auth, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    switch (auth.type) {
      case AuthType.none:
        return const _NoAuthMessage();
      case AuthType.bearerToken:
        return _BearerTokenFields(auth: auth, onChanged: onChanged);
      case AuthType.basicAuth:
        return _BasicAuthFields(auth: auth, onChanged: onChanged);
      case AuthType.apiKey:
        return _ApiKeyFields(auth: auth, onChanged: onChanged);
      case AuthType.oauth2:
        return const _OAuth2Placeholder();
    }
  }
}

class _NoAuthMessage extends StatelessWidget {
  const _NoAuthMessage();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_open, size: 18,
              color: Theme.of(context).colorScheme.onSurface.withAlpha(120)),
          const SizedBox(width: 8),
          Text(
            'This request does not use any authorization.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _BearerTokenFields extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const _BearerTokenFields({required this.auth, required this.onChanged});

  @override
  State<_BearerTokenFields> createState() => _BearerTokenFieldsState();
}

class _BearerTokenFieldsState extends State<_BearerTokenFields> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.auth.bearerToken ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _AuthField(
      label: 'Token',
      hint: 'Enter bearer token or {{token}}',
      controller: _ctrl,
      onChanged: (v) =>
          widget.onChanged(widget.auth.copyWith(bearerToken: v)),
    );
  }
}

class _BasicAuthFields extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const _BasicAuthFields({required this.auth, required this.onChanged});

  @override
  State<_BasicAuthFields> createState() => _BasicAuthFieldsState();
}

class _BasicAuthFieldsState extends State<_BasicAuthFields> {
  late TextEditingController _userCtrl;
  late TextEditingController _passCtrl;
  bool _obscurePass = true;

  @override
  void initState() {
    super.initState();
    _userCtrl = TextEditingController(text: widget.auth.username ?? '');
    _passCtrl = TextEditingController(text: widget.auth.password ?? '');
  }

  @override
  void dispose() {
    _userCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthField(
          label: 'Username',
          hint: 'Enter username',
          controller: _userCtrl,
          onChanged: (v) =>
              widget.onChanged(widget.auth.copyWith(username: v)),
        ),
        const SizedBox(height: 12),
        _AuthField(
          label: 'Password',
          hint: 'Enter password',
          controller: _passCtrl,
          obscureText: _obscurePass,
          suffixIcon: IconButton(
            icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off,
                size: 18),
            onPressed: () => setState(() => _obscurePass = !_obscurePass),
          ),
          onChanged: (v) =>
              widget.onChanged(widget.auth.copyWith(password: v)),
        ),
      ],
    );
  }
}

class _ApiKeyFields extends StatefulWidget {
  final AuthConfig auth;
  final ValueChanged<AuthConfig> onChanged;

  const _ApiKeyFields({required this.auth, required this.onChanged});

  @override
  State<_ApiKeyFields> createState() => _ApiKeyFieldsState();
}

class _ApiKeyFieldsState extends State<_ApiKeyFields> {
  late TextEditingController _nameCtrl;
  late TextEditingController _valueCtrl;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.auth.apiKeyName ?? '');
    _valueCtrl = TextEditingController(text: widget.auth.apiKeyValue ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _valueCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _AuthField(
          label: 'Key Name',
          hint: 'X-API-Key',
          controller: _nameCtrl,
          onChanged: (v) =>
              widget.onChanged(widget.auth.copyWith(apiKeyName: v)),
        ),
        const SizedBox(height: 12),
        _AuthField(
          label: 'Key Value',
          hint: 'Enter API key or {{apiKey}}',
          controller: _valueCtrl,
          onChanged: (v) =>
              widget.onChanged(widget.auth.copyWith(apiKeyValue: v)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Add to:',
              style: Theme.of(context).textTheme.labelMedium,
            ),
            const SizedBox(width: 12),
            ChoiceChip(
              label: const Text('Header', style: TextStyle(fontSize: 12)),
              selected: widget.auth.apiKeyIn == 'header',
              onSelected: (_) => widget.onChanged(
                  widget.auth.copyWith(apiKeyIn: 'header')),
              visualDensity: VisualDensity.compact,
            ),
            const SizedBox(width: 8),
            ChoiceChip(
              label: const Text('Query Param', style: TextStyle(fontSize: 12)),
              selected: widget.auth.apiKeyIn == 'query',
              onSelected: (_) => widget.onChanged(
                  widget.auth.copyWith(apiKeyIn: 'query')),
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ],
    );
  }
}

class _OAuth2Placeholder extends StatelessWidget {
  const _OAuth2Placeholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.construction, size: 16),
              SizedBox(width: 8),
              Text('OAuth 2.0', style: TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'OAuth 2.0 support is coming soon. You can manually add Authorization header in the Headers tab.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _AuthField extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool obscureText;
  final Widget? suffixIcon;

  const _AuthField({
    required this.label,
    required this.hint,
    required this.controller,
    required this.onChanged,
    this.obscureText = false,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          onChanged: onChanged,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 13, fontFamily: 'RobotoMono'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12),
            isDense: true,
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }
}
