part of dartcoin.core;

class PeerAddress extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_SIZE = 30;
  
  InternetAddress _addr;
  int _port;
  BigInteger _services;
  int _time;
  
  PeerAddress(
      InternetAddress address, 
      {
       int port,
       int protocolVersion: NetworkParameters.PROTOCOL_VERSION,
       NetworkParameters params: NetworkParameters.MAIN_NET,
       BigInteger services, 
       int time
      }) {
    if(address == null) throw new Exception("The address argument should not be null");
    _addr = address;
    _port = (port != null) ? port : params.port;
    _services = (services != null) ? services : BigInteger.ZERO;
    _time = time;
    this.protocolVersion = protocolVersion;
    this.params = params;
    _serializationLength = this.protocolVersion > 31402 ? SERIALIZATION_SIZE : SERIALIZATION_SIZE - 4;
  }
  
  factory PeerAddress.localhost({NetworkParameters params: NetworkParameters.MAIN_NET, BigInteger services}) =>
    new PeerAddress(new InternetAddress("127.0.0.1"), params: params);
  
  factory PeerAddress.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) =>  
      new BitcoinSerialization.deserialize(new PeerAddress(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  InternetAddress get address {
    _needInstance();
    return _addr;
  }
  
  void set address(InternetAddress address) {
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
  
  @override
  String toString() {
    _needInstance();
    return "[${_addr.address}]:$_port";
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
  
  int _deserialize(Uint8List bytes) {
    int offset = 0;
    if(protocolVersion >= 31402) {
      _time = Utils.bytesToUintLE(bytes, 4);
      offset += 4;
    }
    _services = Utils.bytesToUBigIntLE(bytes.sublist(offset), 8);
    offset += 8;
    _addr = Utils.decodeInternetAddressAsIPv6(bytes.sublist(offset, offset + 16));
    offset += 16;
    _port = bytes[offset] << 8 + bytes[offset + 1];
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
      ..addAll(Utils.encodeInternetAddressAsIPv6(_addr))
      ..add(0xFF & _port >> 8)
      ..add(0xFF & _port);
    return new Uint8List.fromList(result);
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) {
    return protocolVersion > 31402 ? SERIALIZATION_SIZE : SERIALIZATION_SIZE - 4;
  }
  
}