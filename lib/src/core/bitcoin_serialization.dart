part of dartcoin;

/**
 * Intended for mixin usage to enable lazy decoding in a class.
 * 
 * Because it is impossible to declare named constructors or factories in a mixin, 
 * classes using this mixin also need to define a constructor or factory themselves, 
 * forwarding the bytes to _fromBytes.
 * 
 * We recommend the constructor factory UsingClass.deserialize(Uint8List bytes) => _fromBytes(bytes);
 */
abstract class BitcoinSerialization {
  
  static const int UNKNOWN_LENGTH = -1;
  
  Uint8List _serialization = null;
  bool _isSerialized = false;
  bool retainSerialization = false;
  int _serializationLength = -1;
  
  /**
   * Serialize this object according to the Bitcoin protocol.
   */
  Uint8List serialize() {
    if(_isSerialized && _serializationLength != UNKNOWN_LENGTH) {
      return _serialization.sublist(0, serializationLength);
    }
    return _serialize();
  }
  
  /**
   * Use the deserialize() factory to create an instance of this class from it's serialized version.
   * 
   * Note on classes using the BitcoinSerialization mixin:
   * Using classes should have their own deserialization factory.
   * It is recommended to give it the exact same declaration as BitcoinSerialization.deserialize, 
   * but omitting the first parameter while replacing it with an empty instance in the supercall.
   * An example is:
   * 
   * factory Transaction.deserialize(Uint8List bytes, [int length]) => 
   *   new BitcoinSerialization.deserialize(new Transaction(), bytes, length);
   */
  factory BitcoinSerialization.deserialize(BitcoinSerialization instance, Uint8List bytes, 
      {int length: UNKNOWN_LENGTH, bool lazy: true}) {
    instance._fromSerialization(bytes, length);
    if(!lazy) {
      instance._needInstance();
    }
    return instance;
  }
  
  /**
   * Get the length of the serialization in bytes.
   * 
   * The calculation is done as lazy as possible.
   * 
   * Do not override this getter.
   */
  int get serializationLength {
    if(_serializationLength != UNKNOWN_LENGTH) 
      return _serializationLength;
    if(_serialization != null)
      _serializationLength = _lazySerializationLength(_serialization);
    else
      _serializationLength = serialize().length;
  }
  
  Uint8List _serialize();
  
  void _deserialize(Uint8List bytes);
  
  /**
   * Using classes can override this method to lazily calculate the serialization length.
   * The serialization can be found with _serialization.
   */
  int _lazySerializationLength(Uint8List bytes) {
    return serialize().length;
  }
  
  _fromSerialization(Uint8List bytes, int length) {
    _serialization = bytes;
    if(length != UNKNOWN_LENGTH)
      _serializationLength = length;
    _isSerialized = true;
  }
  
  _needInstance() {
    if(!_isSerialized)
      return
    _deserialize(_serialization);
    if(!retainSerialization)
      _serialization = null;
    _isSerialized = false;
  }
}