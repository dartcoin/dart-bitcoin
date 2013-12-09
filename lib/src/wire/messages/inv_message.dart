part of dartcoin.wire;

class InvMessage extends InventoryItemContainerMessage {
  
  InvMessage(List<InventoryItem> items) : super(items, "inv");
}