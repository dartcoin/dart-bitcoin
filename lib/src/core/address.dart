part of dartcoin.core;

class Address {
  
  static final LENGTH = 20; // bytes (= 160 bits)
  
  int _version;
  Uint8List _bytes;
  
  /**
   * Create a new address object.
   * 
   * The `address` parameter can either be of type String or Uint8List.
   * 
   * If String, the checksum will be verified.
   * 
   * If Uint8List of size 20, bytes is used as the hash160 and the mainnet version will be used.
   * If Uint8List of size 25, version and hash will be extracted and checksum verified.
   */
  Address(dynamic address, [NetworkParameters params]) {
    if(params == null) params = NetworkParameters.MAIN_NET;
    if(address is String)
      address = Base58Check.decode(address);
    if(address is Uint8List && address.length == 20) {
      _bytes = address;
      _version = params.addressHeader;
      return;
    }
    if(address is Uint8List && _validateChecksum(address)) {
      _bytes = address.sublist(1, address.length - 4);
      _version = address[0];
      return;
    }
    throw new Exception("Format exception or failed checksum, read documentation!");
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
  @override
  String toString() {
    List<int> bytes = new List();
    bytes.add(_version);
    bytes.addAll(_bytes);
    bytes.addAll(Utils.doubleDigest(new Uint8List.fromList(bytes)).sublist(0, 4));
    return Base58Check.encode(new Uint8List.fromList(bytes));
  }
  
  @override
  bool operator ==(Address other) {
    if(!(other is Address)) return false;
    if(version != other.version) return false;
    return Utils.equalLists(hash160, other.hash160);
  }
  
  @override
  int get hashCode {
    ListEquality<int> le = new ListEquality<int>();
    List<int> allBytes = new List<int>()
        ..add(version)
        ..addAll(hash160);
    return le.hash(allBytes);
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


