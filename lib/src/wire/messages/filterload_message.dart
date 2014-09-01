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
  
  @override
  void _deserializePayload() {
    _filter = _readObject(new BloomFilter._newInstance());
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeObject(sink, _filter);
  }
  
}