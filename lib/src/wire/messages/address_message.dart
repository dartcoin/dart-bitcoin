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
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    VarInt nbAddrs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbAddrs.serializationLength;
    if(nbAddrs.value > MAX_ADDRESSES) 
      throw new SerializationException("Too many addresses in AddressMessage");
    List<PeerAddress> addresses = new List<PeerAddress>(nbAddrs.value);
    for(int i = 0 ; i < nbAddrs.value ; i++) {
      PeerAddress addr = new PeerAddress.deserialize(bytes.sublist(offset), lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion, parent: this);
      addresses[i] = addr;
      offset += addr.serializationLength;
    }
    _addresses = addresses;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>()
      ..addAll(new VarInt(_addresses.length).serialize());
    _addresses.forEach((a) => result.addAll(a.serialize()));
    return new Uint8List.fromList(result);
  }
  
}