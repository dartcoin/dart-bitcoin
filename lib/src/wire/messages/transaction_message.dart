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
  
  @override
  void _deserializePayload() {
    _tx = _readObject(new Transaction._newInstance());
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeObject(sink, _tx);
  }
}