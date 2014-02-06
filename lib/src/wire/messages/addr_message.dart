part of dartcoin.core;

//TODO implement when peer representation ready
class AddrMessage extends Message {
  
  AddrMessage() : super("addr") {
    
  }
  
  factory AddrMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
          new BitcoinSerialization.deserialize(new AddrMessage(), bytes, length: length, lazy: lazy);
  
  void _deserialize(Uint8List bytes) {
    
  }
  
  Uint8List _serialize_payload() {
    
  }
  
}