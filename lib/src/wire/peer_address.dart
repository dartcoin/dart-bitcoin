part of bitcoin.wire;

class PeerAddress extends BitcoinSerializable {
  static const int SERIALIZATION_SIZE = 30;

  Uint8List address;
  int port;
  BigInt services;
  int time;

  /**
   * 
   * 
   * The [address] parameter should either by a [String] or [Uint8List].
   */
  PeerAddress(dynamic address, {int this.port, BigInt this.services, int this.time}) {
    this.address = _formatAddress(address);
    services = services ?? BigInt.zero;
  }

  factory PeerAddress.localhost({BigInt services, int port}) =>
      new PeerAddress("127.0.0.1", port: port, services: services);

  factory PeerAddress.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new PeerAddress.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }

  factory PeerAddress.fromBuffer(var msg) { // TODO
    return new PeerAddress(
      msg.address,
      port: msg.port
    );
  }

  /// Create an empty instance.
  PeerAddress.empty();

  static Uint8List _formatAddress(dynamic address) {
    if (address == null) throw new ArgumentError("The address argument should not be null");
    if (address is String) {
      try {
        address = new Uint8List.fromList(Uri.parseIPv6Address(address));
      } on FormatException {
        try {
          address = new Uint8List.fromList(Uri.parseIPv4Address(address));
        } on FormatException {
          throw new FormatException("Bad IP address format!");
        }
      }
    }
    if (address is! Uint8List) throw new ArgumentError("Invalid address parameter type");
    if (address.length == 4) {
      address = new Uint8List.fromList(new List.filled(16, 0)..setRange(12, 16, address));
      address[10] = 0xff;
      address[11] = 0xff;
    }
    if (address.length != 16)
      throw new ArgumentError("Invalid address length. Must be either 4 or 16 bytes long.");
    return address;
  }

  @override
  String toString() {
    return "[${address}]:$port";
  }

  @override
  bool operator ==(dynamic other) {
    if (other.runtimeType != PeerAddress) return false;
    return address == other.address &&
        port == other.port &&
        services == other.services &&
        time == other.time;
  }

  @override
  int get hashCode {
    return address.hashCode ^ port.hashCode ^ time.hashCode ^ services.hashCode;
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    if (pver >= 31402) time = readUintLE(reader);
    services = utils.bytesToUBigIntLE(readBytes(reader, 8));
    address = readBytes(reader, 16);
    port = (0xff & readUintLE(reader, 1)) << 8 | (0xff & readUintLE(reader, 1));
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    if (pver >= 31402) {
      // This appears to be dynamic because the client only ever sends out it's
      // own address so assumes itself to be up.  For a fuller implementation
      // this needs to be dynamic only if the address refers to this client.
      int secs = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
      writeUintLE(buffer, secs);
    }
    writeBytes(buffer, utils.uBigIntToBytesLE(services, 8));
    writeBytes(buffer, address);
    writeBytes(buffer, [0xFF & port >> 8]);
    writeBytes(buffer, [0xFF & port]);
  }
}
