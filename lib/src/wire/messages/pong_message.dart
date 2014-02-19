part of dartcoin.core;

class PongMessage extends Message {
  
  int _nonce;
  
  PongMessage([int nonce = null]) : super("pong") {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
    _nonce = nonce;
  }
  
  PongMessage.fromPing(PingMessage ping) : super("pong") {
    _nonce = ping.nonce;
  }

  factory PongMessage.deserialize(Uint8List bytes, {bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new PongMessage(), bytes, length: Message.HEADER_LENGTH + 8, lazy: lazy);
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  bool get hasNonce {
    nonce != null;
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    _nonce = Utils.bytesToUintLE(bytes.sublist(offset), 8);
    offset += 8;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    if(hasNonce)
      return Utils.uintToBytesLE(nonce, 8);
    return new Uint8List(0);
  }
  
}