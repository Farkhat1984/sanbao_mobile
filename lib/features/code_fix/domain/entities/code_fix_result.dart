/// Entity representing a code fix result.
///
/// Contains the corrected code returned by the fix-code API.
library;

/// The result of an AI code fix operation.
class CodeFixResult {
  const CodeFixResult({required this.fixedCode});

  /// The corrected code returned by the API.
  final String fixedCode;
}
