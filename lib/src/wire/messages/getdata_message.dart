part of dartcoin.wire;

class GetDataMessage extends InventoryItemContainerMessage {
  
  GetDataMessage(List<InventoryItem> items) : super(items, "getdata");
  
}