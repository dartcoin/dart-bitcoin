part of dartcoin.wire;

class HeadersMessage extends Message {

  @override
  String get command => Message.CMD_HEADERS;
  
  List<BlockHeader> headers;
  
  HeadersMessage(List<BlockHeader> this.headers);
  
  /// Create an empty instance.
  HeadersMessage.empty();

  void addHeader(BlockHeader header) {
    headers.add(header);
  }
  
  void removeHeader(BlockHeader header) {
    headers.remove(header);
  }
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbHeaders = readVarInt(reader);
    List<BlockHeader> newHeaders = new List<Block>(nbHeaders);
    for(int i = 0 ; i < nbHeaders ; i++) {
      newHeaders[i] = readObject(reader, new BlockHeader.empty(), pver);
    }
    headers = newHeaders;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, headers.length);
    for(BlockHeader header in headers) {
      header.bitcoinSerializeAsEmptyBlock(buffer, pver);
    }
  }
}






