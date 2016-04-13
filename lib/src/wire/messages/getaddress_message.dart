part of dartcoin.wire;

class GetAddressMessage extends Message {

  @override
  String get command => Message.CMD_GETADDR;
  
  GetAddressMessage();
  
  /// Create an empty instance.
  GetAddressMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {}

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}