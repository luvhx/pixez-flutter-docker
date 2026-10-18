/// Browser download implementation of [DocumentPlugin].
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart' as web;

class DocumentPlugin {
  static Future<bool?> save(
    Uint8List uint8list,
    String fileName, {
    bool clearOld = false,
    int? saveMode,
  }) async {
    try {
      _download(uint8list, fileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool?> saveFromPath(
    String sourcePath,
    String fileName, {
    bool clearOld = false,
    int? saveMode,
  }) async => false;

  static Future<bool?> openSave(Uint8List uint8list, String fileName) async {
    try {
      _download(uint8list, fileName);
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<bool?> permissionStatus() async => true;

  static Future<bool?> requestPermission() async => true;

  /// The browser has no way to inspect the download folder.
  static Future<bool?> exist(String fileName, {int? saveMode}) async => false;

  static Future<String?> getPath({int? saveMode}) async => 'browser-download';

  static Future<dynamic> choiceFolder({int? saveMode}) async => null;

  static void _download(Uint8List bytes, String fileName) {
    final blob = web.Blob(
      [bytes.toJS].toJS,
      web.BlobPropertyBag(type: _mimeType(fileName)),
    );
    final url = web.URL.createObjectURL(blob);
    final anchor = web.HTMLAnchorElement()
      ..href = url
      ..download = _sanitize(fileName)
      ..style.display = 'none';
    web.document.body?.appendChild(anchor);
    anchor.click();
    anchor.remove();
    // Give the browser some time to start the download before releasing it.
    Future.delayed(const Duration(seconds: 30), () {
      web.URL.revokeObjectURL(url);
    });
  }

  static String _sanitize(String name) {
    // Browsers may also interpret sub folders; keep just the file name.
    return name.split('/').last.split('\\').last;
  }

  static String _mimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) {
      return 'image/jpeg';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.zip')) return 'application/zip';
    if (lower.endsWith('.json')) return 'application/json';
    if (lower.endsWith('.mp4')) return 'video/mp4';
    return 'application/octet-stream';
  }
}
