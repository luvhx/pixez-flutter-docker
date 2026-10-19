/// Web builds navigate the current tab.
library;

import 'package:web/web.dart' as web;

void webRedirect(String url) {
  web.window.location.href = url;
}
