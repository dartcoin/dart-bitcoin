part of dartcoin.core;

//TODO implement locator stacking here?
abstract class RequestMessage extends Message {
  
  static final int _VERSION = 0x01000000;
  
  final int version = _VERSION;
  
  List<Sha256Hash> _locators;
  Sha256Hash _stop;
  
  RequestMessage(String command, List<Sha256Hash> locators, [Sha256Hash stop]) : super(command) {
    if(stop == null) {
      //TODO is this correct?
      stop = new Sha256Hash(Utils.uintToBytesLE(0, 32));
    }
    _locators = locators;
    _stop = stop;
  }
  
  List<Sha256Hash> get locators {
    _needInstance();
    return _locators;
  }
  
  Sha256Hash get stop {
    _needInstance();
    return _stop;
  }
  
  int _deserialize(Uint8List bytes) {
    int offset = Message._preparePayloadSerialization(bytes, this);
    int version = Utils.bytesToUintLE(bytes.sublist(offset), 4);
    if(version != _VERSION)
      throw new Exception("Version mismatch!");
    offset += 4;
    VarInt nbLocators = new VarInt.deserialize(bytes.sublist(offset));
    offset += nbLocators.size;
    _locators = new List<Sha256Hash>(nbLocators.value);
    for(int i = 0 ; i < nbLocators.value ; i++) {
      _locators.add(new Sha256Hash(bytes.sublist(offset, offset + Sha256Hash.LENGTH)));
      offset += Sha256Hash.LENGTH;
    }
    _stop = new Sha256Hash(bytes.sublist(offset, offset + Sha256Hash.LENGTH));
    offset += Sha256Hash.LENGTH;
    return offset;
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>()
      ..addAll(Utils.uintToBytesLE(version, 4))
      ..addAll(new VarInt(locators.length).serialize());
    for(Sha256Hash hash in locators) {
      result.addAll(hash.bytes);
    }
    result.addAll(stop.bytes);
    return new Uint8List.fromList(result);
  }
}