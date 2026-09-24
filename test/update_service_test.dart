import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:aipray/main.dart';
import 'package:aipray/services/update_service.dart';
import 'package:crypto/crypto.dart' as crypto;
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

final apkBytes = List<int>.generate(300000, (i) => (i * 31 + 7) % 256);
final apkSha256 = crypto.sha256.convert(apkBytes).toString();

/// The shape xman4289.com's update/check answers with.
Map<String, dynamic> offer({
  bool hasUpdate = true,
  String version = '9.9.9',
  Object? downloadUrl = 'https://xman4289.com/apps/aipray/download/9.9.9',
  Object? sha256,
  Object? fileSize,
}) =>
    {
      'has_update': hasUpdate,
      'latest_version': version,
      'download_url': downloadUrl,
      'changelog': '## Aipray v$version - สวดมนต์อัจฉริยะ',
      'sha256': sha256 ?? apkSha256,
      'file_size': fileSize ?? apkBytes.length,
      'filename': 'aipray-$version-universal.apk',
    };

http.Response jsonResponse(Object body, [int status = 200]) => http.Response.bytes(
      utf8.encode(jsonEncode(body)),
      status,
      headers: {'content-type': 'application/json'},
    );

void main() {
  late Directory dir;
  final requests = <http.BaseRequest>[];

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await storageService.init();
  });

  setUp(() async {
    await (await SharedPreferences.getInstance()).clear();
    dir = await Directory.systemTemp.createTemp('aipray_update_test');
    requests.clear();
  });

  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  /// A service whose update check returns [check] and whose download
  /// streams [chunks] (the real file unless given).
  UpdateService service({
    http.Response? check,
    List<List<int>>? chunks,
    int status = 200,
    int? contentLength,
    bool announceLength = true,
    Map<String, String> headers = const {},
  }) {
    final client = MockClient.streaming((request, _) async {
      requests.add(request);
      if (request.url.path.endsWith('/update/check')) {
        final response = check ?? jsonResponse(offer());
        return http.StreamedResponse(
          Stream.value(response.bodyBytes),
          response.statusCode,
          headers: response.headers,
        );
      }
      final body = chunks ?? [apkBytes.sublist(0, 100000), apkBytes.sublist(100000)];
      return http.StreamedResponse(
        Stream.fromIterable(body),
        status,
        contentLength: announceLength
            ? contentLength ?? body.fold<int>(0, (n, c) => n + c.length)
            : null,
        headers: headers,
      );
    });
    return UpdateService(httpClient: () => client, downloadDir: () async => dir);
  }

  List<String> filesLeft() =>
      dir.listSync().map((e) => e.uri.pathSegments.last).toList();

  group('AppVersion.fromUpdateCheck', () {
    test('reads a valid offer', () {
      final v = AppVersion.fromUpdateCheck(offer(version: 'v1.2.5'))!;
      expect(v.version, '1.2.5');
      expect(v.downloadUrl.toString(), 'https://xman4289.com/apps/aipray/download/9.9.9');
      expect(v.sha256, apkSha256);
      expect(v.fileSize, apkBytes.length);
      expect(v.releaseNotes, contains('สวดมนต์'));
    });

    test('accepts an upper-case digest and a numeric-string size', () {
      final v = AppVersion.fromUpdateCheck(
        offer(sha256: apkSha256.toUpperCase(), fileSize: '${apkBytes.length}'),
      )!;
      expect(v.sha256, apkSha256);
      expect(v.fileSize, apkBytes.length);
    });

    for (final url in [
      'http://xman4289.com/apps/aipray/download/9.9.9',
      'https://github.com/xjanova/Aipray/releases/download/v9.9.9/aipray.apk',
      'https://objects.githubusercontent.com/aipray.apk',
      'https://xman4289.com.evil.example/apps/aipray/download',
      'https://evil.example/?https://xman4289.com/',
      'https://xman4289.com@evil.example/apps/aipray/download',
      'https://user@xman4289.com/apps/aipray/download',
      'https://xman4289.com:8443/apps/aipray/download',
      '/apps/aipray/download/9.9.9',
      '',
      null,
      42,
    ]) {
      test('refuses download_url $url', () {
        expect(AppVersion.fromUpdateCheck(offer(downloadUrl: url)), isNull);
      });
    }

    for (final sha in ['', 'abc', 'z' * 64, '${apkSha256}00', 42]) {
      test('refuses sha256 "$sha"', () {
        expect(AppVersion.fromUpdateCheck(offer(sha256: sha)), isNull);
      });
    }

    test('refuses a missing sha256', () {
      final data = offer()..['sha256'] = null;
      expect(AppVersion.fromUpdateCheck(data), isNull);
    });

    for (final size in [0, -1, 1.5, 'lots', UpdateService.maxApkBytes + 1]) {
      test('refuses file_size $size', () {
        expect(AppVersion.fromUpdateCheck(offer(fileSize: size)), isNull);
      });
    }

    test('refuses a missing file_size', () {
      final data = offer()..['file_size'] = null;
      expect(AppVersion.fromUpdateCheck(data), isNull);
    });
  });

  group('checkForUpdate', () {
    test('asks xman4289.com with the installed version', () async {
      final s = service();
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.updateAvailable);
      expect(
        requests.single.url.toString(),
        'https://xman4289.com/api/v1/product/aipray/update/check'
        '?current_version=${UpdateService.currentVersion}',
      );
      expect(s.state.value, UpdateState.updateAvailable);
      expect(s.latestVersion!.version, '9.9.9');
      expect(s.hasPendingUpdate, isTrue);
    });

    test('decodes the notes as UTF-8 whatever the content type says', () async {
      final s = service(
        check: http.Response.bytes(utf8.encode(jsonEncode(offer())), 200,
            headers: {'content-type': 'text/html'}),
      );
      await s.checkForUpdate(force: true);
      expect(s.latestVersion!.releaseNotes, contains('สวดมนต์อัจฉริยะ'));
    });

    test('reports no update when the server has none', () async {
      final s = service(
        check: jsonResponse(offer(hasUpdate: false, version: UpdateService.currentVersion, downloadUrl: '')),
      );
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.noUpdate);
      expect(s.state.value, UpdateState.idle);
      expect(s.latestVersion, isNull);
      expect(s.hasPendingUpdate, isFalse);
    });

    test('never offers a version that is not newer, whatever has_update says', () async {
      final s = service(check: jsonResponse(offer(version: '0.0.1')));
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.noUpdate);
    });

    test('treats an offer it cannot verify as an error, not as up to date', () async {
      final s = service(check: jsonResponse(offer(downloadUrl: 'https://github.com/x/y.apk')));
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.error);
      expect(s.state.value, UpdateState.idle);
      expect(s.hasPendingUpdate, isFalse);
    });

    test('treats a server error as an error', () async {
      final s = service(check: jsonResponse({'has_update': false, 'error': 'Product not found'}, 404));
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.error);
      expect(s.state.value, UpdateState.idle);
    });

    test('treats a non-JSON answer as an error', () async {
      final s = service(check: http.Response('<html>Just a moment...</html>', 200));
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.error);
      expect(s.state.value, UpdateState.idle);
    });

    test('checks at most once an hour unless forced', () async {
      final s = service(check: jsonResponse(offer(hasUpdate: false, downloadUrl: '')));
      expect(await s.checkForUpdate(), UpdateCheckResult.noUpdate);
      expect(await s.checkForUpdate(), UpdateCheckResult.alreadyChecked);
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.noUpdate);
      expect(requests, hasLength(2));
    });

    test('respects a skipped version unless forced', () async {
      final s = service();
      await s.checkForUpdate(force: true);
      await s.skipVersion();
      // Past the once-an-hour limit, as on a later launch.
      await (await SharedPreferences.getInstance()).remove('setting_last_update_check');
      expect(await s.checkForUpdate(), UpdateCheckResult.skipped);
      expect(s.hasPendingUpdate, isFalse);
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.updateAvailable);
    });

    test('two checks at once share one request', () async {
      final s = service();
      final results = await Future.wait([
        s.checkForUpdate(force: true),
        s.checkForUpdate(force: true),
      ]);
      expect(results, everyElement(UpdateCheckResult.updateAvailable));
      expect(requests, hasLength(1));
    });

    test('removes an installed update\'s APK once nothing newer exists', () async {
      File('${dir.path}/aipray_update.apk').writeAsBytesSync([1, 2, 3]);
      File('${dir.path}/aipray_update.apk.part').writeAsBytesSync([1]);
      final s = service(check: jsonResponse(offer(hasUpdate: false, downloadUrl: '')));
      await s.checkForUpdate(force: true);
      expect(filesLeft(), isEmpty);
    });
  });

  group('downloadUpdate', () {
    Future<UpdateService> offered({
      List<List<int>>? chunks,
      int status = 200,
      int? contentLength,
      bool announceLength = true,
      Map<String, String> headers = const {},
      Map<String, dynamic>? check,
    }) async {
      final s = service(
        check: check == null ? null : jsonResponse(check),
        chunks: chunks,
        status: status,
        contentLength: contentLength,
        announceLength: announceLength,
        headers: headers,
      );
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.updateAvailable);
      return s;
    }

    test('keeps the file when size and SHA-256 match', () async {
      final s = await offered();
      expect(await s.downloadUpdate(), isTrue);

      final download = requests.last as http.Request;
      expect(download.url.toString(), 'https://xman4289.com/apps/aipray/download/9.9.9');
      expect(download.followRedirects, isFalse);

      expect(s.state.value, UpdateState.readyToInstall);
      expect(s.downloadProgress.value, 1.0);
      expect(s.downloadedFilePath, endsWith('aipray_update.apk'));
      expect(File(s.downloadedFilePath!).readAsBytesSync(), apkBytes);
      expect(filesLeft(), ['aipray_update.apk']);
    });

    test('also works when the server does not announce a length', () async {
      final s = await offered(announceLength: false);
      expect(await s.downloadUpdate(), isTrue);
      expect(s.state.value, UpdateState.readyToInstall);
    });

    test('replaces an older download', () async {
      File('${dir.path}/aipray_update.apk').writeAsBytesSync([9, 9, 9]);
      final s = await offered();
      expect(await s.downloadUpdate(), isTrue);
      expect(File(s.downloadedFilePath!).readAsBytesSync(), apkBytes);
    });

    Future<void> expectRejected(UpdateService s) async {
      expect(await s.downloadUpdate(), isFalse);
      expect(s.state.value, UpdateState.error);
      expect(s.downloadedFilePath, isNull);
      expect(filesLeft(), isEmpty, reason: 'nothing unverified may stay behind');
      expect(s.hasPendingUpdate, isTrue, reason: 'the user can retry');
    }

    test('throws the file away when the SHA-256 differs', () async {
      final tampered = List<int>.of(apkBytes)..[1234] ^= 0xff;
      await expectRejected(await offered(chunks: [tampered]));
    });

    test('throws the file away when it is shorter than promised', () async {
      await expectRejected(await offered(chunks: [apkBytes.sublist(0, 1000)], announceLength: false));
    });

    test('stops as soon as the file is longer than promised', () async {
      await expectRejected(await offered(chunks: [apkBytes, [0]], announceLength: false));
    });

    test('refuses a Content-Length that differs from the promised size', () async {
      await expectRejected(await offered(contentLength: apkBytes.length + 1));
    });

    test('refuses a redirect instead of following it', () async {
      await expectRejected(await offered(
        chunks: [],
        status: 302,
        headers: {'location': 'https://github.com/xjanova/Aipray/releases/download/v9.9.9/a.apk'},
      ));
    });

    test('refuses a login page', () async {
      await expectRejected(await offered(
        chunks: [utf8.encode('<html>login</html>')],
        headers: {'content-type': 'text/html'},
      ));
    });

    test('a retry after a failure can succeed', () async {
      var attempts = 0;
      final client = MockClient.streaming((request, _) async {
        if (request.url.path.endsWith('/update/check')) {
          return http.StreamedResponse(Stream.value(jsonResponse(offer()).bodyBytes), 200);
        }
        // The first attempt is cut short, the second one is whole.
        final body = ++attempts == 1 ? apkBytes.sublist(0, 10) : apkBytes;
        return http.StreamedResponse(Stream.value(body), 200);
      });
      final s = UpdateService(httpClient: () => client, downloadDir: () async => dir);
      await s.checkForUpdate(force: true);

      expect(await s.downloadUpdate(), isFalse);
      expect(s.state.value, UpdateState.error);
      expect(await s.downloadUpdate(), isTrue);
      expect(s.state.value, UpdateState.readyToInstall);
      expect(File(s.downloadedFilePath!).readAsBytesSync(), apkBytes);
    });

    test('a second tap does not start a second download', () async {
      final gate = Completer<void>();
      final client = MockClient.streaming((request, _) async {
        requests.add(request);
        if (request.url.path.endsWith('/update/check')) {
          return http.StreamedResponse(Stream.value(jsonResponse(offer()).bodyBytes), 200);
        }
        await gate.future;
        return http.StreamedResponse(Stream.value(apkBytes), 200, contentLength: apkBytes.length);
      });
      final s = UpdateService(httpClient: () => client, downloadDir: () async => dir);
      await s.checkForUpdate(force: true);

      final first = s.downloadUpdate();
      expect(s.state.value, UpdateState.downloading);
      expect(await s.downloadUpdate(), isFalse);
      expect(await s.checkForUpdate(force: true), UpdateCheckResult.updateAvailable,
          reason: 'a check during a download must not reset it');

      gate.complete();
      expect(await first, isTrue);
      expect(requests.where((r) => r.url.path.contains('/download/')), hasLength(1));
    });

    test('does nothing without an offer', () async {
      final s = service();
      expect(await s.downloadUpdate(), isFalse);
      expect(s.state.value, UpdateState.idle);
    });
  });
}
