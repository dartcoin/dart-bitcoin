part of dartcoin.core;

class NotFoundMessage extends InventoryItemContainerMessage {
  
  NotFoundMessage(List<InventoryItem> items) : super("notfound", items);

  factory NotFoundMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new NotFoundMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
}