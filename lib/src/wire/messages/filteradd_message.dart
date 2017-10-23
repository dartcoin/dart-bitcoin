part of dartcoin.wire;

class FilterAddMessage extends Message {
  @override
  String get command => Message.CMD_FILTERADD;

  static const int MAX_DATA_SIZE = 520;

  Uint8List data;

  FilterAddMessage(Uint8List this.data) {
    if (data.length > MAX_DATA_SIZE) throw new ArgumentError("Data attribute is too large.");
  }

  /// Create an empty instance.
  FilterAddMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    data = readByteArray(reader);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeByteArray(buffer, data);
  }
}
