part of dartcoin.core;

class InventoryItem extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_LENGTH = 4 + Sha256Hash.LENGTH;
  
  InventoryItemType _type;
  Sha256Hash _hash;
  
  InventoryItem(InventoryItemType type, Sha256Hash hash) {
    _type = type;
    _hash = hash;
  }

  InventoryItem.fromTransaction(Transaction tx) : this(InventoryItemType.MSG_TX, tx.hash);
  InventoryItem.fromBlock(Block block) : this(InventoryItemType.MSG_BLOCK, block.hash);
  
  factory InventoryItem.deserialize(Uint8List bytes, {bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new InventoryItem(null, null), bytes, length: SERIALIZATION_LENGTH, lazy: lazy);
  
  InventoryItemType get type {
    _needInstance();
    return _type;
  }
  
  Sha256Hash get hash {
    _needInstance();
    return _hash;
  }
  
  int _deserialize(Uint8List bytes) {
    _type = new InventoryItemType._(Utils.bytesToUintLE(bytes, 4));
    _hash = new Sha256Hash(bytes.sublist(4, Sha256Hash.LENGTH + 4));
    return SERIALIZATION_LENGTH;
  }
  
  @override
  int _lazySerializationLength(Uint8List bytes) => SERIALIZATION_LENGTH;
  
  Uint8List _serialize() {
    List<int> result = new List<int>()
      ..addAll(Utils.uintToBytesLE(type.value, 4))
      ..addAll(hash.bytes);
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