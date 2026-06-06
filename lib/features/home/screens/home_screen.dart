import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';
import '../../../features/collections/screens/collections_panel.dart';
import '../../../features/environments/providers/environment_provider.dart';
import '../../../features/environments/screens/environments_screen.dart';
import '../../../features/history/screens/history_panel.dart';
import '../../../features/requests/providers/tab_provider.dart';
import '../../../features/requests/models/request_tab.dart';
import '../../../features/requests/screens/request_screen.dart';
import '../../../features/settings/providers/settings_provider.dart';
import '../../../features/settings/screens/settings_screen.dart';
import '../../../shared/widgets/method_badge.dart';
import '../../../shared/widgets/resizable_panel.dart';
import '../../../main.dart' show isDesktopPlatform;

enum SidebarSection { collections, history }

final _sidebarSectionProvider =
    StateProvider<SidebarSection>((ref) => SidebarSection.collections);

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final isDesktop = MediaQuery.of(context).size.width >= 900;

    if (isDesktop) {
      return _DesktopLayout(settings: settings);
    }
    return _MobileLayout(settings: settings);
  }
}

// ─── Desktop Layout ─────────────────────────────────────────────────────────

class _DesktopLayout extends ConsumerWidget {
  final dynamic settings;

  const _DesktopLayout({required this.settings});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appSettings = ref.watch(settingsProvider);

    return Scaffold(
      body: Column(
        children: [
          _AppTopBar(),
          Expanded(
            child: ResizableHorizontalPanel(
              initialWidth: appSettings.sidebarWidth,
              minWidth: 180,
              leftVisible: appSettings.isSidebarVisible,
              left: _Sidebar(),
              right: _MainArea(),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mobile Layout ───────────────────────────────────────────────────────────

class _MobileLayout extends ConsumerStatefulWidget {
  final dynamic settings;
  const _MobileLayout({required this.settings});

  @override
  ConsumerState<_MobileLayout> createState() => _MobileLayoutState();
}

class _MobileLayoutState extends ConsumerState<_MobileLayout> {
  int _bottomIndex = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Managers', style: TextStyle(fontSize: 16)),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () =>
                ref.read(tabProvider.notifier).addTab(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _bottomIndex,
        children: [
          const CollectionsPanel(),
          _MainArea(),
          const HistoryPanel(),
          const SettingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _bottomIndex,
        onDestinationSelected: (i) => setState(() => _bottomIndex = i),
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.folder_outlined),
              selectedIcon: Icon(Icons.folder),
              label: 'Collections'),
          NavigationDestination(
              icon: Icon(Icons.send_outlined),
              selectedIcon: Icon(Icons.send),
              label: 'Request'),
          NavigationDestination(
              icon: Icon(Icons.history),
              label: 'History'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

// ─── App Top Bar ─────────────────────────────────────────────────────────────

class _AppTopBar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final envState = ref.watch(environmentProvider);
    final theme = Theme.of(context);

    final bar = Container(
      height: 44,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          // App icon + name
          Icon(Icons.api, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            'API Managers',
            style: theme.textTheme.titleSmall
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(width: 16),
          // Sidebar toggle
          IconButton(
            icon: Icon(
              settings.isSidebarVisible
                  ? Icons.view_sidebar
                  : Icons.view_sidebar_outlined,
              size: 18,
            ),
            onPressed: () =>
                ref.read(settingsProvider.notifier).toggleSidebar(),
            tooltip: 'Toggle sidebar',
            visualDensity: VisualDensity.compact,
          ),
          const Spacer(),
          // Environment selector
          _EnvironmentSelector(
            environments: envState.environments
                .where((e) => !e.isGlobal)
                .toList(),
            activeId: envState.activeEnvironmentId,
            onChanged: (id) => ref
                .read(environmentProvider.notifier)
                .setActiveEnvironment(id),
          ),
          const SizedBox(width: 8),
          // Environments button
          TextButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const EnvironmentsScreen()),
            ),
            icon: const Icon(Icons.tune, size: 16),
            label: const Text('Environments',
                style: TextStyle(fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
          const SizedBox(width: 8),
          // Settings
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 18),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                  builder: (_) => const SettingsScreen()),
            ),
            tooltip: 'Settings',
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 8),
          // Theme toggle
          IconButton(
            icon: Icon(
              theme.brightness == Brightness.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
              size: 18,
            ),
            onPressed: () {
              final next = theme.brightness == Brightness.dark
                  ? ThemeMode.light
                  : ThemeMode.dark;
              ref.read(settingsProvider.notifier).setThemeMode(next);
            },
            tooltip: 'Toggle theme',
            visualDensity: VisualDensity.compact,
          ),
          // Custom window controls (desktop only, no native title bar)
          if (isDesktopPlatform) const _WindowControls(),
        ],
      ),
    );

    // Wrap in DragToMoveArea on desktop so the bar acts as a drag handle.
    // Interactive widgets inside still receive their own events first.
    if (isDesktopPlatform) {
      return DragToMoveArea(child: bar);
    }
    return bar;
  }
}

// ─── Custom Window Controls ──────────────────────────────────────────────────

class _WindowControls extends StatefulWidget {
  const _WindowControls();

  @override
  State<_WindowControls> createState() => _WindowControlsState();
}

class _WindowControlsState extends State<_WindowControls>
    with WindowListener {
  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    windowManager.isFullScreen().then((v) {
      if (mounted) setState(() => _isFullScreen = v);
    });
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowEnterFullScreen() =>
      setState(() => _isFullScreen = true);

  @override
  void onWindowLeaveFullScreen() =>
      setState(() => _isFullScreen = false);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(width: 4),
        _WinBtn(
          icon: Icons.remove,
          tooltip: 'Minimize',
          onTap: () => windowManager.minimize(),
        ),
        _WinBtn(
          icon: _isFullScreen
              ? Icons.fullscreen_exit
              : Icons.fullscreen,
          tooltip: _isFullScreen ? 'Exit fullscreen' : 'Fullscreen',
          onTap: () =>
              windowManager.setFullScreen(!_isFullScreen),
        ),
        _WinBtn(
          icon: Icons.close,
          tooltip: 'Close',
          isClose: true,
          onTap: () => windowManager.close(),
        ),
      ],
    );
  }
}

class _WinBtn extends StatefulWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool isClose;

  const _WinBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.isClose = false,
  });

  @override
  State<_WinBtn> createState() => _WinBtnState();
}

class _WinBtnState extends State<_WinBtn> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hoverBg = widget.isClose
        ? Colors.red
        : theme.colorScheme.onSurface.withAlpha(25);
    final iconColor = (_hover && widget.isClose)
        ? Colors.white
        : theme.colorScheme.onSurface.withAlpha(180);

    return Tooltip(
      message: widget.tooltip,
      waitDuration: const Duration(milliseconds: 600),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: Container(
            width: 44,
            height: 44,
            color: _hover ? hoverBg : Colors.transparent,
            child: Icon(widget.icon, size: 16, color: iconColor),
          ),
        ),
      ),
    );
  }
}

class _EnvironmentSelector extends StatelessWidget {
  final List<dynamic> environments;
  final String? activeId;
  final ValueChanged<String?> onChanged;

  const _EnvironmentSelector({
    required this.environments,
    required this.activeId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final activeEnv = environments
        .where((e) => e.id == activeId)
        .firstOrNull;

    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(6),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String?>(
          value: activeId,
          hint: const Text('No environment',
              style: TextStyle(fontSize: 12)),
          style: TextStyle(
            fontSize: 12,
            color: activeEnv != null
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurface.withAlpha(160),
          ),
          icon: const Icon(Icons.keyboard_arrow_down, size: 14),
          items: [
            const DropdownMenuItem<String?>(
              child: Text('No environment',
                  style: TextStyle(fontSize: 12)),
            ),
            ...environments.map((e) => DropdownMenuItem<String?>(
                  value: e.id as String,
                  child: Text(e.name as String,
                      style: const TextStyle(fontSize: 12)),
                )),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// ─── Sidebar ─────────────────────────────────────────────────────────────────

class _Sidebar extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final section = ref.watch(_sidebarSectionProvider);
    final theme = Theme.of(context);

    return Column(
      children: [
        // Sidebar nav tabs
        Container(
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              _SidebarTab(
                icon: Icons.folder_outlined,
                label: 'Collections',
                selected: section == SidebarSection.collections,
                onTap: () => ref.read(_sidebarSectionProvider.notifier).state =
                    SidebarSection.collections,
              ),
              _SidebarTab(
                icon: Icons.history,
                label: 'History',
                selected: section == SidebarSection.history,
                onTap: () => ref.read(_sidebarSectionProvider.notifier).state =
                    SidebarSection.history,
              ),
            ],
          ),
        ),
        Divider(height: 1, color: theme.dividerColor),
        Expanded(
          child: section == SidebarSection.collections
              ? const CollectionsPanel()
              : const HistoryPanel(),
        ),
      ],
    );
  }
}

class _SidebarTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: selected
                    ? theme.colorScheme.primary
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 16,
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withAlpha(140),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurface.withAlpha(140),
                  fontWeight:
                      selected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Main Area (Tab Bar + Request Screen) ────────────────────────────────────

class _MainArea extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabState = ref.watch(tabProvider);

    return Column(
      children: [
        _RequestTabBar(tabState: tabState),
        Expanded(
          child: tabState.tabs.isEmpty
              ? const Center(child: Text('No tabs open'))
              : RequestScreen(tabIndex: tabState.clampedIndex),
        ),
      ],
    );
  }
}

class _RequestTabBar extends ConsumerWidget {
  final TabState tabState;
  const _RequestTabBar({required this.tabState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.dividerColor, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: tabState.tabs.length,
              itemBuilder: (ctx, i) => _TabChip(
                tab: tabState.tabs[i],
                isActive: i == tabState.clampedIndex,
                onTap: () => ref.read(tabProvider.notifier).setActiveTab(i),
                onClose: () => ref.read(tabProvider.notifier).closeTab(i),
              ),
            ),
          ),
          // New tab button
          IconButton(
            icon: const Icon(Icons.add, size: 16),
            onPressed: () => ref.read(tabProvider.notifier).addTab(),
            tooltip: 'New Tab (Ctrl+T)',
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final RequestTab tab;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _TabChip({
    required this.tab,
    required this.isActive,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLoading = tab.status == TabStatus.loading;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minWidth: 120, maxWidth: 220),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: isActive
              ? theme.colorScheme.surfaceContainerHighest
              : Colors.transparent,
          border: Border(
            bottom: BorderSide(
              color: isActive
                  ? theme.colorScheme.primary
                  : Colors.transparent,
              width: 2,
            ),
            right: BorderSide(
                color: theme.dividerColor.withAlpha(80), width: 0.5),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 1.5),
              )
            else
              MethodBadge(method: tab.request.method, fontSize: 8),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                tab.title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight:
                      isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurface.withAlpha(160),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            InkWell(
              onTap: onClose,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 12,
                  color: theme.colorScheme.onSurface.withAlpha(120),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
