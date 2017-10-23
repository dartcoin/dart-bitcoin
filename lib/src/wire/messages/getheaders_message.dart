part of dartcoin.wire;

class GetHeadersMessage extends RequestMessage {
  @override
  String get command => Message.CMD_GETHEADERS;

  GetHeadersMessage(List<Hash256> locators, [Hash256 stop]) : super(locators, stop);

  /// Create an empty instance.
  GetHeadersMessage.empty() : super.empty();
}
