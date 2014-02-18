part of dartcoin.core;

class Sha256Hash {
  
  static const int LENGTH = 32;
  
  static final Sha256Hash ZERO_HASH = new Sha256Hash(new Uint8List(32));
  
  Uint8List bytes;
  
  /**
   * The parameter for [hash] can be either a hexadecimal string or a [Uint8List] object.
   */
  Sha256Hash(dynamic hash) {
    if(hash is String) {
      if(hash.length != 2 * LENGTH)
        throw new Exception("SHA-256 hashes are 64 hexadecimal characters long.");
      hash = Utils.hexToBytes(hash);
    }
    if(!(hash is Uint8List))
      throw new Exception("Input parameter must be either a hexadecimal string or a [Uint8List] object.");
    if(hash.length != LENGTH)
      throw new Exception("SHA-256 hashes are 32 bytes long.");
    bytes = hash;
  }
  
  static Sha256Hash digest(Uint8List bytes) {
    return new Sha256Hash(Utils.singleDigest(bytes));
  }
  
  static Sha256Hash doubleDigest(Uint8List bytes) {
    return new Sha256Hash(Utils.doubleDigest(bytes));
  }

  @override
  String toString() {
    return Utils.bytesToHex(bytes);
  }

  @override
  int get hashCode {
    return bytes[bytes.length-1] | (bytes[bytes.length-2] << 8) | (bytes[bytes.length-3] << 16) | (bytes[bytes.length-4] << 24); 
  }
  
  @override
  bool operator ==(Sha256Hash other) {
    if(!(other is Sha256Hash)) return false;
    if(identical(this,other)) return true;
    return Utils.equalLists(bytes, other.bytes);
  }
}