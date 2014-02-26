part of dartcoin.core;

class TxMessage extends Message {
  
  Transaction _tx;
  
  TxMessage(Transaction tx) : super("tx") {
    _tx = tx;
  }
  
  factory TxMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new TxMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  Transaction get tx {
    _needInstance();
    return _tx;
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadDeserialization(bytes, this);
    _tx = new Transaction.deserialize(bytes.sublist(offset), lazy: false);
    offset += _tx.serializationLength;
    return offset; 
  }
  
  Uint8List _serialize_payload() {
    return _tx.serialize();
  }
}