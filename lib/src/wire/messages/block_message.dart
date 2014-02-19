part of dartcoin.core;

class BlockMessage extends Message {
  
  Block _block;
  
  BlockMessage(Block block) : super("block") {
    _block = block;
  }
  
  factory BlockMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new BlockMessage(null), bytes, length: length, lazy: lazy);
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    _block = new Block.deserialize(bytes.sublist(offset), lazy: false);
    offset += _block.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return _block.serialize();
  }
}