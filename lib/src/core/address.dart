part of dartcoin;

class Address {
  int _version;
  List<int> _bytes;
  
  /**
   * Create a new address object.
   * 
   * If version is set, the bytes will be treated as the payload (usually 20 bytes).
   * If version is not set, the version will be extracted from the bytes (first) and 
   * the checksum (last four bytes) will be verified.
   */
  Address(List<int> bytes, [int version]) {
    if(bytes.length == 20 && version != null) {
      _bytes = bytes;
      _version = version;
      return;
    }
    if(_validateChecksum(bytes)) {
      _bytes = bytes.sublist(1, bytes.length - 4);
      _version = bytes[0];
      return;
    }
    throw new Exception("Format exception or failed checksum, read documentation!");
  }
  
  /**
   * Create a new address from a base58 string. Checksum will be verified.
   */
  Address.fromBase58(String address) {
    List<int> bytes = Base58.decode(address);
    if(!_validateChecksum(bytes)) {
      throw new Exception("Checksum failed.");
    }
    _bytes = bytes.sublist(1, 21);
    _version = bytes[0];
  }
  
  /**
   * Returns the base58 string.
   */
  String toString() {
    List<int> bytes = new List();
    bytes.add(_version);
    bytes.addAll(_bytes);
    bytes.addAll(Utils.doubleDigest(bytes).sublist(0, 4));
    return Base58.encode(bytes);
  }
  
  /**
   * Validates the byte string. The last four bytes have to match the first four
   * bytes from the double-round SHA-256 checksum from the main bytes.
   */
  static bool _validateChecksum(List<int> bytes) {
    List<int> payload = bytes.sublist(0, bytes.length - 4);
    List<int> checksum = bytes.sublist(bytes.length - 4);
    if(Utils.equalLists(checksum, Utils.doubleDigest(payload).sublist(0, 4))) {
      return true;
    }
    return false;
  }
}


