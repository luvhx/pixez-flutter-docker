/// Web implementation of the settings import / export helper.
library;

import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:pixez/document_plugin.dart';

class SAFPlugin {
  static String? _pendingName;

  static Future<String?> createFile(String name, String type) async {
    _pendingName = name;
    return name;
  }

  static Future<void> writeUri(String uri, Uint8List data) async {
    await DocumentPlugin.save(data, _pendingName ?? uri);
  }

  static Future<Uint8List?> openFile() async {
    try {
      final result = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );
      return await result?.readAsBytes();
    } catch (_) {
      return null;
    }
  }
}
