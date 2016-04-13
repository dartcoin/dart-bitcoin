part of dartcoin.wire;

class InventoryItemType {

  static const ERROR     = const InventoryItemType._(0);
  static const MSG_TX    = const InventoryItemType._(1);
  static const MSG_BLOCK = const InventoryItemType._(2);
  
  static get values => [ERROR, MSG_TX, MSG_BLOCK];
  
  final int value;
  
  const InventoryItemType._(int this.value);
}

class InventoryItem extends BitcoinSerializable {
  
  static const int SERIALIZATION_LENGTH = 4 + Hash256.LENGTH;
  
  InventoryItemType type;
  Hash256 hash;
  
  InventoryItem(InventoryItemType this.type, Hash256 this.hash) {
    if(type == null || hash == null)
      throw new ArgumentError("None of the attributes should be null");
  }

  InventoryItem.fromTransaction(Transaction tx) : this(InventoryItemType.MSG_TX, tx.hash);
  InventoryItem.fromBlock(Block block) : this(InventoryItemType.MSG_BLOCK, block.hash);
  
  // required for serialization
  InventoryItem.empty();

  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    type = new InventoryItemType._(readUintLE(reader));
    hash = readSHA256(reader);
  }

  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    writeUintLE(buffer, type.value);
    writeSHA256(buffer, hash);
  }

  @override
  int get hashCode {
    return type.hashCode + hash.hashCode;
    // because hash collision is negligible, _hash.hashCode is enough. but we do it this way for elegance
  }

  @override
  bool operator ==(InventoryItem other) {
    if(!(other is InventoryItem)) return false;
    return type == other.type && hash == other.hash;
  }
}