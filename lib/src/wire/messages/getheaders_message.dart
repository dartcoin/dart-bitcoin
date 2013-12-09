part of dartcoin.wire;

class GetHeadersMessage extends RequestMessage {
  
  GetHeadersMessage(List<Sha256Hash> locators, [Sha256Hash stop]) : super("getheaders", locators, stop);
  
}