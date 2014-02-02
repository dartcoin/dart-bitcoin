part of dartcoin.wire;

abstract class InventoryItemContainerMessage extends Message {
  
  final List<InventoryItem> items;
  
  InventoryItemContainerMessage(List<InventoryItem> this.items, String command) : super(command) {
    if(items.length > 50000) {
      throw new Exception("Maximum 50000 inventory items");
    }
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>();
    result.addAll(new VarInt(items.length).serialize());
    for(InventoryItem item in items) {
      result.addAll(item.encode());
    }
    return new Uint8List.fromList(result);
  }
}