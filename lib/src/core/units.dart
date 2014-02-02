part of dartcoin.core;

class Units {
  
  static int toSatoshi(num bitcoins) {
    if(bitcoins is int) {
      return bitcoins * pow(10,8);
    }
    return (bitcoins * pow(10,8)).truncate();
  }
  
  static num toBitcoins(int satoshi) {
    return satoshi / pow(10,8);
  }
}