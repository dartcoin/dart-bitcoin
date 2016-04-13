part of dartcoin.wire;

class AlertMessage extends Message {

  @override
  String get command => Message.CMD_ALERT;
  
  static const int ALERT_VERSION = 1;
  
  // Chosen arbitrarily to avoid memory blowups.
  static const int MAX_SET_SIZE = 100;
  
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

  Uint8List messageChecksum;
  Uint8List signature;
  
  AlertMessage();
  
  /// Create an empty instance.
  AlertMessage.empty();
  
  bool isSignatureValid(Uint8List key) =>
    KeyPair.verifySignatureForPubkey(messageChecksum,
        new ECDSASignature.fromDER(signature), key);

  @override
  void bitcoinDeserialize(bytes.Reader reader, int pver) {
    signature = readByteArray(reader);
    ChecksumReader messageReader =
        new ChecksumReader(reader, new crypto.DoubleSHA256Digest());
    _readMessage(messageReader);
    messageChecksum = messageReader.checksum();
  }

  void _readMessage(bytes.Reader reader) {
    version = readUintLE(reader);
    relayUntil = new DateTime.fromMillisecondsSinceEpoch(readUintLE(reader, 8) * 1000);
    expiration = new DateTime.fromMillisecondsSinceEpoch(readUintLE(reader, 8) * 1000);
    id = readUintLE(reader);
    cancel = readUintLE(reader);
    int cancelSetSize = readVarInt(reader);
    cancelSet = new HashSet<int>();
    for(int i = 0 ; i < cancelSetSize ; i++) {
      cancelSet.add(readUintLE(reader));
    }
    minVer = readUintLE(reader);
    maxVer = readUintLE(reader);
    int subVerSetSize = readVarInt(reader);
    matchingSubVer = new HashSet<String>();
    for(int i = 0 ; i < subVerSetSize ; i++)
      matchingSubVer.add(readVarStr(reader));
    priority = readUintLE(reader);
    comment = readVarStr(reader);
    statusBar = readVarStr(reader);
    reserved = readVarStr(reader);
  }

  @override
  void bitcoinSerialize(bytes.Buffer buffer, int pver) {
    if(signature == null)
      throw new Exception("Cannot sign AlertMessages ourselves");
    _writeMessage(buffer);
    writeByteArray(buffer, signature);
  }
  
  void _writeMessage(bytes.Buffer buffer) {
    writeBytes(buffer, utils.uintToBytesLE(version, 4));
    writeBytes(buffer, utils.uintToBytesLE(relayUntil.millisecondsSinceEpoch ~/ 1000, 8));
    writeBytes(buffer, utils.uintToBytesLE(expiration.millisecondsSinceEpoch ~/ 1000, 8));
    writeBytes(buffer, utils.uintToBytesLE(id, 4));
    writeBytes(buffer, utils.uintToBytesLE(cancel, 4));
    //COMPLETE how to encode the sets?
    writeBytes(buffer, utils.uintToBytesLE(minVer, 4));
    writeBytes(buffer, utils.uintToBytesLE(maxVer, 4));
    //another set
    writeBytes(buffer, utils.uintToBytesLE(priority, 4));
    writeVarStr(buffer, comment);
    writeVarStr(buffer, statusBar);
    writeVarStr(buffer, reserved);
  }
}




