part of dartcoin.wire;

class FilterClearMessage extends Message {

  @override
  String get command => Message.CMD_FILTERCLEAR;
  
  FilterClearMessage();
  
  /// Create an empty instance.
  FilterClearMessage.empty();
  
  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {}

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}