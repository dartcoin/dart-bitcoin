part of dartcoin.wire;

class HeadersMessage extends Message {

  @override
  String get command => Message.CMD_HEADERS;
  
  List<Block> headers;
  
  HeadersMessage(List<Block> this.headers);
  
  /// Create an empty instance.
  HeadersMessage.empty();

  void addHeader(Block header) {
    headers.add(header);
  }
  
  void removeHeader(Block header) {
    headers.remove(header);
  }
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbHeaders = readVarInt(reader);
    List<Block> newHeaders = new List<Block>(nbHeaders);
    for(int i = 0 ; i < nbHeaders ; i++) {
      newHeaders[i] = readObject(reader, new Block.empty(), pver);
    }
    headers = newHeaders;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, headers.length);
    for(Block header in headers) {
      if(header.isHeader) {
        writeObject(buffer, header, pver);
      } else {
        writeObject(buffer, header.cloneAsHeader(), pver);
      }
    }
  }
}






