class StorageKeys {
  StorageKeys._();

  // Hive box names
  static const String collectionsBox = 'collections_box';
  static const String environmentsBox = 'environments_box';
  static const String historyBox = 'history_box';
  static const String tabsBox = 'tabs_box';
  static const String workspacesBox = 'workspaces_box';

  // Hive keys
  static const String collectionsKey = 'collections';
  static const String environmentsKey = 'environments';
  static const String historyKey = 'history';
  static const String tabsKey = 'tabs';
  static const String activeTabKey = 'active_tab';
  static const String workspacesKey = 'workspaces';
  static const String activeWorkspaceKey = 'active_workspace';

  // SharedPreferences keys
  static const String themeMode = 'theme_mode';
  static const String activeEnvironmentId = 'active_environment_id';
  static const String sidebarWidth = 'sidebar_width';
  static const String isSidebarVisible = 'is_sidebar_visible';
  static const String activeWorkspaceId = 'active_workspace_id';
  static const String requestTimeout = 'request_timeout';
  static const String followRedirects = 'follow_redirects';
  static const String verifySsl = 'verify_ssl';
}
