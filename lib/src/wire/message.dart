part of dartcoin.wire;

abstract class Message extends Object with BitcoinSerialization {
  
  Map<String, Function> _messageConstructors = {
    "block": BlockMessage
  };
  
  static const int COMMAND_LENGTH = 12;
  
  int magic;
  String command;
  
  Uint8List _payload;
  Uint8List _checksum;
  
  Message(String this.command) {
    magic = NetworkParameters.MAIN_NET.magicValue;
  }
  
  Message.withPayload(String this.command, Uint8List payload) {
    magic = NetworkParameters.MAIN_NET.magicValue;
    _payload = payload;
  }
  
  Message.withMagic(int this.magic, String this.command, [Uint8List payload]) {
    _payload = payload;
  }
  
  factory Message.deserialize(Uint8List bytes, 
      {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) {
    //String command
  }
  
  Uint8List _serialize_payload();
  
  Uint8List get payload {
    if(_payload == null)
      return _serialize_payload();
    return _payload;
  }
  
  Uint8List get checksum {
    if(_checksum == null)
      _checksum = _calculateChecksum();
    return _checksum;
  }
  
  Uint8List _calculateChecksum() {
    Sha256Hash sum = Sha256Hash.doubleDigest(payload);
    _checksum = sum.bytes.getRange(0, 4);
  }
  
  Uint8List _serialize() {
    if(command.length > 12)
      throw new Exception("Command length should not be greater than 12.");
    List<int> result = new List<int>();
    // the magic value
    result.addAll(Utils.uintToBytesLE(magic, 4));
    // the command code
    List<int> commandBytes = new AsciiCodec().encode(command);
    while(commandBytes.length < 12) {
      commandBytes.add(0);
    }
    result.addAll(commandBytes);
    // the payload length
    result.addAll(Utils.uintToBytesLE(payload.length, 4));
    // the chechsum
    result.addAll(checksum);
    // the payload
    if(payload != null)
      result.addAll(payload);
    else
      result.addAll(_serialize_payload());
    return new Uint8List.fromList(result);
  }
  
  String _parseCommand(Uint8List bytes) {
    int word = COMMAND_LENGTH - 1;
    while(bytes[word] == 0) word--;
    return new AsciiCodec().decode(bytes.sublist(0, word));
  }
  
  int _lazySerializationLength(Uint8List bytes) {
    int payloadLength = Utils.bytesToUintLE(bytes.sublist(4 + COMMAND_LENGTH), 4);
    return 4 + COMMAND_LENGTH + 4 + 4 + payloadLength;
  }
}





