part of dartcoin.wire;

class TransactionMessage extends Message {
  @override
  String get command => Message.CMD_TX;

  Transaction transaction;

  TransactionMessage(Transaction this.transaction) {}

  /// Create an empty instance.
  TransactionMessage.empty();

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    transaction = readObject(reader, new Transaction.empty(), pver);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, transaction, pver);
  }
}
