part of dartcoin;

class ECKey {
  
  
  int _priv;
  Uint8List _pub;
  
  /**
   * Create a keypair from a private or public key.
   * 
   * If provided both, they will be considered correctly matching each other.
   * If public key is null, it will be calculated when it is required.
   * If private key is null, this will represent only a public key.
   * If both are null, a new random key will be generated like using ECKey.generate().
   */
  factory ECKey({Uint8List publicKey, Uint8List privateKey}) {
    if(publicKey == null && privateKey == null) return new ECKey.generate();
    if(privateKey == null) return new ECKey._internal(null, publicKey);
    return new ECKey._internal(Utils.bytesToIntBE(privateKey), publicKey);
  }
  
  ECKey.fromIntegers(int privateKey, int publicKey) {
    _priv = privateKey;
    if(publicKey != null) {
      _pub = Utils.intToBytesBE(publicKey);
    }
  }
  
  /**
   * Intended for internal use only.
   */
  ECKey._internal(int this._priv, Uint8List this._pub);
  
  /**
   * Generate a new random key pair.
   */
  factory ECKey.generate() {
    //TODO
  }
  
  Uint8List get publicKey {
    if(_pub == null) _pub = publicKeyFromPrivateKey(_priv);
    return _pub;
  }
  
  Uint8List get privateKey {
    return Utils.intToBytesBE(_priv);
  }
  
  Address get address {
    return new Address(Utils.sha256hash160(publicKey));
  }
  
  /**
   * This method irreversibly deletes the private key from memory.
   * The key will still be usable as a public key only.
   */
  void deletePrivateKey() {
    if(_pub == null) _pub = publicKeyFromPrivateKey(_priv);
    _priv = null;
  }
  
  bool operator ==(ECKey other) {
    if(!(other is ECKey)) return false;
    if(identical(this, other)) return true;
    return Utils.equalLists(publicKey, other.publicKey);
  }
  
  int get hashCode {
    return (publicKey[0] & 0xff) | ((publicKey[1] & 0xff) << 8) | ((publicKey[2] & 0xff) << 16) | ((publicKey[3] & 0xff) << 24);
  }
  
  static Uint8List publicKeyFromPrivateKey(int privateKey) {
    //TODO
  }
  
  //TODO implement signing, verification methods
  
  //TODO encryption
  
}