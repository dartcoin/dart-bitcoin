part of dartcoin.wire;

class GetAddrMessage extends Message {
  
  GetAddrMessage() : super("getaddr");
  
  Uint8List encode_payload() {
    return new Uint8List(0);
  }
}