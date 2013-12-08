part of dartcoin;

class VarStr {
  
  String content;
  
  VarStr(String this.content);
  
  /**
   * The length of the string, not the length of the output bytes.
   */
  int get length => content.length;
  
  Uint8List encode() {
    List<int> result = new List<int>();
    List<int> contentBytes = new Utf8Codec().encode(content);
    result.addAll(new VarInt(contentBytes.length).encode());
    result.addAll(contentBytes);
    return new Uint8List.fromList(result);
  }
  
}