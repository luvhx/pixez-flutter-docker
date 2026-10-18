/// Native implementation using `path_provider_foundation`.
library;

import 'package:path_provider_foundation/path_provider_foundation.dart';

Future<String?> iosAppGroupContainerPath() async {
  try {
    final providerFoundation = PathProviderFoundation();
    return await providerFoundation.getContainerPath(
      appGroupIdentifier: 'group.pixez',
    );
  } catch (_) {
    return null;
  }
}
