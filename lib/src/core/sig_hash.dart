part of dartcoin.core;


class SigHash {
  static const SigHash ALL    = const SigHash._(1);
  static const SigHash NONE   = const SigHash._(2);
  static const SigHash SINGLE = const SigHash._(3);

  static const int ANYONE_CAN_PAY = 0x80;

  /**
   * The bit-value of this SigHash flag.
   *
   * Note that in BitcoinJ, this value is retrieved by doing sigHash.ordinal() + 1.
   */
  final int value;

  const SigHash._(int this.value);

  static int sigHashFlagsValue(SigHash sh, bool anyoneCanPay) {
    int val = sh.value;
    if(anyoneCanPay)
      val |= ANYONE_CAN_PAY;
    return val;
  }
}