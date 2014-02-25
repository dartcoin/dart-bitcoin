part of dartcoin.core;

class GetDataMessage extends InventoryItemContainerMessage {
  
  GetDataMessage(List<InventoryItem> items) : super("getdata", items);

  factory GetDataMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new GetDataMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  
}