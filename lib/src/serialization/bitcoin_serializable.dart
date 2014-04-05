part of dartcoin.core;

/**
 * This interface defines the minimal functions required to support Bitcoin serialization.
 * 
 * For using Bitcoin serialization, the [BitcoinSerialization] mixin is used.
 */
// interface
abstract class BitcoinSerializable {
  
  BitcoinSerializable.deserialize(Uint8List bytes,
      { int length, 
        bool lazy, 
        bool retain,
        NetworkParameters params, 
        int protocolVersion});
  
  Uint8List serialize();
  
  int get serializationLength;
  
}