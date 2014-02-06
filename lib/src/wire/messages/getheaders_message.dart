part of dartcoin.core;

class GetHeadersMessage extends RequestMessage {
  
  GetHeadersMessage(List<Sha256Hash> locators, [Sha256Hash stop]) : super("getheaders", locators, stop);

  factory GetHeadersMessage.deserialize(Uint8List bytes, {int length: BitcoinSerialization.UNKNOWN_LENGTH, bool lazy: true}) => 
      new BitcoinSerialization.deserialize(new GetHeadersMessage(null, null), bytes, length: length, lazy: lazy);
  
}