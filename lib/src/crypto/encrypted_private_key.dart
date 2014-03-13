part of dartcoin.core;


class EncryptedPrivateKey {
  
  // the actual key
  Uint8List encryptedKey;
  // the initialisation vector
  Uint8List iv;

  EncryptedPrivateKey(this.encryptedKey, this.iv);

  EncryptedPrivateKey.copy(EncryptedPrivateKey key): this(key.iv, key.encryptedKey);

  EncryptedPrivateKey clone() => new EncryptedPrivateKey.copy(this);

  operator ==(EncryptedPrivateKey other) {
    if(other is! EncryptedPrivateKey) return false;
    if(identical(this, other)) return true;
    return iv == other.iv && encryptedKey == other.encryptedKey;
  }
  
  int get hashCode => Utils.listHashCode(encryptedKey) ^ Utils.listHashCode(iv);

  String toString() => "EncryptedPrivateKey [initialisationVector=$iv, encryptedPrivateBytes=$encryptedKey]";

  void clear() {
    iv = null;
    encryptedKey = null;
  }
}