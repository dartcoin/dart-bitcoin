part of dartcoin.wire;

class VerackMessage extends Message {
  
  VerackMessage() : super("verack");
  
  Uint8List _serialize_payload() {
    return new Uint8List(0);
  }
}