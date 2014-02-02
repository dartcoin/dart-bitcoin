part of dartcoin.wire;

//TODO implement locator stacking here?
abstract class RequestMessage extends Message {
  
  final int version = 0x01000000;
  
  List<Sha256Hash> locators;
  Sha256Hash stop;
  
  RequestMessage(String command, List<Sha256Hash> this.locators, Sha256Hash stop) : super(command) {
    if(stop == null) {
      //TODO is this correct?
      stop = new Sha256Hash(Utils.uintToBytesLE(0, 32));
    }
  }
  
  Uint8List _serialize_payload() {
    List<int> result = new List<int>();
    result.addAll(Utils.uintToBytesLE(version, 4));
    result.addAll(new VarInt(locators.length).serialize());
    for(Sha256Hash hash in locators) {
      result.addAll(hash.bytes);
    }
    result.addAll(stop.bytes);
    return new Uint8List.fromList(result);
  }
}