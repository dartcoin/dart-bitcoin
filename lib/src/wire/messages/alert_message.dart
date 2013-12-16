part of dartcoin.wire;

class AlertMessage extends Message {
  //TODO implement
  
  Uint8List _message;
  Uint8List _signature;
  
  int version;
  int relayUntil;
  int expiration;
  int id;
  int cancel;
  Set<int> setCancel;
  int minVer;
  int maxVer;
  Set<String> setSubVer;
  int priority;
  String comment;
  String statusBar;
  String reversed;
  
  AlertMessage(Uint8List message, Uint8List signature) : super("alert") {
    this._message = message;
    this._signature = signature;
  }
  
  Uint8List get message {
    if(_message == null)
      _message = _constructMessage();
    return _message;
  }
  
  Uint8List get signature {
    //TODO implement signing. (only necessary if we suppose holders of the alert key are going to use dartcoin)
    return _signature;
  }
  
  Uint8List _constructMessage() {
    List<int> result = new List<int>();
    result.addAll(Utils.intToBytesLE(version, 4));
    result.addAll(Utils.intToBytesLE(relayUntil, 8));
    result.addAll(Utils.intToBytesLE(expiration, 8));
    result.addAll(Utils.intToBytesLE(id, 4));
    result.addAll(Utils.intToBytesLE(cancel, 4));
    //TODO how to encode the sets?
    result.addAll(Utils.intToBytesLE(minVer, 4));
    result.addAll(Utils.intToBytesLE(maxVer, 4));
    //another set
    result.addAll(Utils.intToBytesLE(priority, 4));
    result.addAll(new VarStr(comment).serialize());
    result.addAll(new VarStr(statusBar).serialize());
    result.addAll(new VarStr(reversed).serialize());
    return new Uint8List.fromList(result);
  }
  
  Uint8List encode_payload() {
    List<int> result = new List<int>();
    result.addAll(message);
    result.addAll(signature);
    return new Uint8List.fromList(result);
  }
}