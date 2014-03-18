part of dartcoin.core;

class PeerAddress extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_SIZE = 30;
  
  Uint8List _addr;
  int _port;
  BigInteger _services;
  int _time;
  
  /**
   * 
   * 
   * The [address] parameter should either by a [String] or [Uint8List].
   */
  PeerAddress(
      dynamic address, 
      {
       int port,
       int protocolVersion: NetworkParameters.PROTOCOL_VERSION,
       NetworkParameters params: NetworkParameters.MAIN_NET,
       BigInteger services, 
       int time
      }) {
    _addr = _formatAddress(address);
    _port = (port != null) ? port : params.port;
    _services = (services != null) ? services : BigInteger.ZERO;
    _time = time;
    this.protocolVersion = protocolVersion != null ? protocolVersion : NetworkParameters.PROTOCOL_VERSION;
    this.params = params;
    _serializationLength = this.protocolVersion > 31402 ? SERIALIZATION_SIZE : SERIALIZATION_SIZE - 4;
  }
  
  factory PeerAddress.localhost({NetworkParameters params: NetworkParameters.MAIN_NET, BigInteger services, int protocolVersion}) =>
    new PeerAddress("127.0.0.1", params: params, protocolVersion: protocolVersion);

  // required for serialization
  PeerAddress._newInstance();
  
  factory PeerAddress.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion, BitcoinSerialization parent}) =>  
      new BitcoinSerialization.deserialize(new PeerAddress._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion, parent: parent);
  
  static Uint8List _formatAddress(dynamic address) {
    if(address == null)
      throw new ArgumentError("The address argument should not be null");
    if(address is String) {
      try {
        address = new Uint8List.fromList(Uri.parseIPv6Address(address));
      } on FormatException {}
      try {
        address = new Uint8List.fromList(Uri.parseIPv4Address(address));
      } on FormatException {}
      if(address is String)
        throw new FormatException("Bad IP address format!");
    }
    if(address is! Uint8List)
      throw new ArgumentError("Invalid address parameter type");
    if(address.length == 4) {
      address = new Uint8List.fromList(new List.filled(16, 0)..setRange(12, 16, address));
      address[10] = 0xff;
      address[11] = 0xff;
    }
    if(address.length != 16)
      throw new ArgumentError("Invalid address length. Must be either 4 or 16 bytes long.");
    return address;
  }
  
  Uint8List get address {
    _needInstance();
    return _addr;
  }
  
  void set address(Uint8List address) {
    _needInstance(true);
    _addr = address;
  }
  
  int get port {
    _needInstance();
    return _port;
  }
  
  void set port(int port) {
    _needInstance(true);
    _port = port;
  }
  
  BigInteger get services {
    _needInstance();
    return _services;
  }
  
  void set services(BigInteger services) {
    _needInstance(true);
    _services = services;
  }
  
  int get time {
    _needInstance();
    return _time;
  }
  
  void set time(int time) {
    _needInstance(true);
    _time = time;
  }
  
  /**
   * Version messages need [PeerAddress]es with [protocolVerion] = 0.
   * (Timestamp should nog be encoded in it (length 26 bytes).
   * 
   * We use this method on the [VersionMessage] constructor instead of checking it
   * when serializing, because the constructor will be used significantly less frequently
   * than the serialize method.
   */
  PeerAddress get _forVersionMessage {
    if(protocolVersion == 0) return this;
    _needInstance();
    return new PeerAddress(_addr, port: _port, protocolVersion: 0, params: params, services: _services, time: _time);
  }
  
  @override
  String toString() {
    _needInstance();
    return "[${_addr}]:$_port";
  }
  
  @override
  bool operator ==(PeerAddress other) {
    if(!(other is PeerAddress)) return false;
    _needInstance();
    other._needInstance();
    return _addr == other._addr &&
        _port == other._port &&
        _services == other._services &&
        _time == other._time;
  }
  
  @override
  int get hashCode {
    _needInstance();
    return _addr.hashCode ^ port.hashCode ^ time.hashCode ^ _services.hashCode;
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    if(protocolVersion >= 31402) {
      _time = Utils.bytesToUintLE(bytes, 4);
      offset += 4;
    }
    _services = Utils.bytesToUBigIntLE(bytes.sublist(offset), 8);
    offset += 8;
    _addr = bytes.sublist(offset, offset + 16);
    offset += 16;
    _port = (0xff & bytes[offset]) << 8 | (0xff & bytes[offset + 1]);
    offset += 2;
    return offset;
  }
  
  Uint8List _serialize() {
    List<int> result = new List<int>();
    if(protocolVersion >= 31402) {
      //TODO (copied from Java) this appears to be dynamic because the client only ever sends out it's own address
      //so assumes itself to be up.  For a fuller implementation this needs to be dynamic only if
      //the address refers to this client.
      int secs = new DateTime.now().millisecondsSinceEpoch ~/ 1000;
      result.addAll(Utils.uintToBytesLE(secs, 4));
    }
    result..addAll(Utils.uBigIntToBytesLE(_services, 8))
      ..addAll(_addr)
      ..add(0xFF & _port >> 8)
      ..add(0xFF & _port);
    return new Uint8List.fromList(result);
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) {
    return protocolVersion > 31402 ? SERIALIZATION_SIZE : SERIALIZATION_SIZE - 4;
  }
  
}