part of dartcoin.core;

class HeadersMessage extends Message {
  
  List<Block> _headers;
  
  HeadersMessage(List<Block> headers, [NetworkParameters params]) : super("headers", params) {
    _headers = headers;
    for(Block header in _headers)
      header._parent = this;
  }
  
  // required for serialization
  HeadersMessage._newInstance() : super("headers", null);

  factory HeadersMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new HeadersMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  List<Block> get headers { 
    _needInstance();
    return new UnmodifiableListView(_headers);
  }
  
  void addHeader(Block header) {
    _needInstance(true);
    _headers.add(header);
    header._parent = this;
  }
  
  void removeHeader(Block header) {
    _needInstance(true);
    _headers.remove(header);
    header._parent = null;
  }
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    VarInt nbHeaders = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbHeaders.size;
    List<Block> headers = new List<Block>(nbHeaders.value);
    for(int i = 0 ; i < nbHeaders.value ; i++) {
      headers[i] = new Block.deserialize(bytes.sublist(offset), lazy: lazy, length: Block.HEADER_SIZE + 1, parent: this);
      offset += Block.HEADER_SIZE + 1;
    }
    _headers = headers;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>()
      ..addAll(new VarInt(_headers.length).serialize());
    for(Block header in _headers) {
      if(header.isHeader)
        result.addAll(header.serialize());
      else
        result.addAll(header.cloneAsHeader().serialize());
    }
    return new Uint8List.fromList(result);
  }
}