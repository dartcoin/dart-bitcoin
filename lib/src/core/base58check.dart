part of dartcoin.core;

/**
 * Used for encoding en decoding bytestrings to the Base58Check encoding that Bitcoin uses.
 * 
 * More info can be found in the Bitcoin wiki: https://en.bitcoin.it/wiki/Base58Check_encoding
 */
class Base58Check {
  static const String ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
  
  // unused
  //static const String _validRegex = r"/^[1-9A-HJ-NP-Za-km-z]+$/";
  
  static String encode(Uint8List bytes) {
    if(bytes.length == 0)
      return "";
    
    // count number of leading zeros
    int leadingZeroes = 0;
    while(leadingZeroes < bytes.length && bytes[leadingZeroes] == 0)
      leadingZeroes++;
    
    String output = "";
    int startAt = leadingZeroes;
    while(startAt < bytes.length) {
      int mod = _divmod58(bytes, startAt);
      if(bytes[startAt] == 0)
        startAt++;
      output = ALPHABET[mod] + output;
    }
    
    if(output.length > 0) {
      while(output[0] == ALPHABET[0])
        output = output.substring(1, output.length);
    }
    while(leadingZeroes-- > 0)
      output = ALPHABET[0] + output;
    
    return output;
  }
  
  static Uint8List decode(String input) {
    if(input.length == 0)
      return new Uint8List(0);
    
    // generate base 58 index list from input string
    List<int> input58 = new List(input.length);
    for(int i = 0 ; i < input.length ; i++) {
      int charint = ALPHABET.indexOf(input[i]);
      if(charint < 0)
        throw new FormatException("Invalid input formatting for Base58 decoding.");
      input58[i] = charint;
    }
    
    // count leading zeroes
    int leadingZeroes = 0;
    while(leadingZeroes < input58.length && input58[leadingZeroes] == 0)
      leadingZeroes++;
    
    // decode
    Uint8List output = new Uint8List(input.length);
    int j = output.length;
    int startAt = leadingZeroes;
    while(startAt < input58.length) {
      int mod = _divmod256(input58, startAt);
      if(input58[startAt] == 0)
        startAt++;
      output[--j] = mod;
    }
    
    // remove unnecessary leading zeroes
    while(j < output.length && output[j] == 0)
      j++;
    return output.sublist(j - leadingZeroes);
  }

  /**
   * Uses the checksum in the last 4 bytes of the decoded data to verify the rest are correct. The checksum is
   * removed from the returned data.
   *
   * Throws [FormatException] if the input is not base 58 or the checksum does not validate.
   */
  static Uint8List decodeChecked(String input) {
    Uint8List bytes = decode(input);
    if (bytes.length < 4)
      throw new FormatException("Input too short");
    Uint8List payload = bytes.sublist(0, bytes.length - 4);
    Uint8List checksum = bytes.sublist(bytes.length - 4, bytes.length);
    Uint8List hash = Utils.doubleDigest(payload).sublist(0, 4);
    if(!Utils.equalLists(checksum, hash))
      throw new FormatException("Checksum does not validate");
    return payload;
  }
  
  /**
   * number -> number / 58
   * returns number % 58 
   */
  static int _divmod58(List<int> number, int startAt) {
    int remaining = 0;
    for(int i = startAt ; i < number.length ; i++) {
      int num = (0xFF & remaining) * 256 + number[i];
      number[i] = num ~/ 58;
      remaining = num % 58;
    }
    return remaining;
  }
  
  /**
   * number -> number / 256
   * returns number % 256 
   */
  static int _divmod256(List<int> number58, int startAt) {
    int remaining = 0;
    for(int i = startAt ; i < number58.length ; i++) {
      int num = 58 * remaining + (number58[i] & 0xFF);
      number58[i] = num ~/ 256;
      remaining = num % 256;
    }
    return remaining;
  }
  
}