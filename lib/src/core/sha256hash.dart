part of dartcoin.core;

class Sha256Hash {
  
  static const int LENGTH = 32;
  
  static final Sha256Hash ZERO_HASH = new Sha256Hash(new Uint8List(32));
  
  Uint8List _bytes;
  
  /**
   * The parameter for [hash] can be either a hexadecimal string or a [Uint8List] object.
   */
  Sha256Hash(dynamic hash) {
    if(hash is String) {
      if(hash.length != 2 * LENGTH)
        throw new ArgumentError("SHA-256 hashes are 64 hexadecimal characters long.");
      hash = Utils.hexToBytes(hash);
    }
    if(!(hash is Uint8List))
      throw new ArgumentError("Input parameter must be either a hexadecimal string or a [Uint8List] object.");
    if(hash.length != LENGTH)
      throw new ArgumentError("SHA-256 hashes are 32 bytes long.");
    _bytes = new Uint8List.fromList(hash);
  }
  
  factory Sha256Hash.digest(Uint8List bytes) {
    return new Sha256Hash(Utils.singleDigest(bytes));
  }
  
  factory Sha256Hash.doubleDigest(Uint8List bytes) {
    return new Sha256Hash(Utils.doubleDigest(bytes));
  }
  
  Uint8List get bytes => new Uint8List.fromList(_bytes);

  @override
  String toString() => Utils.bytesToHex(_bytes);

  @override
  int get hashCode {
    return _bytes[_bytes.length-1] | (_bytes[_bytes.length-2] << 8) | (_bytes[_bytes.length-3] << 16) | (_bytes[_bytes.length-4] << 24); 
  }
  
  @override
  bool operator ==(Sha256Hash other) {
    if(!(other is Sha256Hash)) return false;
    return Utils.equalLists(_bytes, other._bytes);
  }
}