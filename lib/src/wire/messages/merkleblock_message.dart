part of dartcoin.wire;

class MerkleBlockMessage extends Message {

  @override
  String get command => Message.CMD_MERKLEBLOCK;
  
  FilteredBlock block;
  
  MerkleBlockMessage(FilteredBlock this.block);
  
  /// Create an empty instance.
  MerkleBlockMessage.empty();
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    block = readObject(reader, new FilteredBlock.empty(), pver);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, block, pver);
  }
}