part of dartcoin.core;

class PingMessage extends Message {
  
  int _nonce;
  
  PingMessage([int nonce = null, NetworkParameters params]) : super("ping", params) {
    if(nonce != null && nonce < 0)
      throw new Exception("Nonce value should be at least zero");
    _nonce = nonce;
    _serializationLength = Message.HEADER_LENGTH + 8;
  }
  
  factory PingMessage.generate() {
    int nonce = new Random().nextInt(1 << 8);
    return new PingMessage(nonce);
  }
  
  // required for serialization
  PingMessage._newInstance() : super("ping", null);

  factory PingMessage.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new PingMessage._newInstance(), bytes, length: Message.HEADER_LENGTH + 8, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  int get nonce {
    _needInstance();
    return _nonce;
  }
  
  bool get hasNonce => nonce != null;
  
  @override
  void _deserializePayload() {
    _nonce = _readUintLE(8);
  }

  @override
  void _serializePayload(ByteSink sink) {
    if(hasNonce)
      _writeUintLE(sink, _nonce, 8);
    else
      _writeUintLE(sink, 0, 8);
  }
  
}