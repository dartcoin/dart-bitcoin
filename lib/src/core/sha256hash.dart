part of dartcoin;

class Sha256Hash {
  final List<int> bytes;
  
  Sha256Hash(List<int> this.bytes) {
    if(bytes.length != 32) {
      throw new Exception("SHA-256 hashes are 32 bytes long.");
    }
  }
  
  static Sha256Hash create(List<int> bytes) {
    return new Sha256Hash(Utils.singleDigest(bytes));
  }
  
  static Sha256Hash createDouble(List<int> bytes) {
    return new Sha256Hash(Utils.doubleDigest(bytes));
  }
  
  String toString() {
    return Utils.bytesToHex(bytes);
  }
  
  int get hashCode {
    return bytes[bytes.length-1] | (bytes[bytes.length-2] << 8) | (bytes[bytes.length-3] << 16) | (bytes[bytes.length-4] << 24); 
  }
  
  bool operator ==(Sha256Hash other) {
    if(identical(this,other)) return true;
    return Utils.equalLists(bytes, other.bytes);
  }
}