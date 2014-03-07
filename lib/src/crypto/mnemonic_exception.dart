part of dartcoin.core;

class MnemonicException implements Exception {
  
  final String message;
  MnemonicException([this.message]);
  
}

class MnemonicWordException extends MnemonicException {
  String _badWord;
  MnemonicWordException(String badWord) : super("Bad word in the mnemonic: $badWord") {
    _badWord = badWord;
  }
  String get badWord => _badWord;
}

class MnemonicLengthException extends MnemonicException {
  MnemonicLengthException([String message]) : super(message);
}

class MnemonicChecksumException extends MnemonicException {
  MnemonicChecksumException() : super("Invalid mnemonic checksum");
}