part of dartcoin.core;

class GetDataMessage extends InventoryItemContainerMessage {
  
  GetDataMessage(List<InventoryItem> items) : super("getdata", items);

  factory GetDataMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new GetDataMessage(null), bytes, length: length, lazy: lazy);
  
  
}