part of dartcoin.core;

class TransactionInput extends BitcoinSerializable {
  
  static const int NO_SEQUENCE = 0xFFFFFFFF;
  
  TransactionOutPoint outpoint;
  Script scriptSig;
  int sequence;
  
  /**
   * Create a new [TransactionInput].
   * 
   * It's not possible to specify both the [output] parameter and the [outpoint] parameter. 
   */
  TransactionInput({TransactionOutPoint this.outpoint,
                    Script this.scriptSig,
                    int this.sequence: NO_SEQUENCE}) {
    outpoint = outpoint ?? new TransactionOutPoint(index: NO_SEQUENCE);
    scriptSig = scriptSig ?? Script.EMPTY_SCRIPT;
  }
  
  /**
   * Create a coinbase transaction input. 
   * 
   * It is specified by its [TransactionOutPoint] format, but can carry any [Script] as [scriptSig].
   */
  TransactionInput.coinbase([Script this.scriptSig]) {
    outpoint = new TransactionOutPoint(txid: Hash256.ZERO_HASH, index: -1);
    scriptSig = scriptSig ?? Script.EMPTY_SCRIPT;
  }

  factory TransactionInput.fromBitcoinSerialization(Uint8List serialization, int pver) {
    var reader = new bytes.Reader(serialization);
    var obj = new TransactionInput.empty();
    obj.bitcoinDeserialize(reader, pver);
    return obj;
  }
  
  /// Create an empty instance.
  TransactionInput.empty();
  
  bool get isCoinbase {
    return outpoint.txid == Hash256.ZERO_HASH &&
        (outpoint.index & 0xFFFFFFFF) == 0xFFFFFFFF;
  }
  
  @override
  operator ==(TransactionInput other) {
    if(other is! TransactionInput) return false;
    if(identical(this, other)) return true;
    return outpoint == other.outpoint &&
        scriptSig == other.scriptSig &&
        sequence == other.sequence;
  }
  
  @override
  int get hashCode {
    return outpoint.hashCode ^ scriptSig.hashCode ^ sequence.hashCode;
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeObject(buffer, outpoint, pver);
    writeByteArray(buffer, scriptSig.encode());
    writeUintLE(buffer, sequence);
  }

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    outpoint = readObject(reader, new TransactionOutPoint.empty(), pver);
    scriptSig = new Script(readByteArray(reader));
    sequence = readUintLE(reader);
  }
}

