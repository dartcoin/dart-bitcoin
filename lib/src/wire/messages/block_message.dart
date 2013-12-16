part of dartcoin.wire;

class BlockMessage extends Message {
  
  Block block;
  
  BlockMessage(Block this.block) : super("block");
  
  Uint8List encode_payload() {
    return block.serialize();
  }
}