part of dartcoin.core;

class AlertMessage extends Message {
  //TODO implement AlertMessage
  
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
  AlertMessage._newInstance() : super("alert", null);

  factory AlertMessage.deserialize(Uint8List bytes, {int length, bool retain, NetworkParameters params, int protocolVersion}) => 
          new BitcoinSerialization.deserialize(new AlertMessage._newInstance(), bytes, length: length, lazy: false, retain: retain, params: params, protocolVersion: protocolVersion);
  
  Uint8List get message => _message;
  
  Uint8List get signature => _signature;
  
  bool get isSignatureValid =>
    KeyPair.verifySignatureForPubkey(message, 
        new ECDSASignature.fromDER(signature), params.alertSigningKey);
  
  int _deserializePayload(Uint8List bytes, bool lazy, bool retain) {
    int offset = 0;
    VarInt contentLength = new VarInt.deserialize(bytes, lazy: false);
    offset += contentLength.serializationLength;
    _message = bytes.sublist(offset, offset + contentLength.value);
    offset += contentLength.value;
    VarInt signatureLength = new VarInt.deserialize(bytes.sublist(offset), lazy: false);
    offset += signatureLength.serializationLength;
    _signature = bytes.sublist(offset, offset + signatureLength.value);
    offset += signatureLength.value;
    _parseMessage();
    return offset;
  }
  
  void _parseMessage() {
    int offset = 0;
    version = Utils.bytesToUintLE(_message, 4);
    offset += 4;
    relayUntil = new DateTime.fromMillisecondsSinceEpoch(
        Utils.bytesToUintLE(_message.sublist(offset), 8) * 1000);
    offset += 8;
    expiration = new DateTime.fromMillisecondsSinceEpoch(
            Utils.bytesToUintLE(_message.sublist(offset), 8) * 1000);
    offset += 8;
    id = Utils.bytesToUintLE(_message.sublist(offset), 4);
    offset += 4;
    cancel = Utils.bytesToUintLE(_message.sublist(offset), 4);
    offset += 4;
    VarInt cancelSetSize = new VarInt.deserialize(_message.sublist(offset), lazy: false);
    offset += cancelSetSize.serializationLength;
    cancelSet = new HashSet<int>();
    for(int i = 0 ; i < cancelSetSize.value ; i++) {
      cancelSet.add(Utils.bytesToUintLE(_message.sublist(offset), 4));
      offset += 4;
    }
    minVer = Utils.bytesToUintLE(_message.sublist(offset), 4);
    offset += 4;
    maxVer = Utils.bytesToUintLE(_message.sublist(offset), 4);
    offset += 4;
    VarInt subVerSetSize = new VarInt.deserialize(_message.sublist(offset), lazy: false);
    offset += subVerSetSize.serializationLength;
    matchingSubVer = new HashSet<String>();
    for(int i = 0 ; i < subVerSetSize.value ; i++) {
      VarStr subVer = new VarStr.deserialize(_message.sublist(offset), lazy: false);
      matchingSubVer.add(subVer.content);
      offset += subVer.serializationLength;
    }
    priority = Utils.bytesToUintLE(_message.sublist(offset), 4);
    offset += 4;
    VarStr commentStr = new VarStr.deserialize(_message.sublist(offset), lazy: false);
    comment = commentStr.content;
    offset += commentStr.serializationLength;
    VarStr statucBarStr = new VarStr.deserialize(_message.sublist(offset), lazy: false);
    statusBar = statucBarStr.content;
    offset += statucBarStr.serializationLength;
    VarStr reservedStr = new VarStr.deserialize(_message.sublist(offset), lazy: false);
    reserved = reservedStr.content;
    offset += reservedStr.serializationLength;
  }
  
  Uint8List _serialize_payload() { 
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




