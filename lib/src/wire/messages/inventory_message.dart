part of dartcoin.core;

class InventoryMessage extends InventoryItemContainerMessage {
  
  InventoryMessage(List<InventoryItem> items, [NetworkParameters params]) : super("inv", items, params);
  
  // required for serialization
  InventoryMessage._newInstance() : super._newInstance("inv");

  factory InventoryMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new InventoryMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
}