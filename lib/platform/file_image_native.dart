/// Native preview of a picked file.
library;

import 'package:material_ui/material_ui.dart';
import 'package:pixez/platform/io.dart';

Widget pickedFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.file(File(path), width: width, height: height, fit: fit);
}
