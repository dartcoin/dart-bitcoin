part of dartcoin.core;

abstract class RequestMessage extends Message {
  
  List<Hash256> _locators;
  Hash256 _stop;
  
  RequestMessage(String command, List<Hash256> locators,
      [Hash256 stop, NetworkParameters params, int protocolVersion = NetworkParameters.PROTOCOL_VERSION]) : super(command, params) {
    if(stop == null) {
      stop = Hash256.ZERO_HASH;
    }
    _locators = locators;
    _stop = stop;
    this.protocolVersion = protocolVersion;
  }
  
  List<Hash256> get locators {
    _needInstance();
    return new UnmodifiableListView(_locators);
  }

  Hash256 get stop {
    _needInstance();
    return _stop;
  }
  
  void set stop(Hash256 stop) {
    _needInstance(true);
    _stop = stop;
  }
  
  void addLocator(Hash256 locator) {
    _needInstance(true);
    _locators.add(locator);
  }
  
  void removeLocator(Hash256 locator) {
    _needInstance(true);
    _locators.remove(locator);
  }
  
  // required for serialization
  RequestMessage._newInstance(String command) : super(command, null);
  
  @override
  void _deserializePayload() {
    protocolVersion = _readUintLE();
    int nbLocators = _readVarInt();
    _locators = new List<Hash256>(nbLocators);
    for(int i = 0 ; i < nbLocators ; i++) {
      _locators.add(_readSHA256());
    }
    _stop = _readSHA256();
  }

  @override
  void _serializePayload(ByteSink sink) {
    _writeUintLE(sink, protocolVersion);
    _writeVarInt(sink, _locators.length);
    for(Hash256 hash in _locators) {
      _writeSHA256(sink, hash);
    }
    _writeSHA256(sink, _stop);
  }
}