part of dartcoin.core;

class AddrMessage extends Message {

  static const int MAX_ADDRESSES = 1024;
  
  List<PeerAddress> _addresses;
  
  /**
   * Create a new address message with the given list of addresses.
   */
  AddrMessage(List<PeerAddress> addresses, [int protocolVersion]) : super("addr") {
    _addresses = addresses;
    this.protocolVersion = protocolVersion;
  }
  
  List<PeerAddress> get addresses {
    _needInstance();
    return new UnmodifiableListView(_addresses);
  }
  
  factory AddrMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new AddrMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  void addAddress(PeerAddress address) {
    _needInstance(true);
    _addresses.add(address);
  }
  
  void removeAddress(PeerAddress address) {
    _needInstance(true);
    _addresses.remove(address);
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadDeserialization(bytes, this);
    VarInt nbAddrs = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbAddrs.serializationLength;
    if(nbAddrs.value > MAX_ADDRESSES) 
      throw new SerializationException("Too many addresses in AddrMessage");
    List<PeerAddress> addresses = new List<PeerAddress>(nbAddrs.value);
    for(int i = 0 ; i < nbAddrs.value ; i++) {
      PeerAddress addr = new PeerAddress.deserialize(bytes.sublist(offset), lazy: false, params: params, protocolVersion: protocolVersion);
      addresses[i] = addr;
      offset += addr.serializationLength;
    }
    return offset;
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>()
      ..addAll(new VarInt(_addresses.length).serialize());
    _addresses.forEach((a) => result.addAll(a.serialize()));
    return new Uint8List.fromList(result);
  }
  
}