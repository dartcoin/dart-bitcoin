part of dartcoin.core;

class AlertMessage extends Message {
  
  static const int ALERT_VERSION = 1;
  
  // Chosen arbitrarily to avoid memory blowups.
  static const int MAX_SET_SIZE = 100;
  
  Uint8List _message;
  Uint8List _signature;
  
  int version; // specific version for alert messages
  DateTime relayUntil;
  DateTime expiration;
  int id;
  int cancel;
  Set<int> cancelSet;
  int minVer;
  int maxVer;
  Set<String> matchingSubVer;
  int priority;
  String comment;
  String statusBar;
  String reserved;
  
  AlertMessage(Uint8List message, Uint8List signature, [NetworkParameters params]) : super("alert", params) {
    if(message == null || signature == null)
      throw new ArgumentError();
    this._message = message;
    this._signature = signature;
  }
  
  // required for serialization
  AlertMessage._newInstance() : super("alert", null) { _lazySerialization = false; }

  factory AlertMessage.deserialize(Uint8List bytes, {int length, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new AlertMessage._newInstance(), bytes, length: length, lazy: false, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Uint8List get message => _message;
  
  Uint8List get signature => _signature;
  
  bool get isSignatureValid =>
    KeyPair.verifySignatureForPubkey(Utils.doubleDigest(message),
        new ECDSASignature.fromDER(signature), params.alertSigningKey);

  @override
  void _deserializePayload() {
    int startCursor = _serializationCursor;
    _message = _readByteArray();
    _signature = _readByteArray();
    int finalCursor = _serializationCursor;
    _serializationCursor = startCursor;
    _readVarInt(); // skip content size varint
    _parseMessage();
    _serializationCursor = finalCursor;
  }

  void _parseMessage() {
    version = _readUintLE();
    relayUntil = new DateTime.fromMillisecondsSinceEpoch(_readUintLE(8) * 1000);
    expiration = new DateTime.fromMillisecondsSinceEpoch(_readUintLE(8) * 1000);
    id = _readUintLE();
    cancel = _readUintLE();
    int cancelSetSize = _readVarInt();
    cancelSet = new HashSet<int>();
    for(int i = 0 ; i < cancelSetSize ; i++) {
      cancelSet.add(_readUintLE());
    }
    minVer = _readUintLE();
    maxVer = _readUintLE();
    int subVerSetSize = _readVarInt();
    matchingSubVer = new HashSet<String>();
    for(int i = 0 ; i < subVerSetSize ; i++)
      matchingSubVer.add(_readVarStr());
    priority = _readUintLE();
    comment = _readVarStr();
    statusBar = _readVarStr();
    reserved = _readVarStr();
  }

  @override
  Uint8List _serializePayload() {
    if(_message != null && _signature != null) {
      return new Uint8List.fromList(new List<int>()
          ..addAll(new VarInt(_message.length).serialize())
          ..addAll(_message)
          ..addAll(new VarInt(_signature.length).serialize())
          ..addAll(_signature));
    }
    throw new Exception("Cannot sign AlertMessages ourselves");
  }
  
  Uint8List _constructMessage() {
    List<int> result = new List<int>()
      ..addAll(Utils.uintToBytesLE(version, 4))
      ..addAll(Utils.uintToBytesLE(relayUntil.millisecondsSinceEpoch ~/ 1000, 8))
      ..addAll(Utils.uintToBytesLE(expiration.millisecondsSinceEpoch ~/ 1000, 8))
      ..addAll(Utils.uintToBytesLE(id, 4))
      ..addAll(Utils.uintToBytesLE(cancel, 4))
    //COMPLETE how to encode the sets?
      ..addAll(Utils.uintToBytesLE(minVer, 4))
      ..addAll(Utils.uintToBytesLE(maxVer, 4))
    //another set
      ..addAll(Utils.uintToBytesLE(priority, 4))
      ..addAll(new VarStr(comment).serialize())
      ..addAll(new VarStr(statusBar).serialize())
      ..addAll(new VarStr(reserved).serialize());
    return new Uint8List.fromList(result);
  }
}




