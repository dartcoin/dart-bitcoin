part of dartcoin.wire;

class MemPoolMessage extends Message {
  
  MemPoolMessage() : super("mempool");
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}