part of dartcoin.core;


/**
 * Implements a KeyCrypter for BIP0038 using Scrypt.
 * There is also a separate constructor for when EC multiplication is used (and so ScryptParamters should be provided.)
 * 
 * More info in BIP0038: https://github.com/bitcoin/bips/blob/master/bip-0038.mediawiki
 */
class KeyCrypterScrypt implements KeyCrypter {
  
  static const int SALT_LENGTH = 8;
  
  static const int BLOCK_LENGTH = 16;
  
  // (BIP0038 suggests using a 64-byte key and splitting that in two)
  static const int KEY_LENGTH = 32;
  
  // these are copied from BIP0038
  static const int SCRYPT_N = 16384;
  static const int SCRYPT_r = 8;
  static const int SCRYPT_p = 8;
  
  ScryptParameters _scryptParams; 
  
  KeyCrypterScrypt([ScryptParameters scryptParameters]) {
    if(scryptParameters == null) {
      Uint8List salt = new Uint8List(SALT_LENGTH);
      //TODO random bytes in salt
      scryptParameters = scryptParamsWithSalt(salt);
    }
    _scryptParams = scryptParameters;
  }
  
  /**
   * The salt must be of length [SALT_LENGTH];
   */
  static ScryptParameters scryptParamsWithSalt(Uint8List salt) {
    if(salt.length != SALT_LENGTH)
      throw new ArgumentError("Incorrect salt length: ${salt.length} instead of $SALT_LENGTH");
    return new ScryptParameters(SCRYPT_N, SCRYPT_r, SCRYPT_p, KEY_LENGTH, salt);
  }
  
  KeyParameter deriveKey(String passphrase) {
    Uint8List passBytes = new Uint8List.fromList(new Utf8Encoder().convert(passphrase));
    Uint8List keyBytes = new Uint8List(KEY_LENGTH);
    Scrypt scrypt = new Scrypt()
      ..init(_scryptParams)
      ..deriveKey(passBytes, 0, keyBytes, 0);
    return new KeyParameter(keyBytes);
  }

  EncryptedPrivateKey encrypt(Uint8List privKey, KeyParameter aesKey) {
    if(privKey == null || aesKey == null) throw new ArgumentError();
    Uint8List iv = new Uint8List(BLOCK_LENGTH);
    // TODO fill iv with random bytes from securerandom
    ParametersWithIV keyWithIv = new ParametersWithIV(aesKey, iv);
    PaddedBlockCipher cipher = new PaddedBlockCipherImpl(new PKCS7Padding(), new CBCBlockCipher(new AESFastEngine()));
    cipher.init(true, new PaddedBlockCipherParameters(keyWithIv, null));
    Uint8List encryptedKey = cipher.process(privKey);
    return new EncryptedPrivateKey(encryptedKey, iv);
  }
  
  Uint8List decrypt(EncryptedPrivateKey encryptedPrivKey, KeyParameter aesKey) {
    if(encryptedPrivKey == null || aesKey == null) throw new ArgumentError();
    ParametersWithIV keyWithIv = new ParametersWithIV(aesKey, encryptedPrivKey.iv);
    PaddedBlockCipher cipher = new PaddedBlockCipherImpl(new PKCS7Padding(), new CBCBlockCipher(new AESFastEngine()));
    cipher.init(false, keyWithIv);
    return cipher.process(encryptedPrivKey.encryptedKey);
  }
  
  String toString() => "Scrypt/AES";
  
  /* TODO cipher does not have a ScryptParams.hashCode
   *  also, Dart lacks Uint8List.hashCode and Uint8List.==. Hard to implement
   *  https://code.google.com/p/dart/issues/detail?id=16335&thanks=16335&ts=1390849795
   *  ==> dart?collections/equality
   */
  operator ==(KeyCrypterScrypt other) {
    if(other is! KeyCrypterScrypt) return false;
    if(identical(this, other)) return true;
    // return _scryptParams == other._scryptParams;
  }
  
  int get hashCode {
    // return _scryptParams.hashCode;
  }
  
}