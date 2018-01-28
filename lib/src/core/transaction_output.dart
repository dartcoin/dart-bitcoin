part of bitcoin.core;

class TransactionOutput extends BitcoinSerializable {
  int value;
  Script scriptPubKey;

  TransactionOutput({int this.value, Script this.scriptPubKey}) {
    if (value < -1 || value > NetworkParameters.MAX_MONEY)
      throw new ArgumentError("Amounts must be positive and smaller than the max value.");
  }

  factory TransactionOutput.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new TransactionOutput.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }

  /// Create an empty instance.
  TransactionOutput.empty();

  factory TransactionOutput.payToAddress(Address to, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(
        value: amount, scriptPubKey: new PayToPubKeyHashOutputScript.withAddress(to));
  }

  factory TransactionOutput.payToPubKey(KeyPair key, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(value: amount, scriptPubKey: new PayToPubKeyOutputScript(key));
  }

  factory TransactionOutput.payToScriptHash(Hash160 scriptHash, int amount,
      [Transaction parent, NetworkParameters params = NetworkParameters.MAIN_NET]) {
    return new TransactionOutput(
        value: amount, scriptPubKey: new PayToScriptHashOutputScript(scriptHash));
  }

  @override
  operator ==(dynamic other) {
    if (other.runtimeType != TransactionOutput) return false;
    if (identical(this, other)) return true;
    return value == other.value && scriptPubKey == other.scriptPubKey;
  }

  @override
  int get hashCode {
    return value.hashCode ^ scriptPubKey.hashCode;
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeUintLE(buffer, value, 8);
    writeByteArray(buffer, scriptPubKey.encode());
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    value = readUintLE(reader, 8);
    scriptPubKey = new Script(readByteArray(reader));
  }
}
