part of dartcoin.wire;

class GetBlocksMessage extends RequestMessage {

  @override
  String get command => Message.CMD_GETBLOCKS;
  
  GetBlocksMessage(List<Hash256> locators, [Hash256 stop]) : super(locators, stop);
  
  /// Create an empty instance.
  GetBlocksMessage.empty() : super.empty();
}