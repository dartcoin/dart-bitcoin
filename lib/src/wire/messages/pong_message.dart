part of dartcoin.wire;

class PongMessage extends Message {
  
  int nonce;
  
  PongMessage([int this.nonce = null]) : super("pong") {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
  }
  
  PongMessage.fromPing(PingMessage ping) : super("pong") {
    nonce = ping.nonce;
  }
  
  bool get hasNonce {
    nonce != null;
  }
  
  Uint8List _serialize_payload() {
    if(hasNonce)
      return Utils.uintToBytesLE(nonce, 8);
    return new Uint8List(0);
  }
  
}