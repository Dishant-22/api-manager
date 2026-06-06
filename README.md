# API Managers

A professional, cross-platform API testing application built with Flutter — a full-featured Postman alternative for Windows, macOS, Linux, Web, Android, and iOS.

---

## Features

- **Multi-tab interface** — open and manage multiple requests simultaneously, persisted across restarts
- **Full HTTP method support** — GET, POST, PUT, PATCH, DELETE, HEAD, OPTIONS
- **Request builder** — query params, headers, auth (Bearer Token, Basic Auth, API Key), and body editors (JSON, form-data, URL-encoded, XML, plain text)
- **Variable highlighting** — `{{variable}}` placeholders are highlighted inline in the URL bar and value fields
- **Environment management** — create environments with key/value variables, set an active environment, and use `{{variable}}` interpolation across all requests
- **Collections** — organise saved requests into collections and folders with a searchable tree view
- **Request history** — auto-saved history with search, retry, and delete
- **Response viewer** — syntax-highlighted body, status code, response time, size, and headers panel
- **Code generator** — export any request as cURL, Dart (Dio), JavaScript (Fetch / Axios), Python (Requests), or Java (OkHttp)
- **Resizable panels** — 3-panel desktop layout with draggable dividers; bottom-nav layout on mobile
- **Material 3 design** — dark / light mode toggle, consistent theming across all platforms
- **Custom title bar** — native title bar removed on desktop; replaced with a draggable header and Minimize / Fullscreen / Close window controls

---

## Tech Stack

| Layer | Package |
|---|---|
| State management | `flutter_riverpod ^2.6.1` |
| Navigation | `go_router ^14.8.1` |
| HTTP client | `dio ^5.8.0+1` |
| Local storage | `hive_flutter ^1.1.0` |
| Settings | `shared_preferences ^2.3.5` |
| Theming | `flex_color_scheme ^8.2.0` |
| Syntax highlighting | `flutter_highlight ^0.7.0` |
| File picker | `file_picker ^8.0.0` |
| Desktop window | `window_manager ^0.4.3` |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.10.0`
- Dart SDK `>=3.0.0`

### Run locally

```bash
# Clone the repository
git clone https://github.com/dishant-chudasama/api_managers.git
cd api_managers

# Install dependencies
flutter pub get

# Run on Windows (or any target platform)
flutter run -d windows
```

### Supported platforms

| Platform | Status |
|---|---|
| Windows | ✅ |
| macOS | ✅ |
| Linux | ✅ |
| Web | ✅ |
| Android | ✅ |
| iOS | ✅ |

---

## Build & Distribute (Windows)

Build a release binary:

```bash
flutter build windows --release
```

Create an MSIX installer:

```bash
flutter pub run msix:create
```

The installer is output to `installer/APIManagers-Setup.msix`. To install without a code-signing certificate (development/testing):

```powershell
# Run PowerShell as Administrator
Add-AppxPackage installer\APIManagers-Setup.msix
```

---

## Project Structure

```
lib/
├── config/          # Router configuration
├── core/            # Constants, theme, extensions, utilities
├── features/
│   ├── collections/ # Collections panel, models, provider
│   ├── environments/# Environment management, variable resolution
│   ├── history/     # Request history panel
│   ├── home/        # Desktop & mobile shell, tab bar, title bar
│   ├── requests/    # Request builder, response panel, tabs
│   └── settings/    # App settings screen and provider
├── services/
│   ├── http/        # Dio client with variable interpolation
│   └── storage/     # Hive persistence service
└── shared/
    └── widgets/     # Reusable widgets (KeyValueEditor, VariableTextField, …)
```

---

## License

MIT © [Dishant Chudasama](https://dishant-chudasama.com)
