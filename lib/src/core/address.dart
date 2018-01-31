part of bitcoin.core;

class Address {
  static const int LENGTH = 20; // bytes (= 160 bits)
  static final _b58c = new Base58CheckCodec.bitcoin();

  int _version;
  Hash160 _hash160;

  /// Create a new address object from a Base58 string.
  ///
  /// Checksum will be verified.
  Address(String base58address) {
    if (version != null)
      throw new ArgumentError(
          "Version should not be passed when address is a String");

    // extract the payload and verify the checksum
    Base58CheckPayload payload = _b58c.decode(base58address);
    if (payload.payload.length != 20)
      throw new FormatException(
          "The Base58 address should be exactly 25 bytes long: a 21-byte "
          "payload and a 4-byte checksum. (Was ${payload.payload.length}");

    _version = payload.version;
    _hash160 = new Hash160(payload.payload);
    return;
  }

  /// Create a new Address with a 20-byte [Uint8List] or a [Hash160].
  Address.fromHash160(dynamic hash160, int version) {
    if (hash160 is Uint8List) {
      if (hash160.length != 20)
        throw new ArgumentError("To create an address from a hash160 payload, "
            "input needs to be exactly 20 bytes.");
      hash160 = new Hash160(hash160);
    }
    if (hash160 is Hash160) {
      _hash160 = hash160;
      _version = version;
      return;
    }
    throw new ArgumentError("Invalid arguments, please read documentation.");
  }

  /// Create a new address from a pay-to-pubkey-hash (P2PKH) hash.
  ///
  /// To create an address from a P2SH script, use the
  /// [PayToPubKeyHashOutputScript] class.
  factory Address.p2pkh(dynamic hash160,
          [NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      new Address.fromHash160(hash160, params.addressHeader);

  /// Create an address from a pay-to-script-hash (P2SH) hash.
  ///
  /// To create an address from a P2SH script, use the
  /// [PayToScriptHashOutputScript] class.
  factory Address.p2sh(dynamic hash160,
          [NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      new Address.fromHash160(hash160, params.p2shHeader);

  int get version => _version;

  Hash160 get hash160 => _hash160;

  /// Returns the base58 string representation of this address.
  String get address => _b58c.encode(
      new Base58CheckPayload(_version, _hash160.asBytes()));

  /// Finds the [NetworkParameters] that correspond to the version byte of
  /// this [Address].
  ///
  /// Returns [null] if no matching params are found.
  NetworkParameters findNetwork() {
    for (NetworkParameters params in NetworkParameters.SUPPORTED_PARAMS) {
      if (_isAcceptableVersion(params, _version)) return params;
    }
    return null;
  }

  // *******************
  // ** address types **
  // *******************

  /// Checks if this address is a regular pay-to-pubkey-hash address.
  bool isPayToPubkeyHashAddress(
          [NetworkParameters params = NetworkParameters.MAIN_NET]) =>
      _version == params.addressHeader;

  /// Checks if this address is a pay-to-script-hash address.
  bool isP2SHAddress([NetworkParameters params = NetworkParameters.MAIN_NET]) {
    // I first placed this check in the [PayToScriptHashOutputScript] class,
    // like I did with the [matchesType()] methods in the standard Scripts,
    // but then decided to place it here anyways.
    // I'm no big fan of putting BIP- or feature-specific code aspects in general classes.
    return _version == params.p2shHeader;
  }

  @override
  String toString() => address;

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != Address) return false;
    return _version == other._version && _hash160 == other._hash160;
  }

  @override
  int get hashCode =>
      _version.hashCode ^ utils.listHashCode(_hash160.asBytes());

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
