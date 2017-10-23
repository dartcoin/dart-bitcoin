part of bitcoin.wire;

class VerackMessage extends Message {
  @override
  String get command => Message.CMD_VERACK;

  VerackMessage();

  /// Create an empty instance.
  VerackMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {}

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {}
}
