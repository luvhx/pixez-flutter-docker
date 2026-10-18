/// Web storage initialisation: SQLite via WebAssembly, persisted in
/// IndexedDB.
library;

import 'package:pixez/platform/db.dart';

Future<void> initPlatformStorage() async {
  databaseFactory = databaseFactoryFfiWeb;
}
