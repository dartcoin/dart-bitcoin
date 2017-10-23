part of dartcoin.wire;

class BlockMessage extends Message {
  @override
  String get command => Message.CMD_BLOCK;

  Block block;

  BlockMessage(Block this.block);

  /// Create an empty instance.
  BlockMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    block = readObject(reader, new Block.empty(), pver) as Block;
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, block, pver);
  }
}
