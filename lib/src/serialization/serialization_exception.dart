part of dartcoin.core;

class SerializationException implements Exception {
  
  final String message;
  
  SerializationException([String this.message]);
  
}