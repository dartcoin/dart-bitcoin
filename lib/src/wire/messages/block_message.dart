part of dartcoin.core;

class BlockMessage extends Message {
  
  Block _block;
  
  BlockMessage(Block block) : super("block") {
    _block = block;
  }
  
  Block get block {
    _needInstance();
    return _block;
  }
  
  factory BlockMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new BlockMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserializePayload(Uint8List bytes) {
    int offset = 0;
    _block = new Block.deserialize(bytes.sublist(offset), lazy: false);
    offset += _block.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return _block.serialize();
  }
}