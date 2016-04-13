part of dartcoin.wire;

class HeadersMessage extends Message {

  @override
  String get command => Message.CMD_HEADERS;
  
  List<Block> _headers;
  
  HeadersMessage(List<Block> this._headers);
  
  /// Create an empty instance.
  HeadersMessage.empty();

  void addHeader(Block header) {
    _headers.add(header);
  }
  
  void removeHeader(Block header) {
    _headers.remove(header);
  }
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    int nbHeaders = readVarInt(reader);
    List<Block> headers = new List<Block>(nbHeaders);
    for(int i = 0 ; i < nbHeaders ; i++) {
      headers[i] = readObject(reader, new Block.empty(), pver);
    }
    _headers = headers;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeVarInt(buffer, _headers.length);
    for(Block header in _headers) {
      if(header.isHeader) {
        writeObject(buffer, header, pver);
      } else {
        writeObject(buffer, header.cloneAsHeader(), pver);
      }
    }
  }
}






