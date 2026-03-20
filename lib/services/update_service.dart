import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../main.dart';

class AppVersion {
  final String version;
  final String downloadUrl;
  final String releaseNotes;
  final int fileSize;
  final DateTime publishedAt;

  AppVersion({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.publishedAt,
  });

  factory AppVersion.fromGitHubRelease(Map<String, dynamic> json) {
    final tag = (json['tag_name'] as String? ?? '').replaceFirst('v', '');
    final assets = json['assets'] as List? ?? [];
    String downloadUrl = '';
    int fileSize = 0;

    for (final asset in assets) {
      final name = asset['name'] as String? ?? '';
      if (name.endsWith('.apk')) {
        downloadUrl = asset['browser_download_url'] as String? ?? '';
        fileSize = asset['size'] as int? ?? 0;
        break;
      }
    }

    return AppVersion(
      version: tag,
      downloadUrl: downloadUrl,
      releaseNotes: json['body'] as String? ?? '',
      fileSize: fileSize,
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? '') ?? DateTime.now(),
    );
  }
}

class UpdateService {
  static const String currentVersion = '1.2.0';
  static const String _githubRepo = 'xjanova/Aipray';
  static const String _apiUrl = 'https://api.github.com/repos/$_githubRepo/releases/latest';
  static const String _checkKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';

  final ValueNotifier<UpdateState> state = ValueNotifier(UpdateState.idle);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  AppVersion? latestVersion;
  String? downloadedFilePath;

  /// Check for updates from GitHub Releases
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) async {
    // Don't check more than once per hour unless forced
    if (!force) {
      final lastCheck = storageService.getSetting<String>(_checkKey);
      if (lastCheck != null) {
        final lastTime = DateTime.tryParse(lastCheck);
        if (lastTime != null && DateTime.now().difference(lastTime).inHours < 1) {
          return UpdateCheckResult.alreadyChecked;
        }
      }
    }

    state.value = UpdateState.checking;

    try {
      final response = await http.get(
        Uri.parse(_apiUrl),
        headers: {'Accept': 'application/vnd.github.v3+json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        state.value = UpdateState.idle;
        return UpdateCheckResult.error;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      latestVersion = AppVersion.fromGitHubRelease(data);

      await storageService.setSetting(_checkKey, DateTime.now().toIso8601String());

      if (latestVersion!.downloadUrl.isEmpty) {
        state.value = UpdateState.idle;
        return UpdateCheckResult.noUpdate;
      }

      if (_isNewerVersion(latestVersion!.version, currentVersion)) {
        // Check if user skipped this version
        final skippedVersion = storageService.getSetting<String>(_skipVersionKey);
        if (!force && skippedVersion == latestVersion!.version) {
          state.value = UpdateState.idle;
          return UpdateCheckResult.skipped;
        }

        state.value = UpdateState.updateAvailable;
        return UpdateCheckResult.updateAvailable;
      }

      state.value = UpdateState.idle;
      return UpdateCheckResult.noUpdate;
    } catch (e) {
      state.value = UpdateState.idle;
      return UpdateCheckResult.error;
    }
  }

  /// Download the APK update
  Future<bool> downloadUpdate() async {
    if (latestVersion == null || latestVersion!.downloadUrl.isEmpty) return false;

    state.value = UpdateState.downloading;
    downloadProgress.value = 0.0;

    http.Client? client;
    IOSink? sink;

    try {
      client = http.Client();
      final request = http.Request('GET', Uri.parse(latestVersion!.downloadUrl));
      final response = await client.send(request).timeout(const Duration(minutes: 10));

      if (response.statusCode != 200) {
        state.value = UpdateState.error;
        return false;
      }

      final contentLength = response.contentLength ?? latestVersion!.fileSize;
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/aipray_update.apk');

      sink = file.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (contentLength > 0) {
          downloadProgress.value = received / contentLength;
        }
      }

      await sink.flush();
      await sink.close();
      sink = null; // prevent double-close in finally

      downloadedFilePath = file.path;
      state.value = UpdateState.readyToInstall;
      return true;
    } catch (e) {
      state.value = UpdateState.error;
      return false;
    } finally {
      try { sink?.close(); } catch (_) {}
      client?.close();
    }
  }

  /// Install the downloaded APK (Android only).
  /// Opens the system package installer via content:// URI.
  Future<bool> installUpdate() async {
    if (downloadedFilePath == null || kIsWeb) return false;

    state.value = UpdateState.installing;

    try {
      if (Platform.isAndroid) {
        // Use content:// URI via FileProvider for Android 7+ compatibility.
        // The actual installation is triggered by opening the APK file with
        // the system package installer intent.
        final result = await Process.run('am', [
          'start',
          '-a', 'android.intent.action.INSTALL_PACKAGE',
          '-t', 'application/vnd.android.package-archive',
          '-d', 'file://$downloadedFilePath',
          '-n', 'com.android.packageinstaller/.PackageInstallerActivity',
          '--grant-read-uri-permission',
        ]);
        return result.exitCode == 0;
      }
      return false;
    } catch (e) {
      state.value = UpdateState.error;
      return false;
    }
  }

  /// Skip this version
  Future<void> skipVersion() async {
    if (latestVersion != null) {
      await storageService.setSetting(_skipVersionKey, latestVersion!.version);
    }
    state.value = UpdateState.idle;
  }

  /// Compare version strings (e.g. "1.2.0" > "1.1.0")
  bool _isNewerVersion(String remote, String current) {
    final rParts = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final cParts = current.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final len = rParts.length > cParts.length ? rParts.length : cParts.length;

    for (int i = 0; i < len; i++) {
      final r = i < rParts.length ? rParts[i] : 0;
      final c = i < cParts.length ? cParts[i] : 0;
      if (r > c) return true;
      if (r < c) return false;
    }
    return false;
  }

  String get fileSizeFormatted {
    if (latestVersion == null) return '';
    final bytes = latestVersion!.fileSize;
    if (bytes > 1048576) return '${(bytes / 1048576).toStringAsFixed(1)} MB';
    if (bytes > 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
    return '$bytes B';
  }

  void dispose() {
    state.dispose();
    downloadProgress.dispose();
  }
}

enum UpdateState {
  idle,
  checking,
  updateAvailable,
  downloading,
  readyToInstall,
  installing,
  error,
}

enum UpdateCheckResult {
  noUpdate,
  updateAvailable,
  alreadyChecked,
  skipped,
  error,
}
