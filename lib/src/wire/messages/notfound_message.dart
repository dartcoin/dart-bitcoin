part of dartcoin.wire;

class NotFoundMessage extends InventoryItemContainerMessage {
  
  NotFoundMessage(List<InventoryItem> items) : super(items, "notfound");
  
}