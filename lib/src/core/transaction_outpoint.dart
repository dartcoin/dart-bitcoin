part of bitcoin.core;

class TransactionOutPoint extends BitcoinSerializable {
  static const int SERIALIZATION_LENGTH = 36;

  Hash256 txid;
  int index;

  /// Can be `null` when this object has been created by deserialization.
  Transaction transaction;

  TransactionOutPoint({Transaction this.transaction, int this.index: 0, Hash256 this.txid}) {
    if (transaction != null) txid = transaction.hash;
    if (index == -1) index = 0xFFFFFFFF;
    txid = txid ?? Hash256.ZERO_HASH;
  }

  factory TransactionOutPoint.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new TransactionOutPoint.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }

  /// Create an empty instance.
  TransactionOutPoint.empty();

  TransactionOutput get connectedOutput {
    if (transaction == null) return null;
    return transaction.outputs[index];
  }

  @override
  operator ==(TransactionOutPoint other) {
    if (other is! TransactionOutPoint) return false;
    if (identical(this, other)) return true;
    return txid == other.txid &&
        index == other.index &&
        (transaction == null || other.transaction == null || transaction == other.transaction);
  }

  @override
  int get hashCode {
    return index.hashCode ^ txid.hashCode;
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeSHA256(buffer, txid);
    writeUintLE(buffer, index);
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    txid = readSHA256(reader);
    index = readUintLE(reader);
  }
}
