part of dartcoin.core;

// TODO: implement when peer representation ready
class VersionMessage extends Message {
  
  final int version = 0x01000000;
  
  VersionMessage() : super("version") {
    
  }
  
  factory VersionMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new VersionMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserialize(Uint8List bytes) {
    //TODO
  }
  
  Uint8List _serialize_payload() {
    
  }
}