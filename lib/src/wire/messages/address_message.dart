part of dartcoin.core;

class AddressMessage extends Message {

  static const int MAX_ADDRESSES = 1024;
  
  List<PeerAddress> _addresses;
  
  /**
   * Create a new address message with the given list of addresses.
   */
  AddressMessage(List<PeerAddress> addresses, [NetworkParameters params = NetworkParameters.MAIN_NET, int protocolVersion = NetworkParameters.PROTOCOL_VERSION]) : 
      super("addr", params) {
    _addresses = addresses != null ? addresses : new List<PeerAddress>();
    for(PeerAddress pa in _addresses)
      pa._parent = this;
    this.protocolVersion = protocolVersion;
  }
  
  // required for serialization
  AddressMessage._newInstance() : super("addr", null);
  
  factory AddressMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new AddressMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  List<PeerAddress> get addresses {
    _needInstance();
    return new UnmodifiableListView(_addresses);
  }
  
  void addAddress(PeerAddress address) {
    _needInstance(true);
    _addresses.add(address);
    address._parent = this;
  }
  
  void removeAddress(PeerAddress address) {
    _needInstance(true);
    _addresses.remove(address);
    address._parent = null;
  }

  @override
  void _deserializePayload() {
    int nbAddrs = _readVarInt();
    if(nbAddrs > MAX_ADDRESSES)
      throw new SerializationException("Too many addresses in AddressMessage");
    List<PeerAddress> addresses = new List<PeerAddress>(nbAddrs);
    for(int i = 0 ; i < nbAddrs ; i++) {
      addresses[i] = _readObject(new PeerAddress._newInstance());
    }
    _addresses = addresses;
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeVarInt(sink, _addresses.length);
    _addresses.forEach((a) => _writeObject(sink, a));
  }
  
}