part of dartcoin.wire;

class GetDataMessage extends InventoryItemContainerMessage {
  @override
  String get command => Message.CMD_GETDATA;

  GetDataMessage(List<InventoryItem> items) : super(items);

  /// Create an empty instance.
  GetDataMessage.empty();
}
