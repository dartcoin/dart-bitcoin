part of dartcoin.core;

class Address {
  
  static const int LENGTH = 20; // bytes (= 160 bits)
  
  int _version;
  Hash160 _bytes;

  static const String BASE58_ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
  
  /**
   * Create a new address object.
   * 
   * The [address] parameter can either be of type [String] or [Uint8List].
   * 
   * If [String], the checksum will be verified.
   * 
   * If [Hash160] or [Uint8List] of size 20, the bytes are used as the [hash160].
   * If [Uint8List] of size 25, [version] and [hash160] will be extracted and the checksum verified.
   */
  Address(dynamic address, [NetworkParameters params, int version]) {
    if(address is String) {
      if(version != null)
        throw new ArgumentError("Version should not be passed when address is a String");
      Base58CheckPayload payload = new Base58CheckDecoder(BASE58_ALPHABET, Utils.singleDigest).convert(address);
      if(payload.payload.length != 20)
        throw new FormatException(
            "The Base58 address should be exactly 25 bytes long: a 21-byte payload and a 4-byte checksum. (Was ${payload.payload.length}");
      _version = payload.version;
      _bytes = new Hash160(payload.payload);
      if(params != null && !_isAcceptableVersion(params, _version))
        throw new WrongNetworkException(_version, params.acceptableAddressHeaders);
      return;
    }
    if(address is Uint8List || address is Hash160) {
      if(address.length != 20)
        throw new ArgumentError("To create an address from a hash160 payload, input needs to be exactly 20 bytes.");
      if(params == null && version == null)
        params = NetworkParameters.MAIN_NET;
      _bytes = new Hash160(address);
      _version = (version != null) ? version : params.addressHeader;
      if(params != null && !_isAcceptableVersion(params, _version))
        throw new WrongNetworkException(_version, params.acceptableAddressHeaders);
      return;
    }
    throw new ArgumentError("Invalid arguments, please read documentation.");
  }
  
  /**
   * Create an address from a pay-to-script-hash (P2SH) hash.
   * 
   * To create an address from a P2SH script, use the [PayToScriptHashOutputScript] class.
   */
  factory Address.p2sh(Uint8List hash160, [NetworkParameters params = NetworkParameters.MAIN_NET]) =>
    new Address(hash160, params, params.p2shHeader);
  
  int get version => _version;
  
  Hash160 get hash160 => _bytes;
  
  /**
   * Returns the base58 string representation of this address.
   */
  String get address => new Base58CheckEncoder(BASE58_ALPHABET, Utils.singleDigest)
      .convert(new Base58CheckPayload(_version, _bytes.asBytes()));
  
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
  
  // *******************
  // ** address types **
  // *******************
  
  /**
   * Checks if this address is a regular pay-to-pubkey-hash address.
   */
  bool get isPayToPubkeyHashAddress => _version == params.addressHeader;
  
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
    if(other is! Address) return false;
    return _version == other._version && _bytes == other._bytes;
  }
  
  @override
  int get hashCode => _version.hashCode ^ Utils.listHashCode(_bytes.asBytes());
  
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

class WrongNetworkException implements Exception {
  final int version;
  final List<int> acceptableVersions;
  WrongNetworkException(int this.version, List<int> this.acceptableVersions);
  String get message => 
      "Version code of address did not match acceptable versions for network: $version not in $acceptableVersions";
  @override
  String toString() => message;
}


