/// Native storage initialisation.
library;

import 'package:pixez/paths_plugin.dart';
import 'package:pixez/platform/db.dart';
import 'package:pixez/platform/dirs.dart';
import 'package:pixez/platform/io.dart';
import 'package:pixez/single_instance_plugin.dart';
import 'package:pixez/win32_plugin.dart';

Future<void> initPlatformStorage() async {
  if (!Platform.isWindows && !Platform.isLinux) return;

  // sqflite ffi init
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  final dbPath = await getApplicationSupportDirectory();
  await Paths.setApplicationSupportDirectory(dbPath.path);
  if (Platform.isWindows) {
    await Win32.migrationAppData();
  }
  databaseFactory.setDatabasesPath(dbPath.path);

  // 确保只有一个实例正在运行
  // Android 和 iOS 应用本身就是单例程序，无需额外操作
  SingleInstancePlugin.initialize();
}
