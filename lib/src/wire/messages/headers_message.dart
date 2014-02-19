part of dartcoin.core;

class HeadersMessage extends Message {
  
  List<Block> _headers;
  
  HeadersMessage(List<Block> headers) : super("headers") {
    _headers = headers;
  }

  factory HeadersMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new HeadersMessage(null), bytes, length: length, lazy: lazy);
  
  List<Block> get headers { 
    _needInstance();
    return _headers;
  }
  
  //TODO there's something phishy with the 80 vs 81 block header size
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    VarInt nbHeaders = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += nbHeaders.size;
    _headers = new List<Block>(nbHeaders.value);
    for(int i = 0 ; i < nbHeaders.value ; i++) {
      _headers.add(new Block.deserialize(bytes.sublist(offset), length: Block.HEADER_SIZE + 1, lazy: false));
      offset += Block.HEADER_SIZE + 1;
    }
    return offset;
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>()
      ..addAll(new VarInt(headers.length).serialize());
    for(Block header in headers) {
      if(header.isHeader)
        result.addAll(header.serialize());
      else
        result.addAll(header.cloneAsHeader().serialize());
      result.add(0);
    }
    return new Uint8List.fromList(result);
  }
}