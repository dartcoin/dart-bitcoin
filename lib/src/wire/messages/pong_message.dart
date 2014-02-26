part of dartcoin.core;

class PongMessage extends Message {
  
  /** The smallest protocol version that supports the pong response (BIP 31). Anything beyond version 60000. */
  static const int MIN_PROTOCOL_VERSION = 60001;
  
  int _nonce;
  
  PongMessage([int nonce = null]) : super("pong") {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
    _nonce = nonce;
  }
  
  PongMessage.fromPing(PingMessage ping) : super("pong") {
    _nonce = ping.nonce;
  }

  factory PongMessage.deserialize(Uint8List bytes, {bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new PongMessage(), bytes, length: Message.HEADER_LENGTH + 8, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
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
    return new Uint8List(0);
  }
  
}