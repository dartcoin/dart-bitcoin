part of bitcoin.wire;

class TransactionBroadcast extends Message {
  @override
  String get command => Message.CMD_TX;

  Transaction transaction;

  TransactionBroadcast(Transaction this.transaction) {}

  /// Create an empty instance.
  TransactionBroadcast.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    transaction = readObject(reader, new Transaction.empty(), pver);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, transaction, pver);
  }
}
