part of bitcoin.wire;

class NotFoundMessage extends InventoryItemContainerMessage {
  @override
  String get command => Message.CMD_NOTFOUND;

  NotFoundMessage(List<InventoryItem> items) : super(items);

  /// Create an empty instance.
  NotFoundMessage.empty();
}
