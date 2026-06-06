class AppConstants {
  AppConstants._();

  static const String appName = 'API Managers';
  static const String appVersion = '1.0.0';

  static const double sidebarDefaultWidth = 260.0;
  static const double sidebarMinWidth = 180.0;
  static const double sidebarMaxWidth = 480.0;

  static const double responsePanelMinHeight = 120.0;

  static const int requestTimeoutSeconds = 30;
  static const int maxHistoryEntries = 500;
  static const int maxTabs = 20;

  static const List<String> httpMethods = [
    'GET',
    'POST',
    'PUT',
    'PATCH',
    'DELETE',
    'HEAD',
    'OPTIONS',
  ];

  static const List<String> contentTypes = [
    'application/json',
    'application/x-www-form-urlencoded',
    'multipart/form-data',
    'application/xml',
    'text/plain',
    'text/html',
  ];

  static const Map<String, String> defaultHeaders = {
    'Accept': '*/*',
    'User-Agent': 'API-Managers/1.0',
  };

  static const List<String> sampleApis = [
    'https://jsonplaceholder.typicode.com/posts',
    'https://jsonplaceholder.typicode.com/users',
    'https://api.github.com/repos/flutter/flutter',
    'https://httpbin.org/get',
    'https://httpbin.org/post',
  ];
}
