part of dartcoin.core;

//TODO implement when peer representation ready
class AddrMessage extends Message {
  
  AddrMessage() : super("addr") {
    
  }
  
  factory AddrMessage.deserialize(Uint8List bytes, {int length, bool lazy, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new AddrMessage(), bytes, length: length, lazy: lazy, params: params, protocolVersion: protocolVersion);
  
  int _deserialize(Uint8List bytes) {
    
  }
  
  Uint8List _serialize_payload() {
    
  }
  
}