part of dartcoin.wire;

abstract class Message {
  
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
  
  Uint8List encode_payload();
  
  Uint8List get payload {
    if(_payload == null)
      _payload = encode_payload();
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
  
  Uint8List encode() {
    if(command.length > 12)
      throw new Exception("Command length should not be greater than 12.");
    List<int> result = new List<int>();
    // the magic value
    result.addAll(Utils.intToBytesLE(magic, 4));
    // the command code
    List<int> commandBytes = new AsciiCodec().encode(command);
    while(commandBytes.length < 12) {
      commandBytes.add(0);
    }
    result.addAll(commandBytes);
    // the payload length
    result.addAll(Utils.intToBytesLE(payload.length, 4));
    // the chechsum
    result.addAll(checksum);
    // the payload
    result.addAll(payload);
    return new Uint8List.fromList(result);
  }
}





