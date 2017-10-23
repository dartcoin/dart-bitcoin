part of dartcoin.wire;

class FilterLoadMessage extends Message {
  @override
  String get command => Message.CMD_FILTERLOAD;

  BloomFilter filter;

  FilterLoadMessage(BloomFilter this.filter);

  /// Create an empty instance.
  FilterLoadMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    filter = readObject(reader, new BloomFilter.empty(), pver);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, filter, pver);
  }
}
