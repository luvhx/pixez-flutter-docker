/// Web stub for the Fluent (desktop) UI entry point.
///
/// The Fluent UI is only enabled on Windows/Linux (`Constants.isFluent`), so
/// these functions are never called on the web.  They exist so that the web
/// build does not pull in `window_manager` / `flutter_acrylic`.
library;

import 'package:material_ui/material_ui.dart';

Future<void> initFluent(List<String> args) async {}

Widget buildFluentUI(BuildContext context) => const SizedBox.shrink();
