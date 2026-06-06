import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class AppSettings extends Equatable {
  final ThemeMode themeMode;
  final int requestTimeoutSeconds;
  final bool followRedirects;
  final bool verifySsl;
  final double sidebarWidth;
  final bool isSidebarVisible;
  final String? activeEnvironmentId;
  final String? activeWorkspaceId;
  final bool sendDefaultHeaders;
  final bool autoSaveHistory;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.requestTimeoutSeconds = 30,
    this.followRedirects = true,
    this.verifySsl = true,
    this.sidebarWidth = 260.0,
    this.isSidebarVisible = true,
    this.activeEnvironmentId,
    this.activeWorkspaceId,
    this.sendDefaultHeaders = true,
    this.autoSaveHistory = true,
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? requestTimeoutSeconds,
    bool? followRedirects,
    bool? verifySsl,
    double? sidebarWidth,
    bool? isSidebarVisible,
    String? activeEnvironmentId,
    String? activeWorkspaceId,
    bool? sendDefaultHeaders,
    bool? autoSaveHistory,
    bool clearActiveEnvironment = false,
  }) =>
      AppSettings(
        themeMode: themeMode ?? this.themeMode,
        requestTimeoutSeconds:
            requestTimeoutSeconds ?? this.requestTimeoutSeconds,
        followRedirects: followRedirects ?? this.followRedirects,
        verifySsl: verifySsl ?? this.verifySsl,
        sidebarWidth: sidebarWidth ?? this.sidebarWidth,
        isSidebarVisible: isSidebarVisible ?? this.isSidebarVisible,
        activeEnvironmentId: clearActiveEnvironment
            ? null
            : (activeEnvironmentId ?? this.activeEnvironmentId),
        activeWorkspaceId: activeWorkspaceId ?? this.activeWorkspaceId,
        sendDefaultHeaders: sendDefaultHeaders ?? this.sendDefaultHeaders,
        autoSaveHistory: autoSaveHistory ?? this.autoSaveHistory,
      );

  @override
  List<Object?> get props => [
        themeMode,
        requestTimeoutSeconds,
        followRedirects,
        verifySsl,
        sidebarWidth,
        isSidebarVisible,
        activeEnvironmentId,
        activeWorkspaceId,
        sendDefaultHeaders,
        autoSaveHistory,
      ];
}
