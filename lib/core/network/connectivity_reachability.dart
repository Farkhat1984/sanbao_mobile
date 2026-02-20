/// Native reachability check using dart:io DNS lookup.
library;

import 'dart:io';

/// Returns true if [host] resolves via DNS.
Future<bool> checkHost(String host) async {
  try {
    final result = await InternetAddress.lookup(host);
    return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
  } on SocketException {
    return false;
  }
}
