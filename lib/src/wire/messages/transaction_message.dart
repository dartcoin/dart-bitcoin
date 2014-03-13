part of dartcoin.core;

class TransactionMessage extends Message {
  
  Transaction _tx;
  
  TransactionMessage(Transaction tx, [NetworkParameters params]) : super("tx", params != null ? params : tx.params) {
    if(tx == null)
      throw new ArgumentError("tx should not be null");
    _tx = tx;
    _tx._parent = this;
  }
  
  // required for serialization
  TransactionMessage._newInstance() : super("tx", null);
  
  factory TransactionMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new TransactionMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Transaction get transaction {
    _needInstance();
    return _tx;
  }
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _tx = new Transaction.deserialize(bytes.sublist(offset), lazy: lazy, retain: retain, parent: this);
    offset += _tx.serializationLength;
    return offset; 
  }
  
  Uint8List _serialize_payload() => _tx.serialize();
}