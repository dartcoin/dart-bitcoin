
library dartcoin.src.crypto.mnemonic_exception;

class MnemonicException implements Exception {
  
  final String message;

  MnemonicException([this.message]);

  MnemonicException.word(String badWord)
      : this("Bad word in the mnemonic: $badWord");

  MnemonicException.checksum() : this("Invalid mnemonic checksum");

  @override
  String toString() => "MnemonicException: $message";
  
}