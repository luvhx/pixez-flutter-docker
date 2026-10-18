/// Web implementation of the directory helpers.
///
/// The browser has no real file system. Returning a dummy `/tmp` keeps the
/// file-system oriented code paths compilable; they are never used for real
/// downloads on the web (those go through `DocumentPlugin`).
library;

import 'package:pixez/platform/io.dart';

Future<Directory> getTemporaryDirectory() async => Directory('/tmp');

Future<Directory> getApplicationDocumentsDirectory() async =>
    Directory('/tmp/pixez');

Future<Directory> getApplicationSupportDirectory() async =>
    Directory('/tmp/pixez');

Future<Directory> getApplicationCacheDirectory() async => Directory('/tmp');

Future<Directory> getLibraryDirectory() async => Directory('/tmp');

Future<Directory?> getDownloadsDirectory() async => Directory('/tmp');

Future<List<Directory>?> getExternalCacheDirectories() async => null;

Future<List<Directory>?> getExternalStorageDirectories({
  StorageDirectory? type,
}) async => null;

enum StorageDirectory { music, podcasts, ringtones, alarms, notifications, pictures, movies, downloads, dcim, documents }

Future<Directory> getExternalStorageDirectory() async => Directory('/tmp');
