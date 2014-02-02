part of dartcoin.wire;

class BlockMessage extends Message {
  
  Block block;
  
  BlockMessage(Block this.block) : super("block");
  
  factory BlockMessage.deserialize(Uint8List bytes) {
    
  }
  
  static BlockMessage deserializex() {
    return null;
  }
  
  Uint8List _serialize_payload() {
    return block.serialize();
  }
}