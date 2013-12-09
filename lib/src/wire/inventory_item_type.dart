part of dartcoin.wire;

class InventoryItemType {

  static const ERROR     = const InventoryItemType._(0);
  static const MSG_TX    = const InventoryItemType._(1);
  static const MSG_BLOCK = const InventoryItemType._(2);
  
  static get values => [ERROR, MSG_TX, MSG_BLOCK];
  
  final int value;
  
  const InventoryItemType._(int this.value);
}