part of bitcoin.core;

abstract class KeyCrypter {
  /**
   * Derive the decryption key from a passphrase.
   * 
   * Note that passphrase should be encodable as UTF-8.
   */
  KeyParameter deriveKey(String passphrase);

  EncryptedPrivateKey encrypt(Uint8List privKey, KeyParameter encryptionKey);

  Uint8List decrypt(EncryptedPrivateKey encryptedPrivKey, KeyParameter decryptionKey);
}
