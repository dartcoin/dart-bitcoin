part of dartcoin.core;

class KeyCrypterException implements Exception {
  String message;

  ///Will be either an [Exception] or an [Error].
  Object reason;

  KeyCrypterException([String this.message, Object this.reason]);

  @override
  String toString() =>
      "KeyCrypterException: $message" + (reason == null ? "" : "; Reason: $reason");
}
