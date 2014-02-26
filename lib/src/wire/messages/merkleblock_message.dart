part of dartcoin.core;

class MerkleBlockMessage extends Message {
  
  FilteredBlock _block;
  
  MerkleBlockMessage(FilteredBlock block) : super("merkleblock") {
    _block = block;
  }
  
  factory MerkleBlockMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new MerkleBlockMessage(null), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  FilteredBlock get block {
    _needInstance();
    return _block;
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadDeserialization(bytes, this);
    _block = new FilteredBlock.deserialize(bytes.sublist(offset), lazy: false);
    offset += _block.serializationLength;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    return _block.serialize();
  }
}