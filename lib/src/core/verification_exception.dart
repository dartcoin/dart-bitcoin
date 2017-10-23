part of dartcoin.core;

class VerificationException implements Exception {
  final String message;
  VerificationException([String this.message]);
  @override
  String toString() => message;
}
