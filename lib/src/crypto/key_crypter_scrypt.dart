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

  /**
   * Create a new KeyCrypter.
   *
   * If none are given, the BIP0038 defaults will be used.
   */
  KeyCrypterScrypt({Uint8List salt, int iterations}) {
    if(salt == null)
      salt = _randomBytes(SALT_LENGTH);
    if(iterations == null)
      iterations = SCRYPT_N;
    _scryptParams = generateScryptParams(salt, iterations);
  }

  KeyCrypterScrypt.withParams(ScryptParameters scryptParameters) {
    _scryptParams = scryptParameters;
  }

  //TODO temp, need true random bytes in salt
  static Uint8List _randomBytes(int n) {
    Random r = new Random();
    Uint8List result = new Uint8List(n);
    for(int i = 0 ; i < n ; i++)
      result[i] = r.nextInt(256);
    return result;
  }
  
  /**
   * The salt must be of length [SALT_LENGTH];
   */
  static ScryptParameters generateScryptParams(Uint8List salt, [int iterations = SCRYPT_N]) {
    if(salt.length != SALT_LENGTH)
      throw new ArgumentError("Incorrect salt length: ${salt.length} instead of $SALT_LENGTH");
    return new ScryptParameters(iterations, SCRYPT_r, SCRYPT_p, KEY_LENGTH, salt);
  }
  
  KeyParameter deriveKey(String passphrase) {
    Uint8List passBytes = Utils.stringToUTF8(passphrase);
    Uint8List keyBytes = new Uint8List(_scryptParams.desiredKeyLength);
    try {
      Scrypt scrypt = new Scrypt()
        ..init(_scryptParams)
        ..deriveKey(passBytes, 0, keyBytes, 0);
      return new KeyParameter(keyBytes);
    } catch(e) {
      throw new KeyCrypterException("Could not derive key from passphrase and salt.", e);
    }
  }

  EncryptedPrivateKey encrypt(Uint8List privKey, KeyParameter aesKey) {
    if(privKey == null || aesKey == null) throw new ArgumentError();
//    try {
      Uint8List iv = _randomBytes(BLOCK_LENGTH);
      BlockCipher cipher = _createBlockCipher(true, aesKey, iv);
      Uint8List encryptedKey = cipher.process(privKey);
      return new EncryptedPrivateKey(encryptedKey, iv);
//    } catch(e) {
//      throw new KeyCrypterException("Could not encrypt key.", e);
//    }
  }
  
  Uint8List decrypt(EncryptedPrivateKey encryptedPrivKey, KeyParameter aesKey) {
    if(encryptedPrivKey == null || aesKey == null) throw new ArgumentError();
    try {
      BlockCipher cipher = _createBlockCipher(false, aesKey, encryptedPrivKey.iv);
      return cipher.process(encryptedPrivKey.encryptedKey);
    } catch (e) {
      throw new KeyCrypterException("Could not decrypt key.", e);
    }
  }

  // create a new blockcipher used for encrypting and decryptingprivate keys
  BlockCipher _createBlockCipher(bool forEncryption, KeyParameter aesKey, Uint8List iv) {
    ParametersWithIV keyWithIv = new ParametersWithIV(aesKey, iv);
    PaddedBlockCipher cipher = new PaddedBlockCipherImpl(
        new PKCS7Padding(), new CBCBlockCipher(new AESFastEngine()));
    cipher.init(forEncryption, new PaddedBlockCipherParameters(keyWithIv, null));
    return cipher;
  }

  @override
  String toString() => "Scrypt/AES";

  @override
  operator ==(KeyCrypterScrypt other) {
    if(other is! KeyCrypterScrypt) return false;
    if(identical(this, other)) return true;
    return _scryptParams == other._scryptParams;
  }

  @override
  int get hashCode => _scryptParams.hashCode;
  
}