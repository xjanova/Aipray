import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../main.dart';

/// A release offered by xman4289.com, with what the app needs to check the
/// file before installing it.
class AppVersion {
  final String version;
  final Uri downloadUrl;
  final String releaseNotes;
  final int fileSize;
  final String sha256;

  const AppVersion({
    required this.version,
    required this.downloadUrl,
    required this.releaseNotes,
    required this.fileSize,
    required this.sha256,
  });

  /// Reads the answer of `GET /api/v1/product/aipray/update/check`.
  ///
  /// Returns null unless the file can be verified before it is installed: it
  /// has to come from xman4289.com over https, with a known size and SHA-256.
  static AppVersion? fromUpdateCheck(Map<String, dynamic> json) {
    final version = _text(json['latest_version']).replaceFirst(RegExp(r'^v'), '');
    final url = Uri.tryParse(_text(json['download_url']));
    final sha256 = _text(json['sha256']).toLowerCase();
    final fileSize = _wholeNumber(json['file_size']);

    if (!RegExp(r'^\d+(\.\d+)*$').hasMatch(version)) return null;
    if (url == null ||
        url.scheme != 'https' ||
        url.host != UpdateService.host ||
        url.userInfo.isNotEmpty ||
        (url.hasPort && url.port != 443)) {
      return null;
    }
    if (!RegExp(r'^[0-9a-f]{64}$').hasMatch(sha256)) return null;
    if (fileSize == null || fileSize <= 0 || fileSize > UpdateService.maxApkBytes) {
      return null;
    }

    return AppVersion(
      version: version,
      downloadUrl: url,
      releaseNotes: _text(json['changelog']),
      fileSize: fileSize,
      sha256: sha256,
    );
  }

  static String _text(Object? value) => value is String ? value.trim() : '';

  static int? _wholeNumber(Object? value) {
    if (value is int) return value;
    if (value is double && value == value.truncateToDouble()) return value.toInt();
    if (value is String) return int.tryParse(value.trim());
    return null;
  }
}

class UpdateService {
  static const String currentVersion = '1.2.4';

  /// The only place the app checks for or downloads updates.
  static const String host = 'xman4289.com';

  /// Refuse anything bigger, whatever the server claims.
  static const int maxApkBytes = 1024 * 1024 * 1024;

  static final Uri _checkUrl = Uri.https(
    host,
    '/api/v1/product/aipray/update/check',
    {'current_version': currentVersion},
  );
  static const String _checkKey = 'last_update_check';
  static const String _skipVersionKey = 'skip_version';
  static const String _apkName = 'aipray_update.apk';

  /// Longest wait for the next piece of the download before giving up.
  static const Duration _stallTimeout = Duration(seconds: 30);

  UpdateService({
    http.Client Function()? httpClient,
    Future<Directory> Function()? downloadDir,
  })  : _newClient = httpClient ?? http.Client.new,
        _downloadDir = downloadDir ?? getTemporaryDirectory;

  final http.Client Function() _newClient;
  final Future<Directory> Function() _downloadDir;

  final ValueNotifier<UpdateState> state = ValueNotifier(UpdateState.idle);
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);

  AppVersion? latestVersion;
  String? downloadedFilePath;
  Future<UpdateCheckResult>? _checking;

  /// An update the user can still act on: offered, downloading, downloaded,
  /// or failed and waiting for a retry.
  bool get hasPendingUpdate =>
      latestVersion != null &&
      const {
        UpdateState.updateAvailable,
        UpdateState.downloading,
        UpdateState.readyToInstall,
        UpdateState.installing,
        UpdateState.error,
      }.contains(state.value);

  /// Check xman4289.com for a newer release.
  Future<UpdateCheckResult> checkForUpdate({bool force = false}) {
    // An update already being downloaded or installed is the answer; a new
    // check must not reset it underneath the dialog.
    switch (state.value) {
      case UpdateState.downloading:
      case UpdateState.readyToInstall:
      case UpdateState.installing:
        return Future.value(UpdateCheckResult.updateAvailable);
      default:
        return _checking ??= _check(force).whenComplete(() => _checking = null);
    }
  }

  Future<UpdateCheckResult> _check(bool force) async {
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
    final client = _newClient();

    try {
      final response = await client
          .get(_checkUrl, headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        state.value = UpdateState.idle;
        return UpdateCheckResult.error;
      }

      // The server sends no charset; JSON is UTF-8, and the notes are Thai.
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (data is! Map<String, dynamic>) {
        state.value = UpdateState.idle;
        return UpdateCheckResult.error;
      }

      await storageService.setSetting(_checkKey, DateTime.now().toIso8601String());

      final latest = data['latest_version'];
      if (data['has_update'] != true ||
          latest is! String ||
          !_isNewerVersion(latest.trim().replaceFirst(RegExp(r'^v'), ''), currentVersion)) {
        latestVersion = null;
        state.value = UpdateState.idle;
        await _deleteDownloads();
        return UpdateCheckResult.noUpdate;
      }

      final offer = AppVersion.fromUpdateCheck(data);
      latestVersion = offer;
      if (offer == null) {
        // A newer release exists, but not one the app could verify.
        debugPrint('Update check: unusable offer for $latest');
        state.value = UpdateState.idle;
        return UpdateCheckResult.error;
      }

      // Check if user skipped this version
      final skippedVersion = storageService.getSetting<String>(_skipVersionKey);
      if (!force && skippedVersion == offer.version) {
        state.value = UpdateState.idle;
        return UpdateCheckResult.skipped;
      }

      state.value = UpdateState.updateAvailable;
      return UpdateCheckResult.updateAvailable;
    } catch (e) {
      debugPrint('Update check failed: $e');
      state.value = UpdateState.idle;
      return UpdateCheckResult.error;
    } finally {
      client.close();
    }
  }

  /// Download the APK, and keep it only if its size and SHA-256 match what
  /// the update check promised.
  Future<bool> downloadUpdate() async {
    final version = latestVersion;
    if (version == null) return false;
    if (state.value != UpdateState.updateAvailable && state.value != UpdateState.error) {
      return false; // already downloading, or done
    }

    state.value = UpdateState.downloading;
    downloadProgress.value = 0.0;
    downloadedFilePath = null;

    final client = _newClient();
    File? partFile;
    IOSink? sink;

    try {
      final dir = await _downloadDir();
      partFile = File('${dir.path}/$_apkName.part');
      final apkFile = File('${dir.path}/$_apkName');

      // A redirect would take the download off xman4289.com; refuse it.
      final request = http.Request('GET', version.downloadUrl)..followRedirects = false;
      final response = await client.send(request).timeout(_stallTimeout);

      if (response.statusCode != 200) {
        throw HttpException('HTTP ${response.statusCode}', uri: version.downloadUrl);
      }
      final announced = response.contentLength;
      if (announced != null && announced != version.fileSize) {
        throw HttpException(
          'size $announced, expected ${version.fileSize}',
          uri: version.downloadUrl,
        );
      }

      final digest = _DigestSink();
      final hasher = crypto.sha256.startChunkedConversion(digest);
      sink = partFile.openWrite();
      int received = 0;

      await for (final chunk in response.stream.timeout(_stallTimeout)) {
        received += chunk.length;
        if (received > version.fileSize) {
          throw HttpException(
            'more than the expected ${version.fileSize} bytes',
            uri: version.downloadUrl,
          );
        }
        hasher.add(chunk);
        sink.add(chunk);
        downloadProgress.value = received / version.fileSize;
      }

      await sink.flush();
      await sink.close();
      sink = null; // prevent double-close below
      hasher.close();

      if (received != version.fileSize) {
        throw HttpException(
          'got $received of ${version.fileSize} bytes',
          uri: version.downloadUrl,
        );
      }
      if (digest.value.toString() != version.sha256) {
        throw HttpException('SHA-256 mismatch', uri: version.downloadUrl);
      }

      downloadedFilePath = (await partFile.rename(apkFile.path)).path;
      state.value = UpdateState.readyToInstall;
      return true;
    } catch (e) {
      debugPrint('Update download failed: $e');
      try {
        await sink?.close();
      } catch (_) {}
      try {
        if (partFile != null && await partFile.exists()) await partFile.delete();
      } catch (_) {}
      state.value = UpdateState.error;
      return false;
    } finally {
      client.close();
    }
  }

  /// Install the downloaded APK via native MethodChannel.
  /// Uses FileProvider for Android 7+ content:// URI compatibility.
  Future<bool> installUpdate() async {
    final filePath = downloadedFilePath;
    if (filePath == null || kIsWeb || !Platform.isAndroid) return false;
    if (state.value != UpdateState.readyToInstall) return false;

    state.value = UpdateState.installing;

    try {
      const channel = MethodChannel('com.xjanova.aipray/installer');

      // Check if we have install permission; carry on once the user allows it
      final canInstall = await channel.invokeMethod<bool>('canRequestInstall');
      if (canInstall != true) {
        final allowed = await channel.invokeMethod<bool>('requestInstallPermission');
        if (allowed != true) {
          state.value = UpdateState.readyToInstall;
          return false;
        }
      }

      await channel.invokeMethod('installApk', {'filePath': filePath});
      // Android's installer takes over from here. If the user backs out of
      // it, the same file can be installed again.
      state.value = UpdateState.readyToInstall;
      return true;
    } on PlatformException catch (e) {
      debugPrint('Install failed: ${e.message}');
      state.value = UpdateState.error;
      return false;
    } catch (e) {
      debugPrint('Install failed: $e');
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

  /// Remove an APK left over from an update that is now installed.
  Future<void> _deleteDownloads() async {
    downloadedFilePath = null;
    try {
      final dir = await _downloadDir();
      for (final name in [_apkName, '$_apkName.part']) {
        final file = File('${dir.path}/$name');
        if (await file.exists()) await file.delete();
      }
    } catch (e) {
      debugPrint('Could not remove old update files: $e');
    }
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

/// Receives the digest when a chunked SHA-256 conversion is closed.
class _DigestSink implements Sink<crypto.Digest> {
  crypto.Digest? value;

  @override
  void add(crypto.Digest data) => value = data;

  @override
  void close() {}
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
