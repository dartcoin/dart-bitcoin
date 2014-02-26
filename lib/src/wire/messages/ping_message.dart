part of dartcoin.core;

class PingMessage extends Message {
  
  int _nonce;
  
  PingMessage([int nonce = null]) : super("ping") {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
    _nonce = nonce;
  }
  
  factory PingMessage.generate() {
    int nonce = new Random().nextInt(1 << 8);
    return new PingMessage(nonce);
  }

  factory PingMessage.deserialize(Uint8List bytes, {bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new PingMessage(), bytes, length: Message.HEADER_LENGTH + 8, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  bool get hasNonce {
    nonce != null;
  }
  
  int _deserializePayload(Uint8List bytes) {
    int offset = 0;
    _nonce = Utils.bytesToUintLE(bytes.sublist(offset), 8);
    offset += 8;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    if(hasNonce)
      return Utils.uintToBytesLE(nonce, 8);
    return Utils.uintToBytesLE(0, 8);
  }
  
}