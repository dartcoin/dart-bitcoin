part of dartcoin.wire;

abstract class RequestMessage extends Message {
  
  List<Hash256> locators;
  Hash256 stop;
  int protocolVersion;
  
  RequestMessage(List<Hash256> this.locators, [Hash256 this.stop]) {
    stop = stop ?? Hash256.ZERO_HASH;
  }
  
  void addLocator(Hash256 locator) {
    locators.add(locator);
  }
  
  void removeLocator(Hash256 locator) {
    locators.remove(locator);
  }

  /// Create an empty instance.
  RequestMessage.empty();
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    protocolVersion = readUintLE(reader);
    int nbLocators = readVarInt(reader);
    locators = new List<Hash256>(nbLocators);
    for(int i = 0 ; i < nbLocators ; i++) {
      locators.add(readSHA256(reader));
    }
    stop = readSHA256(reader);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeUintLE(buffer, protocolVersion);
    writeVarInt(buffer, locators.length);
    for(Hash256 hash in locators) {
      writeSHA256(buffer, hash);
    }
    writeSHA256(buffer, stop);
  }
}