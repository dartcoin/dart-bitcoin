part of dartcoin.core;

class TxMessage extends Message {
  
  Transaction _tx;
  
  TxMessage(Transaction tx) : super("tx") {
    _tx = tx;
  }
  
  factory TxMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new TxMessage(null), bytes, length: length, lazy: lazy);
  
  Transaction get tx {
    _needInstance();
    return _tx;
  }
  
  void _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    _tx = new Transaction.deserialize(bytes.sublist(offset), lazy: false);
    _serializationLength = offset + _tx.serializationLength;
  }
  
  Uint8List _serialize_payload() {
    return _tx.serialize();
  }
}