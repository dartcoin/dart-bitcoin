part of dartcoin.core;

abstract class KeyCrypter {
  
  /**
   * Derive the decryption key from a passphrase.
   * 
   * Note that passphrase should be encodable as UTF-8.
   */
  //TODO replace KeyParameter with just Uint8List?
  KeyParameter deriveKey(String passphrase);
  
  EncryptedPrivateKey encrypt(Uint8List privKey, KeyParameter aesKey);
  
  Uint8List decrypt(EncryptedPrivateKey encryptedPrivKey, KeyParameter aesKey);
  
}