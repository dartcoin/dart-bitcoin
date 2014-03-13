part of dartcoin.core;

class NotFoundMessage extends InventoryItemContainerMessage {
  
  NotFoundMessage(List<InventoryItem> items, [NetworkParameters params]) : super("notfound", items, params);
  
  // required for serialization
  NotFoundMessage._newInstance() : super._newInstance("notfound");

  factory NotFoundMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new NotFoundMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
}