part of dartcoin.wire;

class HeadersMessage extends Message {
  
  List<Block> headers;
  
  HeadersMessage(List<Block> this.headers) : super("headers");
  
  Uint8List encode_payload() {
    List<int> result = new List<int>();
    result.addAll(new VarInt(headers.length).serialize());
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