part of dartcoin.core;

class SerializationException implements Exception {
  
  final String message;
  
  SerializationException([String this.message]);
  
  @override
  String toString() => "SerializationException: $message";
  
  @override
  bool operator ==(SerializationException other) => 
      other is SerializationException && 
      message == other.message;  
  
}