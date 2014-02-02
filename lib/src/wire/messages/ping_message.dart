part of dartcoin.wire;

class PingMessage extends Message {
  
  int nonce;
  
  PingMessage([int this.nonce = null]) : super("ping") {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
  }
  
  //TODO maybe PingMessage.generate() to get a new message with a random nonce
  
  bool get hasNonce {
    nonce != null;
  }
  
  Uint8List _serialize_payload() {
    if(hasNonce)
      return Utils.uintToBytesLE(nonce, 8);
    return new Uint8List(0);
  }
  
}