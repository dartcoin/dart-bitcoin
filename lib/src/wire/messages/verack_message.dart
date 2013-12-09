part of dartcoin.wire;

class VerackMessage extends Message {
  
  VerackMessage() : super("verack");
  
  Uint8List encode_payload() {
    return new Uint8List(0);
  }
}