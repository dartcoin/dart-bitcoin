part of dartcoin.core;

// TODO: implement when peer representation ready
class VersionMessage extends Message {
  
  final int version = 0x01000000;
  
  VersionMessage() : super("version") {
    
  }
  
  factory VersionMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new VersionMessage(), bytes, length: length, lazy: lazy);
  
  int _deserialize(Uint8List bytes) {
    //TODO
  }
  
  Uint8List _serialize_payload() {
    
  }
}