part of dartcoin.core;

class GetDataMessage extends InventoryItemContainerMessage {
  
  GetDataMessage(List<InventoryItem> items, [NetworkParameters params]) : super("getdata", items, params);
  
  // required for serialization
  GetDataMessage._newInstance() : super._newInstance("getdata");

  factory GetDataMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new GetDataMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  
}