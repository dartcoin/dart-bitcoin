part of dartcoin.core;

class InvMessage extends InventoryItemContainerMessage {
  
  InvMessage(List<InventoryItem> items) : super("inv", items);

  factory InvMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new InvMessage(null), bytes, length: length, lazy: lazy);
  
}