part of dartcoin.core;


/**
 * This mixin is intended to be implemented by objects that
 * can be represented by a hash.
 */
abstract class HashRepresentable {
  
  Sha256Hash get hash;
  
  bool get isHashOnly => false;
  
  @override
  bool operator ==(HashRepresentable other) {
    if(other is! HashRepresentable) return false;
    return hash == other.hash;
  }
  
  @override
  int get hashCode => hash.hashCode;
  
}