part of dartcoin.wire;

// TODO: implement when peer representation ready
class VersionMessage extends Message {
  
  final int version = 0x01000000;
  
  VersionMessage() : super("version") {
    
  }
  
  Uint8List encode_payload() {
    
  }
}