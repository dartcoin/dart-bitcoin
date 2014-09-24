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
abstract class BitcoinSerialization implements BitcoinSerializable, TypedData {

  static const int UNKNOWN_LENGTH = -1;

  ByteBuffer _serializationBuffer;
  int _serializationOffset;
  // the cursor should always be null when not actively deserializing
  int _serializationCursor;
  // this flag means that only a serialization is present, so it has not been deserialized yet
  bool _instanceReady = true;
  bool _lazySerialization; // subclasses force immedaite deserialization by setting this to false
  bool _retainSerialization = false;
  int _serializationLength = UNKNOWN_LENGTH;

  // use getters for these attributes
  //  (for unit tests, they can be hard coded before deserialization by setting them on the new instance)
  NetworkParameters _params;
  int _protocolVersion;
  
  BitcoinSerialization _parent;

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
        bool retain: false,
        NetworkParameters params: NetworkParameters.MAIN_NET, 
        int protocolVersion,
        BitcoinSerialization parent}) {
    // make sure the Uint8List is not a view on a buffer that is actually larger
    //  if this is the case, we copy the Uint8List so that we get a new ByteBuffer
    return new BitcoinSerialization._internal(instance, bytes.buffer, bytes.offsetInBytes, bytes.lengthInBytes,
        lazy, retain, params, protocolVersion, parent);
  }

  factory BitcoinSerialization._internal(BitcoinSerialization instance, ByteBuffer buffer, int offset, int length,
      bool lazy, bool retain, NetworkParameters params, int protocolVersion, BitcoinSerialization parent) {
    // fix defaults from subconstructors that default to null
    if(instance._lazySerialization == null) // subclasses can force immediate deserializing by setting lazy to false
      instance._lazySerialization = lazy != null ? lazy : true;
    if(retain == null) retain = false;
    if(length == null) length = UNKNOWN_LENGTH;
    if(params == null) params = NetworkParameters.MAIN_NET;
    //
    instance._serializationBuffer = buffer;
    instance._serializationOffset = offset;
    if(length != UNKNOWN_LENGTH) instance._serializationLength = length;
    instance._retainSerialization = retain;
    instance._instanceReady = false;
    // allow hardcoding them
    instance._params = instance._params == null ? params : instance._params;
    instance._protocolVersion = instance._protocolVersion == null ? protocolVersion : instance._protocolVersion;
    instance._parent = instance._parent == null ? parent : instance._parent;
    if(!instance._lazySerialization) {
      instance._performDeserialization();
    }
    return instance;
  }

  /**
   * Serialize this object according to the Bitcoin protocol.
   */
  Uint8List serialize() {
    if (isCached) {
      if (_serializationLength <= UNKNOWN_LENGTH)
        _performLazyDeserialization();
      return new Uint8List.view(_serializationBuffer, _serializationOffset, _serializationLength);
    }
    ByteSink sink = new ByteSink();
    _serialize(sink);
    Uint8List seri = sink.toUint8List();
    _serializationLength = seri.lengthInBytes;
    if (retainSerialization) {
      _serializationBuffer = seri.buffer;
      _serializationOffset = seri.offsetInBytes;
      return new Uint8List.fromList(seri);
    }
    return seri;
  }

  /**
   * Override this method to perform the serialization of an object.
   *
   * Bytes should be added to the sink.
   *
   * Do not use this method inside _serialize() bodies, use _writeObject() instead.
   */
  void _serialize(ByteSink byteSink);

  bool get retainSerialization => _retainSerialization;

  void set retainSerialization(bool retainSerialization) {
    _retainSerialization = retainSerialization;
    if (!retainSerialization && _instanceReady) {
      _serializationBuffer = null;
      _serializationOffset = 0;
    }
  }

  /**
   * Get the length of the serialization in bytes.
   * 
   * The calculation is done as lazy as possible.
   * 
   * Do not override this getter.
   */
  int get serializationLength {
    if (_serializationLength > UNKNOWN_LENGTH)
      return _serializationLength;
    if (!_instanceReady) {
      _performLazyDeserialization();
    } else {
      ByteSink sink = new ByteSink();
      _serialize(sink);
      _serializationLength = sink.size;
    }
    return _serializationLength;
  }

  /**
   * Returns true if the instance of this serialization is ready and 
   * false if only a serialized version is present.
   */
  bool get instanceReady => _instanceReady;

  bool get isCached => _serializationBuffer != null;

  /**
   * Deserialize the object using [bytes].
   * Should return the amount of bytes it used to deserialize. 
   * This is required because sometimes the bytes represent more than one object.
   * 
   * The lazy bool indicates whether sub-serializations should be lazily created or not.
   */
  void _deserialize();

  /**
   * [BitcoinSerialization] subclasses can override this method to lazily calculate the serialization length.
   * This method goes over the serialization, but does not interpret it more than required to know the final
   * length of the serialization.
   */
  void _deserializeLazy() {
    _needInstance();
  }

  /**
   * Call this method to trigger deserialization when required.
   * 
   * This method is called when access to object attributes is required.
   */
  void _needInstance([bool clearCache = false]) {
    clearCache = clearCache != null ? clearCache : false;
    if(!_instanceReady) {
      _performDeserialization();
    }
    if(clearCache) {
      _serializationBuffer = null;
      _serializationOffset = 0;
      _serializationLength = UNKNOWN_LENGTH;
      if(_parent != null)
        _parent._needInstance(true);
    }
  }
  
  void _performDeserialization() {
    _serializationCursor = _serializationOffset;
    _deserialize();
    _serializationLength = _serializationCursor - _serializationOffset;
    _serializationCursor = null;
    if (!_retainSerialization) {
      _serializationBuffer = null;
      _serializationOffset = 0;
    }
    _instanceReady = true;
  }

  void _performLazyDeserialization() {
    _serializationCursor = _serializationOffset;
    _deserializeLazy();
    _serializationLength = _serializationLength > UNKNOWN_LENGTH ? _serializationLength :
        _serializationCursor - _serializationOffset;
    _serializationCursor = null;
  }

  NetworkParameters get params => (_params != null) ? _params :
      NetworkParameters.MAIN_NET;

  void set params(NetworkParameters params) {
    _params = params;
  }

  int get protocolVersion => (_protocolVersion != null) ? _protocolVersion :
      NetworkParameters.PROTOCOL_VERSION;

  void set protocolVersion(int protocolVersion) {
    _protocolVersion = protocolVersion;
  }
  
  BitcoinSerialization get parent => _parent;


  // methods inherited from TypedData

  @override
  ByteBuffer get buffer => _serializationBuffer;
  @override
  int get elementSizeInBytes => serializationLength;
  @override
  int get lengthInBytes => serializationLength;
  @override
  int get offsetInBytes => _serializationOffset;

  // active deserialization methods

  void _deserializationBytesRequired(int lenght) {
    if(_serializationCursor + lenght > _serializationBuffer.lengthInBytes)
      throw new SerializationException("The provided serialization is invalid or not complete.");
  }

  int _deserializationBytesAvailable() {
    if(_serializationLength > UNKNOWN_LENGTH)
      return _serializationLength - (_serializationCursor - _serializationOffset);
    return _serializationBuffer.lengthInBytes - _serializationCursor;
  }

  Uint8List _readBytes(int length) {
    _deserializationBytesRequired(length);
    Uint8List result = new Uint8List.view(_serializationBuffer, _serializationCursor, length);
    _serializationCursor += length;
    return result;
  }

  BitcoinSerialization _readObject(BitcoinSerialization instance, {int length, bool lazy}) {
    if(length != null)
      _deserializationBytesRequired(length);
    BitcoinSerialization result = new BitcoinSerialization._internal(instance,
        _serializationBuffer, _serializationCursor, length,
        (lazy != null ? lazy : _lazySerialization), _retainSerialization, params, protocolVersion, this);
    _serializationCursor += result.serializationLength;
    return result;
  }

  int _readVarInt() {
    VarInt vi = _readObject(new VarInt._newInstance(), lazy: false);
    return vi.value;
  }

  String _readVarStr() {
    VarStr vs = _readObject(new VarStr._newInstance(), lazy: false);
    return vs.content;
  }

  Uint8List _readByteArray() {
    int size = _readVarInt();
    return _readBytes(size);
  }

  int _readUintLE([int length = 4]) {
    int result = Utils.bytesToUintLE(_readBytes(length), length);
    return result;
  }

  /**
   * In the Bitcoin protocol, hashes are serialized in little endian.
   */
  Hash256 _readSHA256() {
    return new Hash256(Utils.reverseBytes(_readBytes(32)));
  }

  void _writeObject(ByteSink sink, BitcoinSerializable obj) {
    if(obj is BitcoinSerialization) {
      if (obj.isCached) {
        if (obj._serializationLength <= UNKNOWN_LENGTH)
          obj._performLazyDeserialization();
        sink.add(new Uint8List.view(obj._serializationBuffer, obj._serializationOffset, obj._serializationLength));
      } else {
        obj._serialize(sink);
      }
    } else {
      sink.add(obj.serialize());
    }
  }

  void _writeUintLE(ByteSink sink, int value, [int length = 4]) {
    sink.add(Utils.uintToBytesLE(value, length));
  }

  void _writeVarInt(ByteSink sink, int value) {
    _writeObject(sink, new VarInt(value));
  }

  void _writeString(ByteSink sink, String string) {
    _writeObject(sink, new VarStr(string));
  }

  void _writeByteArray(ByteSink sink, Uint8List bytes) {
    _writeObject(sink, new VarInt(bytes.length));
    sink.add(bytes);
  }

  /**
   * In the Bitcoin protocol, hashes are serialized in little endian.
   */
  void _writeSHA256(ByteSink sink, Hash256 hash) {
    sink.add(Utils.reverseBytes(hash));
  }

}

