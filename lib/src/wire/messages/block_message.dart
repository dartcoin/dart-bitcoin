part of dartcoin.core;

class BlockMessage extends Message {
  
  Block _block;
  
  BlockMessage(Block block, [NetworkParameters params]) : super("block", params != null ? params : block.params) {
    if(block == null)
      throw new ArgumentError("block should not be null");
    _block = block;
    _block._parent = this;
  }
  
  // required for serialization
  BlockMessage._newInstance() : super("block", null);
  
  factory BlockMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new BlockMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Block get block {
    _needInstance();
    return _block;
  }
  
  @override
  void _deserializePayload() {
    _block = _readObject(new Block._newInstance());
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeObject(sink, _block);
  }
}