part of dartcoin;

class Sha256Hash {
  final Uint8List bytes;
  
  Sha256Hash(Uint8List this.bytes) {
    if(bytes.length != 32) {
      throw new Exception("SHA-256 hashes are 32 bytes long.");
    }
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
    if(identical(this,other)) 
      return true;
    return Utils.equalLists(bytes, other.bytes);
  }
}