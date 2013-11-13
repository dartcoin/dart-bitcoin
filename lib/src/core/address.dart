part of dartcoin;

class Address {
  
  static final LENGTH = 20; // bytes (= 160 bits)
  
  int _version;
  Uint8List _bytes;
  
  /**
   * Create a new address object.
   * 
   * If bytes is of size 20, bytes is used as the hash160 and the mainnet version will be used.
   * If bytes is of size 25, version and hash will be extracted and checksum verified.
   */
  Address(Uint8List bytes) {
    if(bytes.length == 20) {
      _bytes = bytes;
      _version = NetworkParameters.MAIN_NET.addressHeader;
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
    Uint8List bytes = Base58.decode(address);
    if(!_validateChecksum(bytes)) {
      throw new Exception("Checksum failed.");
    }
    _bytes = new Uint8List.fromList(bytes.sublist(1, 21));
    _version = bytes[0];
  }
  
  Address.withNetworkParameters(Uint8List hash160, NetworkParameters params) {
    if(hash160.length != 20 || params == null) throw new Exception();
    _bytes = hash160;
    _version = params.addressHeader;
  }
  
  int get version {
    return _version;
  }
  
  Uint8List get hash160 {
    return _bytes;
  }
  
  /**
   * Returns the base58 string.
   */
  String toString() {
    List<int> bytes = new List();
    bytes.add(_version);
    bytes.addAll(_bytes);
    bytes.addAll(Utils.doubleDigest(new Uint8List.fromList(bytes)).sublist(0, 4));
    return Base58.encode(new Uint8List.fromList(bytes));
  }
  
  /**
   * Validates the byte string. The last four bytes have to match the first four
   * bytes from the double-round SHA-256 checksum from the main bytes.
   */
  static bool _validateChecksum(Uint8List bytes) {
    List<int> payload = bytes.sublist(0, bytes.length - 4);
    List<int> checksum = bytes.sublist(bytes.length - 4);
    if(Utils.equalLists(checksum, Utils.doubleDigest(payload).sublist(0, 4))) {
      return true;
    }
    return false;
  }
}


