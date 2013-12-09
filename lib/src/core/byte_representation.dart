part of dartcoin;

/**
 * Intended for mixin usage to enable lazy decoding in a class.
 * 
 * Because it is impossible to declare named constructors or factories in a mixin, 
 * classes using this mixin also need to define a constructor or factory themselves, 
 * forwarding the bytes to _fromBytes.
 * 
 * We recommend the constructor factory UsingClass.decode(Uint8List bytes) => _fromBytes(bytes);
 */
abstract class ByteRepresentation {
  
  Uint8List _byteRepresentation;
  bool _decoded;

  Uint8List _encode();
  
  void _decode(Uint8List bytes);
  
  Uint8List encode() {
    if(!_decoded) {
      return _byteRepresentation;
    }
    return _encode();
  }
  
  _fromBytes(Uint8List bytes) {
    this._byteRepresentation = bytes;
    _decoded = false;
  }
  
  _needInstance() {
    if(!_decoded) {
      _decode(_byteRepresentation);
      _byteRepresentation = null;
    }
  }
}