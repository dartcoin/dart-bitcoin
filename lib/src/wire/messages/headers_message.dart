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
  
  @override
  void _deserializePayload() {
    int nbHeaders = _readVarInt();
    List<Block> headers = new List<Block>(nbHeaders);
    for(int i = 0 ; i < nbHeaders ; i++) {
      headers[i] = _readObject(new Block._newInstance(), length: Block.HEADER_SIZE + 1);
    }
    _headers = headers;
  }

  @override
  Uint8List _serializePayload() {
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