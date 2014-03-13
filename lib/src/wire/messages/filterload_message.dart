part of dartcoin.core;

class FilterLoadMessage extends Message {
  
  BloomFilter _filter;
  
  FilterLoadMessage(BloomFilter filter, [NetworkParameters params]) : super("filterload", params != null ? params : filter.params) {
    if(filter == null)
      throw new ArgumentError("filter should not be null");
    _filter = filter;
    _filter._parent = this;
  }
  
  // required for serialization
  FilterLoadMessage._newInstance() : super("filterload", null);
  
  factory FilterLoadMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new FilterLoadMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  BloomFilter get filter {
    _needInstance();
    return _filter;
  }
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _filter = new BloomFilter.deserialize(bytes.sublist(offset), lazy: lazy, retain: retain, parent: this);
    offset += _filter.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() => _filter.serialize();
  
}