/// Web preview of a picked file.
///
/// `image_picker` returns a `blob:` URL on the web, which the browser can load
/// directly.
library;

import 'package:material_ui/material_ui.dart';

Widget pickedFileImage(
  String path, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  return Image.network(path, width: width, height: height, fit: fit);
}
