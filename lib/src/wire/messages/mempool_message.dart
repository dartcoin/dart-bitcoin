part of dartcoin.wire;

class MemPoolMessage extends Message {

  @override
  String get command => Message.CMD_MEMPOOL;
  
  MemPoolMessage();
  
  /// Create an empty instance.
  MemPoolMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {}

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}