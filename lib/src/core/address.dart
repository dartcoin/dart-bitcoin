part of dartcoin.core;

class Address {
  
  static const int LENGTH = 20; // bytes (= 160 bits)
  
  int _version;
  Uint8List _bytes;
  
  /**
   * Create a new address object.
   * 
   * The [address] parameter can either be of type [String] or [Uint8List].
   * 
   * If [String], the checksum will be verified.
   * 
   * If [Uint8List] of size 20, the bytes are used as the [hash160].
   * If [Uint8List] of size 25, [version] and [hash160] will be extracted and the checksum verified.
   */
  Address(dynamic address, [NetworkParameters params = NetworkParameters.MAIN_NET, int version]) {
    if(version == null) version = params.addressHeader;
    if(address is String)
      address = Base58Check.decode(address);
    if(address is Uint8List && address.length == 25 && version == null) {
      if(!_validateChecksum(address))
        throw new FormatException("Checksum validation failed");
      _bytes = new Uint8List.fromList(address.sublist(1, address.length - 4));
      _version = address[0];
    }
    else if(address is Uint8List && address.length == 20) {
      _bytes = new Uint8List.fromList(address);
      _version = (version != null) ? version : params.addressHeader;
    }
    if(!_isAcceptableVersion(params, _version))
      throw new FormatException("Unrecognized Address version");
    throw new ArgumentError("Invalid arguments, please read documentation.");
  }
  
  int get version => _version;
  
  Uint8List get hash160 => new Uint8List.fromList(_bytes);
  
  /**
   * Returns the base58 string representation of this address.
   */
  String get address {
    List<int> bytes = new List<int>()
      ..add(_version)
      ..addAll(_bytes);
    bytes.addAll(Utils.doubleDigest(new Uint8List.fromList(bytes)).sublist(0, 4));
    return Base58Check.encode(new Uint8List.fromList(bytes));
  }
  
  /**
   * Finds the [NetworkParameters] that correspond to the version byte of this [Address].
   * 
   * Returns [null] if no matching params are found.
   */
  NetworkParameters get params {
    for(NetworkParameters params in NetworkParameters.SUPPORTED_PARAMS) {
      if(_isAcceptableVersion(params, _version))
        return params;
    }
    return null;
  }
  
  // I first placed this check in the [PayToScriptHashOutputScript] class, 
  // like I did with the [matchesType()] methods in the standard Scripts, 
  // but then decided to place it here anyways.
  // I'm no big fan of putting BIP- or feature-specific code aspects in general classes.
  /**
   * Checks if this address is a pay-to-script-hash address.
   */
  bool get isP2SHAddress => _version == params.p2shHeader;
  
  
  @override
  String toString() => address;
  
  @override
  bool operator ==(Address other) {
    if(!(other is Address)) return false;
    return _version == other._version && 
        Utils.equalLists(_bytes, other._bytes);
  }
  
  @override
  int get hashCode => _version.hashCode ^ Utils.listHashCode(_bytes);
  
  /**
   * Validates the byte string. The last four bytes have to match the first four
   * bytes from the double-round SHA-256 checksum from the main bytes.
   */
  static bool _validateChecksum(Uint8List bytes) {
    List<int> payload = bytes.sublist(0, bytes.length - 4);
    List<int> checksum = bytes.sublist(bytes.length - 4);
    return Utils.equalLists(checksum, Utils.doubleDigest(payload).sublist(0, 4));
  }
  
  static bool _isAcceptableVersion(NetworkParameters params, int version) => 
      params.acceptableAddressHeaders.contains(version);
}


