part of dartcoin.core;

abstract class RequestMessage extends Message {
  
  List<Sha256Hash> _locators;
  Sha256Hash _stop;
  
  RequestMessage(String command, List<Sha256Hash> locators, 
      [Sha256Hash stop, NetworkParameters params, int protocolVersion = NetworkParameters.PROTOCOL_VERSION]) : super(command, params) {
    if(stop == null) {
      stop = Sha256Hash.ZERO_HASH;
    }
    _locators = locators;
    _stop = stop;
    this.protocolVersion = protocolVersion;
  }
  
  List<Sha256Hash> get locators {
    _needInstance();
    return new UnmodifiableListView(_locators);
  }
  
  Sha256Hash get stop {
    _needInstance();
    return _stop;
  }
  
  void set stop(Sha256Hash stop) {
    _needInstance(true);
    _stop = stop;
  }
  
  void addLocator(Sha256Hash locator) {
    _needInstance(true);
    _locators.add(locator);
  }
  
  void removeLocator(Sha256Hash locator) {
    _needInstance(true);
    _locators.remove(locator);
  }
  
  // required for serialization
  RequestMessage._newInstance(String command) : super(command, null);
  
  @override
  void _deserializePayload() {
    protocolVersion = _readUintLE();
    int nbLocators = _readVarInt();
    _locators = new List<Sha256Hash>(nbLocators);
    for(int i = 0 ; i < nbLocators ; i++) {
      _locators.add(new Sha256Hash.deserialize(_readBytes(32)));
    }
    _stop = new Sha256Hash.deserialize(_readBytes(32));
  }

  @override
  Uint8List _serializePayload() {
    List<int> result = new List<int>()
      ..addAll(Utils.uintToBytesLE(protocolVersion, 4))
      ..addAll(new VarInt(_locators.length).serialize());
    for(Sha256Hash hash in _locators) {
      result.addAll(hash.bytes);
    }
    result.addAll(_stop.bytes);
    return new Uint8List.fromList(result);
  }
}