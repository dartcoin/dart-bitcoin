part of dartcoin.core;

class MerkleBlockMessage extends Message {
  
  FilteredBlock _block;
  
  MerkleBlockMessage(FilteredBlock block, [NetworkParameters params]) : super("merkleblock", params != null ? params : block.params) {
    if(block == null)
      throw new ArgumentError("block should not be null");
    _block = block;
    _block._parent = this;
  }
  
  // required for serialization
  MerkleBlockMessage._newInstance() : super("merkleblock", null);
  
  factory MerkleBlockMessage.deserialize(Uint8List bytes, {int length, bool lazy, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new MerkleBlockMessage._newInstance(), bytes, length: length, lazy: lazy, retain: retain, params: params, protocolVersion: protocolVersion);
  
  FilteredBlock get block {
    _needInstance();
    return _block;
  }
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    _block = new FilteredBlock.deserialize(bytes.sublist(offset), lazy: lazy, retain: retain, parent: this);
    offset += _block.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() => _block.serialize();
}