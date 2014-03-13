part of dartcoin.core;

class InventoryItemType {

  static const ERROR     = const InventoryItemType._(0);
  static const MSG_TX    = const InventoryItemType._(1);
  static const MSG_BLOCK = const InventoryItemType._(2);
  
  static get values => [ERROR, MSG_TX, MSG_BLOCK];
  
  final int value;
  
  const InventoryItemType._(int this.value);
}

class InventoryItem extends Object with BitcoinSerialization {
  
  static const int SERIALIZATION_LENGTH = 4 + Sha256Hash.LENGTH;
  
  InventoryItemType _type;
  Sha256Hash _hash;
  
  InventoryItem(InventoryItemType type, Sha256Hash hash) {
    if(type == null || hash == null)
      throw new ArgumentError("None of the attributes should be null");
    _type = type;
    _hash = hash;
    _serializationLength = SERIALIZATION_LENGTH;
  }

  InventoryItem.fromTransaction(Transaction tx) : this(InventoryItemType.MSG_TX, tx.hash);
  InventoryItem.fromBlock(Block block) : this(InventoryItemType.MSG_BLOCK, block.hash);
  
  // required for serialization
  InventoryItem._newInstance();
  
  factory InventoryItem.deserialize(Uint8List bytes, {bool lazy, bool retain, NetworkParameters params}) => 
          new BitcoinSerialization.deserialize(new InventoryItem._newInstance(), bytes, length: SERIALIZATION_LENGTH, lazy: lazy, retain: retain, params: params);
  
  InventoryItemType get type {
    _needInstance();
    return _type;
  }
  
  Sha256Hash get hash {
    _needInstance();
    return _hash;
  }
  
  int _deserialize(Uint8List bytes, bool lazy, bool retain) {
    _type = new InventoryItemType._(Utils.bytesToUintLE(bytes, 4));
    _hash = new Sha256Hash.deserialize(bytes.sublist(4, Sha256Hash.LENGTH + 4));
    return SERIALIZATION_LENGTH;
  }
  
  Uint8List _serialize() {
    return new Uint8List.fromList(new List<int>()
      ..addAll(Utils.uintToBytesLE(_type.value, 4))
      ..addAll(_hash.serialize()));
  }

  @override
  int get hashCode {
    _needInstance();
    return _type.hashCode + _hash.hashCode;
    // because hash collision is negligible, _hash.hashCode is enough. but we do it this way for elegance
  }

  @override
  bool operator ==(InventoryItem other) {
    if(!(other is InventoryItem)) return false;
    _needInstance();
    other._needInstance();
    return _type == other._type && _hash == other._hash;
  }
}