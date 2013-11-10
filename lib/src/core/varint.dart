part of dartcoin;

class VarInt {
  
  int value;
  
  VarInt(int this.value) {
    if(value < 0) throw new Exception("VarInt values should be at elast 0!");
  }
  
  int get size {
    return sizeOf(this.value);
  }
  
  List<int> encode() {
    List<int> result;
    if(value < 0xfd)        result =  [value];
    if(value <= 0xffff)     result = [253, 0, 0];
    if(value <= 0xffffffff) result = [254, 0, 0, 0, 0];
    if(result == null)      result = [255, 0, 0, 0, 0, 0, 0, 0, 0];
    
    result.replaceRange(1, result.length, Utils.intToBytesLE(value));
    // sublist is necessary due to doubtful implementation of replaceRange
    return result.sublist(0, size);
  }
  
  static int sizeOf(int value) {
    if(value < 0) throw new Exception("VarInt values should be at elast 0!");
    
    if(value < 0xfd) return 1;
    if(value <= 0xffff) return 3;
    if(value <= 0xffffffff) return 5;
    return 9;
  }
  
}