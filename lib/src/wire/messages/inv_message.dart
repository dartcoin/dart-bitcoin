part of dartcoin.core;

class InvMessage extends InventoryItemContainerMessage {
  
  InvMessage(List<InventoryItem> items) : super("inv", items);

  factory InvMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
      new BitcoinSerialization.deserialize(new InvMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
}