part of dartcoin.core;

class PongMessage extends Message {
  
  /** The smallest protocol version that supports the pong response (BIP 31). Anything beyond version 60000. */
  static const int MIN_PROTOCOL_VERSION = 60001;
  
  int _nonce;
  
  PongMessage([int nonce = null, NetworkParameters params]) : super("pong", params) {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
    _nonce = nonce;
    _serializationLength = Message.HEADER_LENGTH + 8;
  }
  
  PongMessage.fromPing(PingMessage ping) : super("pong", ping.params) {
    _nonce = ping.nonce;
  }
  
  // required for serialization
  PongMessage._newInstance() : super("pong", null);
  
  factory PongMessage.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new PongMessage._newInstance(), bytes, length: Message.HEADER_LENGTH + 8, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  bool get hasNonce => nonce != null;
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _nonce = Utils.bytesToUintLE(bytes.sublist(offset), 8);
    offset += 8;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    if(hasNonce)
      return Utils.uintToBytesLE(_nonce, 8);
    return new Uint8List(0);
  }
  
}