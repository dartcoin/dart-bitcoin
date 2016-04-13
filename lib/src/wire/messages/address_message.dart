part of dartcoin.wire;

class AddressMessage extends Message {

  @override
  String get command => Message.CMD_ADDR;

  static const int MAX_ADDRESSES = 1024;
  
  List<PeerAddress> addresses;
  
  /**
   * Create a new address message with the given list of addresses.
   */
  AddressMessage([List<PeerAddress> this.addresses]) {
    addresses = addresses ?? new List<PeerAddress>();
  }
  
  /// Create an empty instance.
  AddressMessage.empty();
  
  void addAddress(PeerAddress address) {//TODO look at peeraddress btcd
    addresses.add(address);
  }
  
  void removeAddress(PeerAddress address) {
    addresses.remove(address);
  }

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbAddrs = readVarInt(reader);
    if(nbAddrs > MAX_ADDRESSES)
      throw new SerializationException("Too many addresses in AddressMessage");
    List<PeerAddress> newAddresses = new List<PeerAddress>(nbAddrs);
    for(int i = 0 ; i < nbAddrs ; i++) {
      newAddresses[i] = readObject(reader, new PeerAddress.empty(), pver);
    }
    addresses = newAddresses;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, addresses.length);
    addresses.forEach((a) => writeObject(buffer, a, pver));
  }
  
}