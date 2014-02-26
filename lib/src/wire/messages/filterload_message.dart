part of dartcoin.core;

class FilterLoadMessage extends Message {
  
  BloomFilter _filter;
  
  FilterLoadMessage(BloomFilter filter) : super("filterload") {
    _filter = filter;
  }
  
  factory FilterLoadMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new FilterLoadMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  BloomFilter get filter {
    _needInstance();
    return _filter;
  }
  
  int _deserializePayload(Uint8List bytes) {
    int offset = 0;
    _filter = new BloomFilter.deserialize(bytes.sublist(offset), lazy: false);
    offset += _filter.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return _filter.serialize();
  }
  
}