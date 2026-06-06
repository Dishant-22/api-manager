import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/settings_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionHeader('Appearance'),
          _SettingsTile(
            title: 'Theme',
            subtitle: _themeModeLabel(settings.themeMode),
            icon: Icons.palette_outlined,
            trailing: DropdownButton<ThemeMode>(
              value: settings.themeMode,
              underline: const SizedBox(),
              items: ThemeMode.values
                  .map((m) => DropdownMenuItem(
                        value: m,
                        child: Text(_themeModeLabel(m),
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (m) => m != null ? notifier.setThemeMode(m) : null,
            ),
          ),
          const Divider(),
          const _SectionHeader('Network'),
          _SettingsTile(
            title: 'Request Timeout',
            subtitle: '${settings.requestTimeoutSeconds} seconds',
            icon: Icons.timer_outlined,
            trailing: DropdownButton<int>(
              value: settings.requestTimeoutSeconds,
              underline: const SizedBox(),
              items: [10, 15, 30, 60, 120]
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Text('${s}s',
                            style: const TextStyle(fontSize: 13)),
                      ))
                  .toList(),
              onChanged: (v) =>
                  v != null ? notifier.setRequestTimeout(v) : null,
            ),
          ),
          SwitchListTile(
            title: const Text('Follow Redirects'),
            subtitle: const Text(
                'Automatically follow HTTP 3xx redirects',
                style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.alt_route_outlined),
            value: settings.followRedirects,
            onChanged: notifier.setFollowRedirects,
            dense: true,
          ),
          SwitchListTile(
            title: const Text('Verify SSL Certificates'),
            subtitle: const Text(
                'Validate SSL certificates for HTTPS requests',
                style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.security_outlined),
            value: settings.verifySsl,
            onChanged: notifier.setVerifySsl,
            dense: true,
          ),
          const Divider(),
          const _SectionHeader('History'),
          SwitchListTile(
            title: const Text('Auto-save Request History'),
            subtitle: const Text(
                'Automatically save each request to history',
                style: TextStyle(fontSize: 12)),
            secondary: const Icon(Icons.history),
            value: settings.autoSaveHistory,
            onChanged: (v) =>
                notifier.setAutoSaveHistory(v),
            dense: true,
          ),
          const Divider(),
          const _SectionHeader('About'),
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('API Managers'),
            subtitle: Text('v1.0.0 — Professional API testing tool',
                style: TextStyle(fontSize: 12)),
            dense: true,
          ),
        ],
      ),
    );
  }

  String _themeModeLabel(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.system:
        return 'System';
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget trailing;

  const _SettingsTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: trailing,
      dense: true,
    );
  }
}
