/// Web reachability stub — browser handles connectivity natively.
library;

/// Always returns true on web (browser manages connectivity).
Future<bool> checkHost(String host) async => true;
