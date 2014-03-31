part of dartcoin.core;


class EncryptedPrivateKey {
  
  // the actual key
  Uint8List _encryptedKey;
  // the initialisation vector
  Uint8List _iv;

  EncryptedPrivateKey(Uint8List encryptedKey, Uint8List iv) {
    _encryptedKey = encryptedKey;
    _iv = iv;
  }

  Uint8List get encryptedKey {
    if(_encryptedKey == null) return null;
    return new Uint8List.fromList(_encryptedKey);
  }

  Uint8List get iv {
    if(_iv == null) return null;
    return new Uint8List.fromList(_iv);
  }

  /**
   * Clone this encrypted private key.
   */
  EncryptedPrivateKey clone() => new EncryptedPrivateKey(this._encryptedKey, this._iv);

  @override
  operator ==(EncryptedPrivateKey other) {
    if(other is! EncryptedPrivateKey) return false;
    if(identical(this, other)) return true;
    return _iv == other._iv && _encryptedKey == other._encryptedKey;
  }

  @override
  int get hashCode => Utils.listHashCode(_encryptedKey) ^ Utils.listHashCode(_iv);

  @override
  String toString() => "EncryptedPrivateKey [initialisationVector=$_iv, encryptedPrivateBytes=$_encryptedKey]";

  /**
   * Clear this private key.
   */
  void clear() {
    _iv = null;
    _encryptedKey = null;
  }
}