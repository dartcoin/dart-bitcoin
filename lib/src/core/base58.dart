part of dartcoin;

class Base58 {
  static final String ALPHABET = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
  
  // unused
  //static final String _validRegex = r"/^[1-9A-HJ-NP-Za-km-z]+$/";
  
  static String encode(Uint8List bytes) {
    if(bytes.length == 0) {
      return "";
    }
    
    // count number of leading zeros
    int leadingZeroes = 0;
    while(leadingZeroes < bytes.length && bytes[leadingZeroes] == 0) {
      leadingZeroes++;
    }
    
    String output = "";
    int startAt = leadingZeroes;
    while(startAt < bytes.length) {
      int mod = _divmod58(bytes, startAt);
      output = ALPHABET[mod] + output;
      if(bytes[startAt] == 0) {
        startAt++;
      }
    }
    
    while(output[0] == ALPHABET[0]) {
      output = output.substring(1, output.length);
    }
    while(leadingZeroes-- > 0) {
      output = ALPHABET[0] + output;
    }
    if(output[0] != ALPHABET[0]) {
      output = ALPHABET[0] + output;
    }
    
    return output;
  }
  
  static Uint8List decode(String input) {
    if(input.length == 0) {
      return [0];
    }
    
    // generate base 58 index list from input string
    List<int> input58 = new List(input.length);
    for(int i = 0 ; i < input.length ; i++) {
      int charint = ALPHABET.indexOf(input[i]);
      if(charint < 0) {
        throw new Exception("Invalid input formatting for Base58 decoding.");
      }
      input58[i] = charint;
    }
    
    // count leading zeroes
    int leadingZeroes = 0;
    while(leadingZeroes < input.length && input58[leadingZeroes] == 0) {
      leadingZeroes++;
    }
    
    // decode
    List<int> output = new List();
    // TODO
    int startAt = leadingZeroes;
    while(startAt < input58.length) {
      int mod = _divmod256(input58, startAt);
      if(input58[startAt] == 0) {
        startAt++;
      }
      output.insert(0, mod);
    }
    
    // remove unnecessary leading zeroes
    int zeroes = 0;
    while(output[zeroes++] == 0) {}
    output = output.sublist(zeroes - leadingZeroes - 1);
    
    return new Uint8List.fromList(output);
  }
  
  /**
   * number -> number / 58
   * returns number % 58 
   */
  static int _divmod58(Uint8List number, int startAt) {
    Uint8List result = new Uint8List(number.length);
    int remaining = 0;
    for(int i = startAt ; i < number.length ; i++) {
      int num = number[i] + (remaining << 8); //= number[i] + remaining * 16
      number[i] = num ~/ 58;
      remaining = num % 58;
    }
    return remaining;
  }
  
  /**
   * number -> number / 256
   * returns number % 256 
   */
  static int _divmod256(Uint8List number58, int startAt) {
    Uint8List result = new Uint8List(number58.length);
    int remaining = 0;
    for(int i = startAt ; i < number58.length ; i++) {
      int num = number58[i] + 58 * remaining;
      number58[i] = num >> 8; //=num ~/ 256
      remaining = num & 0xff;
    }
    return remaining;
  }
  
}