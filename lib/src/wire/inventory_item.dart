part of dartcoin.wire;

class InventoryItem {
  
  final InventoryItemType type;
  final Sha256Hash hash;
  
  InventoryItem(InventoryItemType this.type, Sha256Hash this.hash);

  InventoryItem.fromTransaction(Transaction tx) : this(InventoryItemType.MSG_TX, tx.hash);
  InventoryItem.fromBlock(Block block) : this(InventoryItemType.MSG_BLOCK, block.hash);
  
  Uint8List encode() {
    List<int> result = new List<int>();
    result.addAll(Utils.uintToBytesLE(type.value, 4));
    result.addAll(hash.bytes);
    return new Uint8List.fromList(result);
  }

  @override
  int get hashCode {
    return type.hashCode + hash.hashCode;
  }

  @override
  bool operator ==(InventoryItem other) {
    return type == other.type && hash == other.hash;
  }
}