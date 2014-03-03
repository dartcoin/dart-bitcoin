part of dartcoin.core;

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
  // this flag means that only a serialization is present, so it has not been deserialized yet
  bool _isSerialized = false;
  bool _retainSerialization = false;
  int _serializationLength = UNKNOWN_LENGTH;
  
  // use getters for these attributes
  NetworkParameters _params;
  int _protocolVersion;
  
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
      { int length: UNKNOWN_LENGTH, 
        bool lazy: true, 
        NetworkParameters params: NetworkParameters.MAIN_NET, 
        int protocolVersion }) {
    instance._serialization = bytes;
    if(length != UNKNOWN_LENGTH)
      instance._serializationLength = length;
    instance._isSerialized = true;
    instance._params = params;
    instance._protocolVersion = protocolVersion;
    if(!lazy) {
      instance._needInstance();
    }
    return instance;
  }
  
  /**
   * Serialize this object according to the Bitcoin protocol.
   */
  Uint8List serialize() {
    if(_isSerialized) {
      if(_serializationLength <= UNKNOWN_LENGTH)
        _serializationLength = _lazySerializationLength(_serialization);
      return new Uint8List.fromList(_serialization.sublist(0, _serializationLength));
    }
    Uint8List seri = _serialize();
    _serializationLength = seri.length;
    if(retainSerialization)
      _serialization = seri;
    return new Uint8List.fromList(seri);
  }
  
  bool get retainSerialization => _retainSerialization;
  
  void set retainSerialization(bool retainSerialization) {
    _retainSerialization = retainSerialization;
    if(!retainSerialization && !_isSerialized)
      _serialization = null;
  }
  
  /**
   * Get the length of the serialization in bytes.
   * 
   * The calculation is done as lazy as possible.
   * 
   * Do not override this getter.
   */
  int get serializationLength {
    if(_serializationLength > UNKNOWN_LENGTH) 
      return _serializationLength;
    if(_isSerialized)
      _serializationLength = _lazySerializationLength(_serialization);
    else
      _serializationLength = _serialize().length;
    return _serializationLength;
  }
  
  Uint8List _serialize();
  
  /**
   * Deserialize the object using [bytes].
   * Should return the amount of bytes it used to deserialize. 
   * This is required because sometimes the bytes represent more than one object.
   */
  int _deserialize(Uint8List bytes);
  
  /**
   * [BitcoinSerialization] subclasses can override this method to lazily calculate the serialization length.
   */
  int _lazySerializationLength(Uint8List bytes) {
    _needInstance();
    return _serializationLength;
  }
  
  /**
   * Call this method to trigger deserialization when required.
   * 
   * This method is called when access to object attributes is required.
   */
  void _needInstance([bool clearCache = false]) {
    if(!_isSerialized) {
      if(clearCache) {
        _serialization = null;
        _serializationLength = UNKNOWN_LENGTH;
      }
      return;
    }
    _serializationLength = _deserialize(_serialization);
    if(!_retainSerialization)
      _serialization = null;
    _isSerialized = false;
  }
  
  NetworkParameters get params => (_params != null) ? _params : NetworkParameters.MAIN_NET;
  
  void set params(NetworkParameters params) {
    _params = params;
  }
  
  int get protocolVersion => (_protocolVersion != null) ? _protocolVersion : NetworkParameters.PROTOCOL_VERSION;
  
  void set protocolVersion(int protocolVersion) {
    _protocolVersion = protocolVersion;
  }
  
  
}



