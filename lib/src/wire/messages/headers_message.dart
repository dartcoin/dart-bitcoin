part of dartcoin.core;

class HeadersMessage extends Message {
  
  List<Block> _headers;
  
  HeadersMessage(List<Block> headers) : super("headers") {
    _headers = headers;
  }

  factory HeadersMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new HeadersMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  List<Block> get headers { 
    _needInstance();
    return new UnmodifiableListView(_headers);
  }
  
  int _deserializePayload(Uint8List bytes) {
    int offset = 0;
    VarInt nbHeaders = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbHeaders.size;
    List<Block> headers = new List<Block>(nbHeaders.value);
    for(int i = 0 ; i < nbHeaders.value ; i++) {
      headers.add(new Block.deserialize(bytes.sublist(offset), length: Block.HEADER_SIZE + 1, lazy: false));
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