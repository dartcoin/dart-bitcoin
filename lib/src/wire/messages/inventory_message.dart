part of dartcoin.wire;

class InventoryMessage extends InventoryItemContainerMessage {
  @override
  String get command => Message.CMD_INV;

  InventoryMessage(List<InventoryItem> items) : super(items);

  /// Create an empty instance.
  InventoryMessage.empty();
}
